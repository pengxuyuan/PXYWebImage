//
//  PXYWebImageManager.h
//  PXYWebImage
//
//  Created by pengguang on 16/6/12.
//  Copyright © 2016年 pengxuyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PXYWebImageCompat.h"
#import "PXYImageCache.h"
#import "PXYWebImageDownloader.h"
#import "PXYWebImageOperation.h"

typedef NS_OPTIONS(NSUInteger, PXYWebImageOptions){
    // 默认情况下，当URL下载失败时，URL会被列入黑名单，导致库不会再去重试，该标记用于禁用黑名单
    PXYWebImageRetryFailed = 1 << 0,
    
    // 默认情况下，图片下载开始于UI交互，该标记禁用这一特性，这样下载延迟到UIScrollView减速时
    PXYWebImageLowPriority = 1 << 1,
    
    // 该标记禁用磁盘缓存
    PXYWebImageCacheMemoryOnly = 1 << 2,
    
    // 该标记启用渐进式下载，图片在下载过程中是渐渐显示的，如同浏览器一下。
    // 默认情况下，图像在下载完成后一次性显示
    PXYWebImageProgressiveDownload = 1 << 3,
    
    // 即使图片缓存了，也期望HTTP响应cache control，并在需要的情况下从远程刷新图片。
    // 磁盘缓存将被NSURLCache处理而不是PXYWebImage，因为PXYWebImage会导致轻微的性能下载。
    // 该标记帮助处理在相同请求URL后面改变的图片。如果缓存图片被刷新，则完成block会使用缓存图片调用一次
    // 然后再用最终图片调用一次
    PXYWebImageRefreshCached = 1 << 4,
    
    // 在iOS 4+系统中，当程序进入后台后继续下载图片。这将要求系统给予额外的时间让请求完成
    // 如果后台任务超时，则操作被取消
    PXYWebImageContinueInBackground = 1 << 5,
    
    // 通过设置NSMutableURLRequest.HTTPShouldHandleCookies = YES;来处理存储在NSHTTPCookieStore中的cookie
    PXYWebImageHandleCookies = 1 << 6,
    
    // 允许不受信任的SSL认证
    PXYWebImageAllowInvalidSSLCertificates = 1 << 7,
    
    // 默认情况下，图片下载按入队的顺序来执行。该标记将其移到队列的前面，
    // 以便图片能立即下载而不是等到当前队列被加载
    PXYWebImageHighPriority = 1 << 8,
    
    // 默认情况下，占位图片在加载图片的同时被加载。该标记延迟占位图片的加载直到图片已以被加载完成
    PXYWebImageDelayPlaceholder = 1 << 9,
    
    // 通常我们不调用动画图片的transformDownloadedImage代理方法，因为大多数转换代码可以管理它。
    PXYWebImageTransformAnimatedImage = 1 << 10,
    
    PXYWebImageAvoidAutoSetImage = 1 << 11
};

//图片下载完成block
typedef void(^PXYWebImageCompletionBlock)(UIImage *image, NSError *error, PXYImageCacheType cacheType, NSURL *imageURL);

//图片下载完成block
typedef void(^PXYWebImageCompletionWithFinishedBlock)(UIImage *image, NSError *error, PXYImageCacheType cacheType, BOOL finished, NSURL *imageURL);

typedef NSString *(^PXYWebImageCacheKeyFilterBlock)(NSURL *url);

//协议代理
@class PXYWebImageManager;

@protocol PXYWebImageManagerDelegate <NSObject>
@optional
// 控制当图片在缓存中没有找到时，应该下载哪个图片
- (BOOL)imageManager:(PXYWebImageManager *)imageManager shouldDownloadImageForURL:(NSURL *)imageURL;

// 允许在图片已经被下载完成且被缓存到磁盘或内存前立即转换
- (UIImage *)imageManager:(PXYWebImageManager *)imageManager transformDownloadedImage:(UIImage *)image withURL:(NSURL *)imageURL;

@end

//该对象将一个下载器和一个图片缓存绑定在一起，并对外提供两个只读属性来获取它们
@interface PXYWebImageManager : NSObject
@property (weak, nonatomic) id <PXYWebImageManagerDelegate> delegate;

@property (strong, nonatomic, readonly) PXYImageCache *imageCache;
@property (strong, nonatomic, readonly) PXYWebImageDownloader *imageDownloader;

/**
 * 这个缓存的过滤器 可以将URL转换成一个缓存cache key 过滤特殊的部分
 */
@property (nonatomic, copy) PXYWebImageCacheKeyFilterBlock cacheKeyFilter;

//单例
+ (PXYWebImageManager *)sharedManager;

//自定义 初始化 SDImageCache SDWebImageDownloader 返回 SDWebImageManager 这个对象
- (instancetype)initWithCache:(PXYImageCache *)cache downloader:(PXYWebImageDownloader *)downloader;

//通过URL 下载图片
- (id <PXYWebImageOperation>)downloadImageWithURL:(NSURL *)url
                                         options:(PXYWebImageOptions)options
                                        progress:(PXYWebImageDownloaderProgressBlock)progressBlock
                                       completed:(PXYWebImageCompletionWithFinishedBlock)completedBlock;

//将图片缓存
- (void)saveImageToCache:(UIImage *)image forURL:(NSURL *)url;

//kill当前所有的下载
- (void)cancelAll;

//查看是否正在下载
- (BOOL)isRunning;

//查看这个URL 是否被缓存过
- (BOOL)cachedImageExistsForURL:(NSURL *)url;

//是否只在硬盘中缓存了
- (BOOL)diskImageExistsForURL:(NSURL *)url;

//查看这个图片有没有被缓存了
- (void)cachedImageExistsForURL:(NSURL *)url
                     completion:(PXYWebImageCheckCacheCompletionBlock)completionBlock;

//查看这个图片有没在硬盘中缓存了
- (void)diskImageExistsForURL:(NSURL *)url
                   completion:(PXYWebImageCheckCacheCompletionBlock)completionBlock;

//返回URL对应的缓存key
- (NSString *)cacheKeyForURL:(NSURL *)url;

@end
