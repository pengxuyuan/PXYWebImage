//
//  PXYWebImageDownloader.m
//  PXYWebImage
//
//  Created by pengguang on 16/6/2.
//  Copyright © 2016年 pengxuyuan. All rights reserved.
//

#import "PXYWebImageDownloader.h"

#import "PXYWebImageDownloaderOperation.h"

static NSString *const kProgressCallbackKey = @"progress";
static NSString *const kCompletedCallbackKey = @"completes";

@interface PXYWebImageDownloader()


@property (nonatomic,strong) NSOperationQueue *downloadQueue; //下载队列
@property (nonatomic,weak) NSOperation *lastAddedOperation; //多线程 最后添加进来的
@property (nonatomic,assign) Class operationClass;  //操作类 下载图片的多线程类

@property (nonatomic,strong) NSMutableDictionary *URLCallbacks; //URL 回调  回调信息存储
@property (nonatomic,strong) NSMutableDictionary *HTTPHeaders; //HTTP 请求头

//这个队列是序列化所有下载操作的网络响应 单一队列
//并行调度队列
@property (nonatomic,strong) dispatch_queue_t barrierQueue;

@end


@implementation PXYWebImageDownloader

+(void)initialize{
    //SDNetworkActivityIndicator.h Bind
    
}

+(PXYWebImageDownloader *)sharedDownloder{
    static dispatch_once_t onceToken;
    static PXYWebImageDownloader *shareInstance;
    dispatch_once(&onceToken, ^{
        shareInstance = [PXYWebImageDownloader new];
    });
    return shareInstance;
}

//自身初始化 设置默认值
- (instancetype)init
{
    self = [super init];
    if (self) {
        _operationClass = [PXYWebImageDownloaderOperation class];
        
        _downloadQueue = [NSOperationQueue new];
        _downloadQueue.maxConcurrentOperationCount = 6;
        
        _URLCallbacks = [NSMutableDictionary new];
        
        _shouldDecompressImages = YES;
        _executionOrder = PXYWebImageDownloaderFIFOExecutionOrder;
        
        _barrierQueue = dispatch_queue_create("com.pengxuyuan.PXYSDWebImageDownloaderBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
        _downloadTimeout = 15.0;
        
#warning !!!!!
#ifdef SD_WEBP
        _HTTPHeaders = [@{@"Accept": @"image/webp,image/*;q=0.8"} mutableCopy];
#else
        _HTTPHeaders = [@{@"Accept": @"image/*;q=0.8"} mutableCopy];
#endif
    }
    return self;
}

-(void)dealloc{
    [self.downloadQueue cancelAllOperations];
//    dispatch_release(_barrierQueue);
}

#pragma mark -- method
//设置 请求头 设置key-value属性
//这里跟过滤相反 这里是将每个HTTP request 前面都加一个请求头 HTTPHeaders  字典保存
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field{
    if (value) {
        self.HTTPHeaders[field] = value;
    }else{
        [self.HTTPHeaders removeObjectForKey:field];
    }
}

//返回这个HTTP的请求头 key对应的value值
- (NSString *)valueForHTTPHeaderField:(NSString *)field{
    return self.HTTPHeaders[field];
}

- (void)setOperationClass:(Class)operationClass{
    _operationClass = operationClass?: [PXYWebImageDownloaderOperation class];
}

#pragma mark --setter getter
//最大同时下载数量  队列最大并发数
-(void)setMaxConcurrentDownloads:(NSInteger)maxConcurrentDownloads{
    _downloadQueue.maxConcurrentOperationCount = maxConcurrentDownloads;
}

//返回 最大同时下载数量
-(NSInteger)maxConcurrentDownloads{
    return _downloadQueue.maxConcurrentOperationCount;
}

//返回需要被下载的图片的数量 当前队列里面的操作数量
-(NSUInteger)currentDownloadCount{
    return  _downloadQueue.operationCount;
}

/**
 *  通过URL 创建一个异步下载
 *  下载完成或则失败都会用代理delagate方法回调 （通知）
 */
-(id<PXYWebImageOperation>)downloaderImageWithURL:(NSURL *)url
                                          options:(PXYWebImageDownloaderOptions)options
                                         progress:(PXYWebImageDownloaderProgressBlock)progressBlock
                                        completed:(PXYWebImageDownloaderCompletedBlock)completedBlock{

    __block PXYWebImageDownloaderOperation *operation;
    __weak typeof(self) weakSelf = self;
    
    [self addProgressCallback:progressBlock completedBlock:completedBlock forURL:url createCallback:^{
        //没加载过 要加载 继续进行下载操作
        NSTimeInterval timeoutInterval = weakSelf.downloadTimeout;
        if (timeoutInterval == 0.0) {
            timeoutInterval = 15;
        }
        
        //为了防止潜在的多次缓存（NSURLCache + SDImageCache 这样子导致）
        // 为了避免潜在的重复缓存(NSURLCache + SDImageCache)，如果没有明确告知需要缓存，则禁用图片请求的缓存操作
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:(options & PXYWebImageDownloaderUseNSURLCache ? NSURLRequestUseProtocolCachePolicy : NSURLRequestReloadIgnoringLocalCacheData) timeoutInterval:timeoutInterval];
        
        request.HTTPShouldHandleCookies = (options & PXYWebImageDownloaderHandleCookies);
        request.HTTPShouldUsePipelining = YES;
        if (weakSelf.headerFilter) {
            request.allHTTPHeaderFields = weakSelf.headerFilter(url,[self.HTTPHeaders copy]);
        }else{
            request.allHTTPHeaderFields = self.HTTPHeaders;
        }
        
        //进行下载操作  SDWebImageDownloaderOperation
//        operation
        
        
        
    }];
    
    return operation;
}

//这里做判断 看看是否返回 createCallback 进行下载操作
- (void)addProgressCallback:(PXYWebImageDownloaderProgressBlock)progressBlock
             completedBlock:(PXYWebImageDownloaderCompletedBlock)completedBlock
                     forURL:(NSURL *)url
             createCallback:(PXYWebImageNoParamsBlock)createCallback {
    
    
    //这个URL 需要用来在返回字典URLCallbacks中做key的 如果没有的话 立即返回完成的completeBlock 其中没有数据 没有图片
    if (url == nil) {
        if (completedBlock) {
            completedBlock(nil,nil,nil,NO);
        }
        return;
    }
    
    //dispatch队列  dispatch_barrier_sync来保证同一时间只有一个线程在访问URLCallbacks
    //并且此处使用了一个单独的queue--barrierQueue，并且这个queue是一个DISPATCH_QUEUE_CONCURRENT类型的。也就是说，这里虽然允许你针对URLCallbacks的操作是并发执行的，但是因为使用了dispatch_barrier_sync，所以你必须保证之前针对URLCallbacks的操作要完成才能执行下面针对URLCallbacks的操作
    // 1. 以dispatch_barrier_sync操作来保证同一时间只有一个线程能对URLCallbacks进行操作
    dispatch_barrier_sync(self.barrierQueue, ^{
        //看看是不是第一次下载 URLCallbacks url取不出来 第一次下载这个URL资源
        BOOL isFrist = NO;
        if (!self.URLCallbacks[url]) {
            self.URLCallbacks[url] = [NSMutableArray new];
            isFrist = YES;
        }
        
        // 2. 处理同一URL的同步下载请求的单个下载 不下载 多次
        NSMutableArray *callbacksForURL = self.URLCallbacks[url];
        NSMutableDictionary *callbacks = [NSMutableDictionary new];
        if (progressBlock) callbacks[kProgressCallbackKey] = [progressBlock copy];
        if (completedBlock) callbacks[kCompletedCallbackKey] = [completedBlock copy];
        [callbacksForURL addObject:callbacks];
        self.URLCallbacks[url] = callbacksForURL;
        
        if (isFrist) {
            createCallback();
        }
        
    });
}




















@end
