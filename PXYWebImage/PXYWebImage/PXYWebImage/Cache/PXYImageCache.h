//
//  PXYImageCache.h
//  PXYWebImage
//
//  Created by pengguang on 16/6/3.
//  Copyright © 2016年 pengxuyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PXYWebImageCompat.h"

//图片缓存类型
typedef NS_ENUM(NSInteger,PXYImageCacheType){

    //不用缓存 直接下载
    PXYImageCacheTypeNone,
    
    //从磁盘高速缓存中获得的图像。
    PXYImageCacheTypeDisk,
    
    //从内存缓存中获得的图像。
    PXYImageCacheTypeMemory
};

//图片查询
typedef void(^PXYWebImageQueryCompletedBlock)(UIImage *image,PXYImageCacheType cacheType);

//检查图片的缓存状态 是否缓存了
typedef void(^PXYWebImageCheckCacheCompletionBlock)(BOOL isInCache);

//计算磁盘缓存
typedef void(^PXYWebImageCalculateSizeBlock)(NSUInteger fileCount, NSUInteger totalSize);

//PXYImageCache 内存缓存 磁盘缓存  写磁盘的的操作是异步的 所以不会阻塞UI主线程
@interface PXYImageCache : NSObject

//解压
@property (assign, nonatomic) BOOL shouldDecompressImages;

//禁用iCloud备份
@property (assign, nonatomic) BOOL shouldDisableiCloud;

//默认是可以内存缓存的
@property (assign, nonatomic) BOOL shouldCacheImagesInMemory;

//最大内存值 消耗
@property (assign, nonatomic) NSUInteger maxMemoryCost;

//应该保持缓存中的对象的最大数目。
@property (assign, nonatomic) NSUInteger maxMemoryCountLimit;

//最大时间限制 图片在缓存的时间
@property (assign, nonatomic) NSInteger maxCacheAge;

//缓存的最大字节
@property (assign, nonatomic) NSUInteger maxCacheSize;

//单例
+(PXYImageCache *)sharedImageCache;

//初始化一个自定义名字的命名空间
-(id)initWithNamespace:(NSString *)ns;

//初始化一个自定义名字的命名空间 目录
-(id)initWithNamespace:(NSString *)ns diskCacheDirectory:(NSString *)directory;

//拿空间名来 返回一个完整的缓存路径
-(NSString *)makeDiskCachePath:(NSString*)fullNamespace;

//预加载
//*添加只读缓存路径搜索图像预缓存的sdimagecache
//*有用的，如果你想捆绑预先加载的图像与您的应用程序
- (void)addReadOnlyCachePath:(NSString *)path;

//缓存图片到 内存跟磁盘
- (void)storeImage:(UIImage *)image forKey:(NSString *)key;

//缓存图片到 内存 跟 是否需要磁盘
- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk;

- (void)storeImage:(UIImage *)image recalculateFromImage:(BOOL)recalculate imageData:(NSData *)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk;

//存储NSData到磁盘
- (void)storeImageDataToDisk:(NSData *)imageData forKey:(NSString *)key;

//异步 从磁盘请求数据
- (NSOperation *)queryDiskCacheForKey:(NSString *)key done:(PXYWebImageQueryCompletedBlock)doneBlock;

//同步 从内存缓存中 查询数据
- (UIImage *)imageFromMemoryCacheForKey:(NSString *)key;

//检查完内存缓存中 没有 再去 磁盘缓存中获取图片
- (UIImage *)imageFromDiskCacheForKey:(NSString *)key;

//异步删除图片 缓存
- (void)removeImageForKey:(NSString *)key;

//异步删除图片 缓存
- (void)removeImageForKey:(NSString *)key withCompletion:(PXYWebImageNoParamsBlock)completion;

//异步删除图片 缓存 看看要不要删除磁盘
- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk;

//异步删除图片 缓存 看看要不要删除磁盘
- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk withCompletion:(PXYWebImageNoParamsBlock)completion;

//清除内存中的所有图片
- (void)clearMemory;

//清除硬盘中所有图片
- (void)clearDiskOnCompletion:(PXYWebImageNoParamsBlock)completion;

//清除硬盘中所有图片
- (void)clearDisk;

//清除 过期的缓存图片 从磁盘 部分文件
- (void)cleanDiskWithCompletionBlock:(PXYWebImageNoParamsBlock)completionBlock;

//清除 过期的缓存图片 从磁盘  部分文件
- (void)cleanDisk;

//获取磁盘缓存的大小
- (NSUInteger)getSize;

//获取磁盘缓存的图片数量
- (NSUInteger)getDiskCount;

//异步计算磁盘缓存大小
- (void)calculateSizeWithCompletionBlock:(PXYWebImageCalculateSizeBlock)completionBlock;

//异步查看已经这个key对应的图片 有没有在磁盘中存在
- (void)diskImageExistsWithKey:(NSString *)key completion:(PXYWebImageCheckCacheCompletionBlock)completionBlock;

//查看已经这个key对应的图片 有没有在磁盘中存在
- (BOOL)diskImageExistsWithKey:(NSString *)key;

//获取缓存路径
- (NSString *)cachePathForKey:(NSString *)key inPath:(NSString *)path;

//获取缓存路径
- (NSString *)defaultCachePathForKey:(NSString *)key;

@end






















