/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"
#import "SDWebImageOperation.h"

/**
 普通的枚举 C风格的
 typedef enum : NSUInteger {
 <#MyEnumValueA#>,
 <#MyEnumValueB#>,
 <#MyEnumValueC#>,
 } <#MyEnum#>;
 
 //推荐使用  简单明了
 typedef NS_ENUM(NSInteger,SDWebImageDownloaderOptions) ;
 
 //位移操作枚举定义
 typedef NS_OPTIONS(NSUInteger, SDWebImageDownloaderOptions);
 
 <<带符号左移 (n<<2 将整型值带符号左移2位 ）
 >>带符号右移 (n>>2 将整型值带符号右移2位 ）
 >>>无符号右移 (n>>>2 将整型值无符号右移2位 ）
 
 <<(左移)
 将一个运算符对象的各二进制位全部左移若干位（左边的二进制位丢弃，右边补0）
 操作数每左移一位，相当于该数乘以2
 例如：3<<2 后，结果为12
 此运算符的意思就是把3的二进制位全部左移两位，右边补2个0。3的二进制位11，左移两位后，右边补2个0就是1100。1100转为10进制为12。
 说到底左移操作就相当于2的2次方×3。 每左移1位次方就增1
 >>(右移)
 将一个数的各二进制位全部右移若干位，正数左补0，负数左补1，右边丢弃。
 操作数每右移一位，相当于该数除以2
 例如：9>>1 后，结果为4
 9的二进制为1001，右移1位后，左正数补0，右边丢弃。结果为 0100。转为10进制后为4。
 
*/

//枚举 下载图片操作方式 可以看出，这些选项主要涉及到下载的优先级、缓存、后台任务执行、cookie处理以认证几个方面。
#warning 这里的下载模式 还没有搞懂为什么要这样子设置
typedef NS_OPTIONS(NSUInteger, SDWebImageDownloaderOptions) {
    
    //普通下载图片 返回进度block 信息 下载完成调用completeBlock
    SDWebImageDownloaderLowPriority = 1 << 0, //1
    
    //下载图片 返回进度block的同时 同时返回completeBlock 里面的Image是当前正在下载的图片 可以实现将图片一点点的显示
    SDWebImageDownloaderProgressiveDownload = 1 << 1, //2

    /**
     * By default, request prevent the use of NSURLCache. With this flag, NSURLCache
     * is used with default policies.
     */
    //默认使用这个策略 NSURLCache
    SDWebImageDownloaderUseNSURLCache = 1 << 2, //4

    /**
     * Call completion block with nil image/imageData if the image was read from NSURLCache
     * (to be combined with `SDWebImageDownloaderUseNSURLCache`).
     */
    // 如果从NSURLCache 读取到了图片 completeBlock 将返回nil 配合 SDWebImageDownloaderUseNSURLCache 一起使用
    SDWebImageDownloaderIgnoreCachedResponse = 1 << 3, //8
    
    /**
     * In iOS 4+, continue the download of the image if the app goes to background. This is achieved by asking the system for
     * extra time in background to let the request finish. If the background task expires the operation will be cancelled.
     */
    //在iOS 4＋ 系统上面 系统允许程序在后台状态 继续下载东西 这个数据会向系统申请额外的时间来下载图片 如果后台程序被kill了 这个下载任务也会被kill
    SDWebImageDownloaderContinueInBackground = 1 << 4, //16

    /**
     * Handles cookies stored in NSHTTPCookieStore by setting 
     * NSMutableURLRequest.HTTPShouldHandleCookies = YES;
     */
    // 通过设置NSMutableURLRequest.HTTPShouldHandleCookies = YES来处理存储在NSHTTPCookieStore中的cookie
    SDWebImageDownloaderHandleCookies = 1 << 5, //32

    /**
     * Enable to allow untrusted SSL certificates.
     * Useful for testing purposes. Use with caution in production.
     */
    // 允许不受信任的SSL证书。主要用于测试目的。
    SDWebImageDownloaderAllowInvalidSSLCertificates = 1 << 6, //64

    /**
     * Put the image in the high priority queue.
     */
    // 将图片下载放到高优先级队列中
    SDWebImageDownloaderHighPriority = 1 << 7, //128
};

//下载顺序
typedef NS_ENUM(NSInteger, SDWebImageDownloaderExecutionOrder) {
    /**
     * Default value. All download operations will execute in queue style (first-in-first-out).
     */
    //队列 先进先出
    SDWebImageDownloaderFIFOExecutionOrder,

    /**
     * All download operations will execute in stack style (last-in-first-out).
     */
    //栈 后进先出
    SDWebImageDownloaderLIFOExecutionOrder
};

//2个通知 图片开始下载了 图片停止下载了
extern NSString *const SDWebImageDownloadStartNotification;
extern NSString *const SDWebImageDownloadStopNotification;

//2个block回调  下载正在进行（进度信息） 下载完成（图片 日志等信息）
typedef void(^SDWebImageDownloaderProgressBlock)(NSInteger receivedSize, NSInteger expectedSize);

typedef void(^SDWebImageDownloaderCompletedBlock)(UIImage *image, NSData *data, NSError *error, BOOL finished);

#warning 过滤什么东东
// Header过滤 block
typedef NSDictionary *(^SDWebImageDownloaderHeadersFilterBlock)(NSURL *url, NSDictionary *headers);

/**
 * Asynchronous downloader dedicated and optimized for image loading.
 */
//异步下载
@interface SDWebImageDownloader : NSObject

/**
 * Decompressing images that are downloaded and cached can improve performance but can consume lot of memory.
 * Defaults to YES. Set this to NO if you are experiencing a crash due to excessive memory consumption.
 */
/**
可以提高解压，下载和缓存的图像性能，但会消耗大量的内存。
默认是YES 如果你因为过度消耗内存而导致crash可以将这个设置成 NO 不过一般不会考虑从这里找内存紧张的原因
*/
@property (assign, nonatomic) BOOL shouldDecompressImages;

//最大同时下载数量  队列最大并发数
@property (assign, nonatomic) NSInteger maxConcurrentDownloads;

/**
 * Shows the current amount of downloads that still need to be downloaded
 */
//返回需要被下载的图片的数量
@property (readonly, nonatomic) NSUInteger currentDownloadCount;


/**
 *  The timeout value (in seconds) for the download operation. Default: 15.0.
 */
//下载超时时间
@property (assign, nonatomic) NSTimeInterval downloadTimeout;


/**
 * Changes download operations execution order. Default value is `SDWebImageDownloaderFIFOExecutionOrder`.
 */
//修改下载图片顺序
@property (assign, nonatomic) SDWebImageDownloaderExecutionOrder executionOrder;

/**
 *  Singleton method, returns the shared instance
 *
 *  @return global shared instance of downloader class
 */
//单例走一波
+ (SDWebImageDownloader *)sharedDownloader;

#warning  URL 什么凭据
/**
 *  Set the default URL credential to be set for request operations.
 */
//设置 URL 凭据
@property (strong, nonatomic) NSURLCredential *urlCredential;

#warning  username password 有什么用？
/**
 * Set username
 */
@property (strong, nonatomic) NSString *username;

/**
 * Set password
 */
@property (strong, nonatomic) NSString *password;

/**
 * Set filter to pick headers for downloading image HTTP request.
 *
 * This block will be invoked for each downloading image request, returned
 * NSDictionary will be used as headers in corresponding HTTP request.
 */

#warning 这里要了解一波 HTTP 请求
//设置过滤 HTTP 请求头 这里设置了过滤的请求头 所有请求的都会忽略这个请求头
@property (nonatomic, copy) SDWebImageDownloaderHeadersFilterBlock headersFilter;

/**
 * Set a value for a HTTP header to be appended to each download HTTP request.
 *
 * @param value The value for the header field. Use `nil` value to remove the header.
 * @param field The name of the header field to set.
 */
//这里跟过滤相反 这里是将每个HTTP request 前面都加一个请求头
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

/**
 * Returns the value of the specified HTTP header field.
 *
 * @return The value associated with the header field field, or `nil` if there is no corresponding header field.
 */
//返回这个HTTP的请求头 key对应的value值
- (NSString *)valueForHTTPHeaderField:(NSString *)field;

#warning SDWebImageDownloaderOperation
/**
 * Sets a subclass of `SDWebImageDownloaderOperation` as the default
 * `NSOperation` to be used each time SDWebImage constructs a request
 * operation to download an image.
 *
 * @param operationClass The subclass of `SDWebImageDownloaderOperation` to set 
 *        as default. Passing `nil` will revert to `SDWebImageDownloaderOperation`.
 */
- (void)setOperationClass:(Class)operationClass;

/**
 * Creates a SDWebImageDownloader async downloader instance with a given URL
 *
 * The delegate will be informed when the image is finish downloaded or an error has happen.
 *
 * @see SDWebImageDownloaderDelegate
 *
 * @param url            The URL to the image to download
 * @param options        The options to be used for this download
 * @param progressBlock  A block called repeatedly while the image is downloading
 * @param completedBlock A block called once the download is completed.
 *                       If the download succeeded, the image parameter is set, in case of error,
 *                       error parameter is set with the error. The last parameter is always YES
 *                       if SDWebImageDownloaderProgressiveDownload isn't use. With the
 *                       SDWebImageDownloaderProgressiveDownload option, this block is called
 *                       repeatedly with the partial image object and the finished argument set to NO
 *                       before to be called a last time with the full image and finished argument
 *                       set to YES. In case of error, the finished argument is always YES.
 *
 * @return A cancellable SDWebImageOperation
 */

/**
 *  通过URL 创建一个异步下载
 *  下载完成或则失败都会用代理delagate方法回调 （通知）
 */
- (id <SDWebImageOperation>)downloadImageWithURL:(NSURL *)url
                                         options:(SDWebImageDownloaderOptions)options
                                        progress:(SDWebImageDownloaderProgressBlock)progressBlock
                                       completed:(SDWebImageDownloaderCompletedBlock)completedBlock;

/**
 * Sets the download queue suspension state
 */
//挂起下载
- (void)setSuspended:(BOOL)suspended;

/**
 * Cancels all download operations in the queue
 */
//取消下载
- (void)cancelAllDownloads;

@end
