//
//  PXYImageCache.m
//  PXYWebImage
//
//  Created by pengguang on 16/6/3.
//  Copyright © 2016年 pengxuyuan. All rights reserved.
//

#import "PXYImageCache.h"
#import "UIImage+MultiFormat.h"
#import "UIImage+ForceDecode.h"

#import <CommonCrypto/CommonDigest.h>

//继承 NSCache 需要监听 内存紧张的时候 要移除内存中的图片
@interface AutoPurgeCache : NSCache

@end

@implementation AutoPurgeCache

- (instancetype)init
{
    self = [super init];
    if (self) {
        //接收到系统内存警告 将内存全部移除
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

@end

//设置默认缓存的生命周期
static const NSInteger kDefaultCacheMaxCacheAge = 60 * 60 * 24 * 7; // 1 week

// PNG signature bytes and data (below)
static unsigned char kPNGSignatureBytes[8] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};

static NSData *kPNGSignatureData = nil;

//判断是不是PNG 格式的数据
BOOL ImageDataHasPNGPreffix(NSData *data);

BOOL ImageDataHasPNGPreffix(NSData *data) {
    NSUInteger pngSignatureLength = [kPNGSignatureData length];
    if ([data length] >= pngSignatureLength) {
        if ([[data subdataWithRange:NSMakeRange(0, pngSignatureLength)] isEqualToData:kPNGSignatureData]) {
            return YES;
        }
    }
    
    return NO;
}

//防止静态分析 返回图片的大小
FOUNDATION_STATIC_INLINE NSUInteger SDCacheCostForImage(UIImage *image) {
    return image.size.height * image.size.width * image.scale * image.scale;
}

@interface PXYImageCache()

@property (strong, nonatomic) NSCache *memCache; //内存缓存
@property (strong, nonatomic) NSString *diskCachePath; //磁盘缓存的路径
@property (strong, nonatomic) NSMutableArray *customPaths;

//队列
@property (assign, nonatomic) dispatch_queue_t ioQueue;

@end


@implementation PXYImageCache{
    NSFileManager *_fileManager; //文件管理
}

//单例
+(PXYImageCache *)sharedImageCache{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

//default 默认命名空间
- (id)init {
    return [self initWithNamespace:@"default"];
}

//初始化一个自定义名字的命名空间
- (id)initWithNamespace:(NSString *)ns {
    NSString *path = [self makeDiskCachePath:ns];
    return [self initWithNamespace:ns diskCacheDirectory:path];
}

//创建文件路径directory目录下面的 ns 命名空间
- (id)initWithNamespace:(NSString *)ns diskCacheDirectory:(NSString *)directory{
    if ((self = [super init])) {
        //文件的全名
        NSString *fullNamespace = [@"com.hackemist.PXYWebImageCache." stringByAppendingString:ns];
        
        // initialise PNG signature data PNG签名 生成Data PNG
        kPNGSignatureData = [NSData dataWithBytes:kPNGSignatureBytes length:8];
        
         //创建IO 串行 队列
        _ioQueue = dispatch_queue_create("com.hackemist.PXYWebImageCache", DISPATCH_QUEUE_SERIAL);
        
        //默认缓存周期 一周
        _maxCacheAge = kDefaultCacheMaxCacheAge;
        
        // 初始化 内存缓存 对象
        _memCache = [[AutoPurgeCache alloc] init];
        _memCache.name = fullNamespace;
        
        // 初始化 磁盘缓存
        if (directory != nil){
            _diskCachePath = [directory stringByAppendingPathComponent:fullNamespace];
        }else{
            NSString *path = [self makeDiskCachePath:ns];
            _diskCachePath = path;
        }
        
        //初始化默认参数
        _shouldDecompressImages = YES;
        _shouldCacheImagesInMemory = YES;
        _shouldDisableiCloud = YES;
        
        dispatch_sync(_ioQueue, ^{
            _fileManager = [NSFileManager new];
        });
        
#if TARGET_OS_IOS
        // Subscribe to app events
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemory)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cleanDisk)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(backgroundCleanDisk)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
#endif
        
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    dispatch_release(_ioQueue);
}

#warning !!!!!!!!!!!!!!!!!!
//预加载
//*添加只读缓存路径搜索图像预缓存的sdimagecache
//*有用的，如果你想捆绑预先加载的图像与您的应用程序
- (void)addReadOnlyCachePath:(NSString *)path {
    if (!self.customPaths) {
        self.customPaths = [NSMutableArray new];
    }
    
    if (![self.customPaths containsObject:path]) {
        [self.customPaths addObject:path];
    }
}

//返回默认的缓存路径 硬盘缓存 这里是直接在default 目录下 有文件名称的
- (NSString *)defaultCachePathForKey:(NSString *)key {
    return [self cachePathForKey:key inPath:self.diskCachePath];
}

//获取缓存路径 硬盘缓存
- (NSString *)cachePathForKey:(NSString *)key inPath:(NSString *)path{
    NSString *filename = [self cachedFileNameForKey:key];
    return [path stringByAppendingPathComponent:filename];
}

#pragma mark SDImageCache (private)
//内存缓存 中搞个路径  !!!!!!!!!错误
//这里不是内存缓存 是硬盘缓存 MD5 加密 拿URL 生成MD5 格式的 文件名字
#warning !!!!
- (NSString *)cachedFileNameForKey:(NSString *)key {
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15], [[key pathExtension] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@".%@", [key pathExtension]]];
    
    return filename;
}



#pragma mark ImageCache
//在磁盘上 初始化一个内存空间 返回路径 拼接
//拿空间名来 返回一个完整的缓存路径 全路径
-(NSString *)makeDiskCachePath:(NSString*)fullNamespace{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths[0] stringByAppendingPathComponent:fullNamespace];
}

//缓存图片到 内存跟磁盘
- (void)storeImage:(UIImage *)image forKey:(NSString *)key {
    [self storeImage:image recalculateFromImage:YES imageData:nil forKey:key toDisk:YES];
}

//缓存图片到 内存 跟 是否需要磁盘
- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk {
    [self storeImage:image recalculateFromImage:YES imageData:nil forKey:key toDisk:toDisk];
}

//缓存图片
- (void)storeImage:(UIImage *)image recalculateFromImage:(BOOL)recalculate imageData:(NSData *)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk{
    if (!image || !key) {
        return;
    }
    
    //1.内存缓存
    if (self.shouldCacheImagesInMemory) {
        NSUInteger cost = SDCacheCostForImage(image);
        [self.memCache setObject:image forKey:key cost:cost];
    }
    
    //硬盘缓存
    if (toDisk){
        //2.如果确定需要磁盘缓存，则将缓存操作作为一个任务放入ioQueue中
        dispatch_async(self.ioQueue, ^{
            NSData *data = imageData;
            
            if(image && (recalculate || !data)){
#if TARGET_OS_IPHONE
                // We need to determine if the image is a PNG or a JPEG
                // PNGs are easier to detect because they have a unique signature (http://www.w3.org/TR/PNG-Structure.html)
                // The first eight bytes of a PNG file always contain the following (decimal) values:
                // 137 80 78 71 13 10 26 10
                
                // If the imageData is nil (i.e. if trying to save a UIImage directly or the image was transformed on download)
                // and the image has an alpha channel, we will consider it PNG to avoid losing the transparency
                // 3. 需要确定图片是PNG还是JPEG。PNG图片容易检测，因为有一个唯一签名。PNG图像的前8个字节总是包含以下值：137 80 78 71 13 10 26 10
                // 在imageData为nil的情况下假定图像为PNG。我们将其当作PNG以避免丢失透明度。而当有图片数据时，我们检测其前缀，确定图片的类型
                int alphaInfo = CGImageGetAlphaInfo(image.CGImage);
                BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                                  alphaInfo == kCGImageAlphaNoneSkipFirst ||
                                  alphaInfo == kCGImageAlphaNoneSkipLast);
                BOOL imageIsPng = hasAlpha;
                
                // But if we have an image data, we will look at the preffix
                if ([imageData length] >= [kPNGSignatureData length]) {
                    imageIsPng = ImageDataHasPNGPreffix(imageData);
                }
                
                if (imageIsPng) {
                    data = UIImagePNGRepresentation(image);
                }
                else {
                    data = UIImageJPEGRepresentation(image, (CGFloat)1.0);
                }
#else
                // 4. 创建缓存文件并存储图片
                data = [NSBitmapImageRep representationOfImageRepsInArray:image.representations usingType: NSJPEGFileType properties:nil];
#endif
            }
            
            [self storeImageDataToDisk:data forKey:key];
            
        });
    }
}

//存储NSData到磁盘
- (void)storeImageDataToDisk:(NSData *)imageData forKey:(NSString *)key{
    if (!imageData) {
        return;
    }
    
    if (![_fileManager fileExistsAtPath:_diskCachePath]) {
        [_fileManager createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    // get cache Path for image key
    NSString *cachePathForKey = [self defaultCachePathForKey:key];
    // transform to NSUrl
#warning !!!! fileURL  有什需要
    NSURL *fileURL = [NSURL fileURLWithPath:cachePathForKey];
    
    [_fileManager createFileAtPath:cachePathForKey contents:imageData attributes:nil];
    
    // disable iCloud backup
    if (self.shouldDisableiCloud) {
        [fileURL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
    }
}

//查看已经这个key对应的图片 有没有在磁盘中存在
- (BOOL)diskImageExistsWithKey:(NSString *)key{
    //判断是否在磁盘中 而且做了路径不同的判断
    BOOL exists = NO;
    
    exists = [[NSFileManager defaultManager] fileExistsAtPath:[self defaultCachePathForKey:key]];
    if (!exists) {
        exists = [[NSFileManager defaultManager] fileExistsAtPath:[[self defaultCachePathForKey:key] stringByDeletingPathExtension]];
    }
    
    return exists;

}

//异步查看已经这个key对应的图片 有没有在磁盘中存在
- (void)diskImageExistsWithKey:(NSString *)key completion:(PXYWebImageCheckCacheCompletionBlock)completionBlock{
    BOOL exists = [_fileManager fileExistsAtPath:[self defaultCachePathForKey:key]];
    
    if (!exists) {
        exists = [_fileManager fileExistsAtPath:[[self defaultCachePathForKey:key] stringByDeletingPathExtension]];
    }
    
    if (completionBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(exists);
        });
    }
}

//同步 从内存缓存中 查询数据
- (UIImage *)imageFromMemoryCacheForKey:(NSString *)key{
    return [self.memCache objectForKey:key];
}

//检查完内存缓存中 没有 再去 磁盘缓存中获取图片
- (UIImage *)imageFromDiskCacheForKey:(NSString *)key{
    //1.内存缓存中找
    UIImage *image = [self imageFromMemoryCacheForKey:key];
    if (image) {
        return image;
    }
    
    //2.硬盘缓存中找 找到加一次内存缓存
    UIImage *diskImage = [self diskImageForKey:key];
    if (diskImage && self.shouldCacheImagesInMemory) {
        NSUInteger cost = SDCacheCostForImage(diskImage);
        [self.memCache setObject:diskImage forKey:key cost:cost];
    }
    
    return diskImage;
}

//重硬盘缓存中寻找图片 找出Data类型的数据 然后拉伸 然后看看要不要解压
-(UIImage *)diskImageForKey:(NSString *)key{
    NSData *data = [self diskImageDataBySearchingAllPathsForKey:key];
    if (data) {
        UIImage *image = [UIImage pxy_imageWithData:data];
        image = [self scaledImageForKey:key image:image];
        if (self.shouldDecompressImages) {
            image = [UIImage decodedImageWithImage:image];
        }
        return image;
    }
    else {
        return nil;
    }
}

//拉伸图片
- (UIImage *)scaledImageForKey:(NSString *)key image:(UIImage *)image {
    return PXYScaleImageForKey(key, image);
}

//这里用key 文件名字在磁盘中 寻找文件
-(NSData *)diskImageDataBySearchingAllPathsForKey:(NSString *)key {
    NSString *defaultPath = [self defaultCachePathForKey:key];
    NSData *data = [NSData dataWithContentsOfFile:defaultPath];
    if (data) {
        return data;
    }
    
    data = [NSData dataWithContentsOfFile:[defaultPath stringByDeletingPathExtension]];
    if (data) {
        return data;
    }
    
    NSArray *customPaths = [self.customPaths copy];
    for (NSString *path in customPaths) {
        NSString *filePath = [self cachePathForKey:key inPath:path];
        NSData *imageData = [NSData dataWithContentsOfFile:filePath];
        if (imageData) {
            return imageData;
        }
        
        imageData = [NSData dataWithContentsOfFile:[filePath stringByDeletingPathExtension]];
        if (imageData) {
            return imageData;
        }
    }
    
    return nil;
}


@end































