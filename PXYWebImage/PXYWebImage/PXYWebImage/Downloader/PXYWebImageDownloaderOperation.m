//
//  PXYWebImageDownloaderOperation.m
//  PXYWebImage
//
//  Created by pengguang on 16/6/2.
//  Copyright © 2016年 pengxuyuan. All rights reserved.
//

#import "PXYWebImageDownloaderOperation.h"

/**
 开始下载
 接收到数据
 停止下载
 完成下载
 */
NSString *const PXYWebImageDownloadStartNotification = @"PXYWebImageDownloadStartNotification";
NSString *const PXYWebImageDownloadReceiveResponseNotification = @"PXYWebImageDownloadReceiveResponseNotification";
NSString *const PXYWebImageDownloadStopNotification = @"PXYWebImageDownloadStopNotification";
NSString *const PXYWebImageDownloadFinishNotification = @"PXYWebImageDownloadFinishNotification";

@interface PXYWebImageDownloaderOperation()<NSURLConnectionDataDelegate>{
    size_t width, height;
    UIImageOrientation orientation;
    BOOL responseFromCached;
}

//block 进行中 完成 无数据
@property (copy, nonatomic) PXYWebImageDownloaderProgressBlock progressBlock;
@property (copy, nonatomic) PXYWebImageDownloaderCompletedBlock completedBlock;
@property (copy, nonatomic) PXYWebImageNoParamsBlock cancelBlock;

//是否在执行 是否完成
@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;

//imageData 全局保存的图片属性
@property (strong, nonatomic) NSMutableData *imageData;

//connection
@property (strong, nonatomic) NSURLConnection *connection;

//thread
@property (strong, atomic) NSThread *thread;

//大于4系统 后台任务
#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;
#endif


@end

@implementation PXYWebImageDownloaderOperation

#warning 为什么要这样子
@synthesize executing = _executing;
@synthesize finished = _finished;

//初始化下载操作 异步下载
- (id)initWithRequest:(NSURLRequest *)request
              options:(PXYWebImageDownloaderOptions)options
             progress:(PXYWebImageDownloaderProgressBlock)progressBlock
            completed:(PXYWebImageDownloaderCompletedBlock)completedBlock
            cancelled:(PXYWebImageNoParamsBlock)cancelBlock{
    self = [super init];
    if (self) {
        _request = request;
        _options = options;
        
        _progressBlock = [progressBlock copy];
        _completedBlock = [completedBlock copy];
        _cancelBlock = [cancelBlock copy];
        
        _shouldDecompressImages = YES;
        _shouldUseCredentialStorage = YES;
        
        _executing = NO;
        _finished = NO;
        _expectedSize = 0;
        
        responseFromCached = YES;
        
        
    }
    return self;
}

//它没有简单的实现main方法，而是采用更加灵活的start方法，以便自己管理下载的状态。
//在start方法中，创建了我们下载所使用的NSURLConnection对象，开启了图片的下载，同时抛出一个下载开始的通知。当然，如果我们期望下载在后台处理，则只需要配置我们的下载选项，使其包含SDWebImageDownloaderContinueInBackground选项。
- (void)start{
    @synchronized(self) {
        // 管理下载状态，如果已取消，则重置当前下载并设置完成状态为YES
        //是否取消 取消了 完成属性YES 重置其他属性
        if (self.isCancelled) {
            self.finished = YES;
            [self reset];
            return;
        }
        
        //大于4 后台任务
#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_
        Class UIApplicationClass = NSClassFromString(@"UIApplication");
        BOOL hasApplication = UIApplicationClass && [UIApplicationClass respondsToSelector:@selector(sharedApplication)];
        if (hasApplication && [self shouldContinueWhenAppEntersBackground]) {
            __weak typeof(self) weakSelf = self;
            UIApplication * app = [UIApplicationClass performSelector:@selector(sharedApplication)];
            self.backgroundTaskId = [app beginBackgroundTaskWithExpirationHandler:^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                
                if (strongSelf) {
                    [strongSelf cancle];
                    
                    [app endBackgroundTask:strongSelf.backgroundTaskId];
                    strongSelf.backgroundTaskId = UIBackgroundTaskInvalid;
                }
            }];
        }
#endif
        
        self.executing = YES;
        self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
        self.thread = [NSThread currentThread];
    }
    
    [self.connection start];
    
    
}


#pragma mark -- method
//重设值
- (void)reset {
    self.cancelBlock = nil;
    self.completedBlock = nil;
    self.progressBlock = nil;
    self.connection = nil;
    self.imageData = nil;
    self.thread = nil;
}

//看看是否需要后台继续下载
- (BOOL)shouldContinueWhenAppEntersBackground {
    return self.options & PXYWebImageDownloaderContinueInBackground;
}

//取消
-(void)cancel{
    @synchronized(self) {
        if (self.thread) {
            [self performSelector:@selector(cancelInternalAndStop) onThread:self.thread withObject:nil waitUntilDone:NO];
        }else{
            [self cancelInternal];
        }
    }
}

//kill 线程
-(void)cancelInternalAndStop{
    if (self.isFinished) return;
    [self cancelInternal];
    CFRunLoopStop(CFRunLoopGetCurrent());
}

-(void)cancelInternal{
    if(self.finished) return;
    [super cancel];
    if (self.cancelBlock) self.cancelBlock();
    
    if (self.connection){
        [self.connection cancel];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:PXYWebImageDownloadStopNotification object:self];
        });
        
        if (self.isExecuting) self.executing = NO;
        if (!self.isFinished) self.finished = YES;
    }
    
    [self reset];
}

//做完了 重设值
- (void)done {
    self.finished = YES;
    self.executing = NO;
    [self reset];
}









@end
