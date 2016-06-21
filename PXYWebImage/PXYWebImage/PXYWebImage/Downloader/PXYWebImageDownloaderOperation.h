//
//  PXYWebImageDownloaderOperation.h
//  PXYWebImage
//
//  Created by pengguang on 16/6/2.
//  Copyright © 2016年 pengxuyuan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PXYWebImageOperation.h"
#import "PXYWebImageDownloader.h"

/**
 开始下载
 接收到数据
 停止下载
 完成下载
 */
extern NSString *const PXYWebImageDownloadStartNotification;
extern NSString *const PXYWebImageDownloadReceiveResponseNotification;
extern NSString *const PXYWebImageDownloadStopNotification;
extern NSString *const PXYWebImageDownloadFinishNotification;


@interface PXYWebImageDownloaderOperation : NSOperation<PXYWebImageOperation>

//用于连接的 request
@property (nonatomic,strong,readonly) NSURLRequest *request;

//是否需要解压
@property (nonatomic,assign) BOOL shouldDecompressImages;

//凭据 认证连接  NSURLConnectionDelegate 这个代理里面返回
@property (nonatomic,assign) BOOL shouldUseCredentialStorage;

//凭据变化 更换凭据
@property (nonatomic,strong) NSURLCredential *credential;

//下载图片操作方式
@property (nonatomic,assign,readonly) PXYWebImageDownloaderOptions options;

//数据预计大小
@property (nonatomic,assign) NSInteger expectedSize;

//连接的 response
@property (nonatomic,strong) NSURLResponse *responese;

//初始化下载操作 异步下载
- (id)initWithRequest:(NSURLRequest *)request
              options:(PXYWebImageDownloaderOptions)options
             progress:(PXYWebImageDownloaderProgressBlock)progressBlock
            completed:(PXYWebImageDownloaderCompletedBlock)completedBlock
            cancelled:(PXYWebImageNoParamsBlock)cancelBlock;














@end
