//
//  PXYWebImageDownloader.h
//  PXYWebImage
//
//  Created by pengguang on 16/6/2.
//  Copyright © 2016年 pengxuyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PXYWebImageCompat.h"
#import "PXYWebImageOperation.h"

//枚举 下载图片操作方式 可以看出，这些选项主要涉及到下载的优先级、缓存、后台任务执行、cookie处理以认证几个方面。
typedef NS_OPTIONS(NSUInteger,PXYWebImageDownloaderOptions){

    //普通下载图片 返回进度block 信息 下载完成调用completeBlock
    PXYWebImageDownloaderLowPriority = 1 << 0, //1
    
    //下载图片 返回进度block的同时 同时返回completeBlock 里面的Image是当前正在下载的图片 可以实现将图片一点点的显示
    PXYWebImageDownloaderProgressiveDownload = 1 << 1, //2
    
    //默认情况下 这个策略 NSURLCache
    PXYWebImageDownloaderUseNSURLCache = 1 << 2, //4
    
    // 如果从NSURLCache 读取到了图片 completeBlock 将返回nil 配合 SDWebImageDownloaderUseNSURLCache 一起使用
    PXYWebImageDownloaderIgnoreCachedResponse = 1 << 3, //8
    
    //在iOS 4＋ 系统上面 系统允许程序在后台状态 继续下载东西 这个数据会向系统申请额外的时间来下载图片 如果后台程序被kill了 这个下载任务也会被kill
    PXYWebImageDownloaderContinueInBackground = 1 << 4, //16
    
    // 通过设置NSMutableURLRequest.HTTPShouldHandleCookies = YES来处理存储在NSHTTPCookieStore中的cookie
    PXYWebImageDownloaderHandleCookies = 1 << 5, //32
    
    // 允许不受信任的SSL证书。主要用于测试目的。
    PXYWebImageDownloaderAllowInvalidSSLCertificates = 1 << 6, //64
    
    // 将图片下载放到高优先级队列中
    PXYWebImageDownloaderHighPriority = 1 << 7, //128

};

typedef NS_ENUM(NSInteger,PXYWebImageDownloaderExecutionOrder){

    //队列 先进先出 (first-in-first-out)
    PXYWebImageDownloaderFIFOExecutionOrder,
    
    //栈 后进先出 (last-in-first-out)
    PXYWebImageDownloaderLIFOExecutionOrder
};

//2个通知 图片开始下载了 图片停止下载了
extern NSString *const PXYWebImageDownloadStartNotification;
extern NSString *const PXYWebImageDownloadStopNotification;

//2个block回调  下载正在进行（进度信息） 下载完成（图片 日志等信息）
typedef void(^PXYWebImageDownloaderProgressBlock)(NSInteger receivedSize,NSInteger expextedSize);

typedef void(^PXYWebImageDownloaderCompletedBlock)(UIImage *image,NSData *data,NSError *error,BOOL finished);

#warning 过滤什么东东 !!!!
// Header过滤 block
typedef NSDictionary *(^PXYWebImageDownloaderHeadersFilterBlock)(NSURL *url,NSDictionary *headers);

//异步下载
@interface PXYWebImageDownloader : NSObject

//可以提高解压，下载和缓存的图像性能，但会消耗大量的内存。\
默认是YES 如果你因为过度消耗内存而导致crash可以将这个设置成 NO 不过一般不会考虑从这里找内存紧张的原因
@property (nonatomic,assign) BOOL shouldDecompressImages;

//最大同时下载数量  队列最大并发数
@property (nonatomic,assign) NSInteger maxConcurrentDownloads;

//返回需要被下载的图片的数量 当前队列里面的操作数量
@property (nonatomic,readonly) NSUInteger currentDownloadCount;

//下载超时时间 默认 15
@property (nonatomic,assign) NSTimeInterval downloadTimeout;

//修改下载图片顺序 默认PXYWebImageDownloaderFIFOExecutionOrder
@property (nonatomic,assign) PXYWebImageDownloaderExecutionOrder executionOrder;



//单例
+(PXYWebImageDownloader *)sharedDownloder;

//设置 URL 凭据
@property (nonatomic,strong) NSURLCredential *urlCredential;

//username password
@property (nonatomic,strong) NSString *username;

@property (nonatomic,strong) NSString *password;

//设置过滤 HTTP 请求头 这里设置了过滤的请求头 所有请求的都会忽略这个请求头
@property (nonatomic,copy) PXYWebImageDownloaderHeadersFilterBlock headerFilter;

//这里跟过滤相反 这里是将每个HTTP request 前面都加一个请求头 也可以将一个属性 设置成nil
-(void)setValue:(id)value forHTTPHeaderField:(NSString *)field;

//返回这个HTTP的请求头 key对应的value值
-(NSString *)valueForHTTPHeaderFiled:(NSString *)field;

#warning SDWebImageDownloaderOperation 还不知道什么鬼
- (void)setOperationClass:(Class)operationClass;

/**
 *  通过URL 创建一个异步下载
 *  下载完成或则失败都会用代理delagate方法回调 （通知）
 */
-(id<PXYWebImageOperation>)downloaderImageWithURL:(NSURL *)url
                                          options:(PXYWebImageDownloaderOptions)options
                                         progress:(PXYWebImageDownloaderProgressBlock)progressBlock
                                        completed:(PXYWebImageDownloaderCompletedBlock)completedBlock;

//挂起下载
-(void)setSuspended:(BOOL)suspended;

//取消下载
-(void)cancleAllDownloads;


@end








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