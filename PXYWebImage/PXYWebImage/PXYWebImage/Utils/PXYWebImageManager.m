//
//  PXYWebImageManager.m
//  PXYWebImage
//
//  Created by pengguang on 16/6/12.
//  Copyright © 2016年 pengxuyuan. All rights reserved.
//

#import "PXYWebImageManager.h"

@interface PXYWebImageManager()

@property (strong, nonatomic, readwrite) PXYImageCache *imageCache; //图片缓存
@property (strong, nonatomic, readwrite) PXYWebImageDownloader *imageDownloader; //图片下载管理器

@property (strong, nonatomic) NSMutableSet *failedURLs;
@property (strong, nonatomic) NSMutableArray *runningOperations;

@end

@implementation PXYWebImageManager

//单例
+ (PXYWebImageManager *)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

//初始化
- (instancetype)init {
    PXYImageCache *cache = [PXYImageCache sharedImageCache];
    PXYWebImageDownloader *downloader = [PXYWebImageDownloader sharedDownloder];
    return [self initWithCache:cache downloader:downloader];
}


//初始化
- (instancetype)initWithCache:(PXYImageCache *)cache downloader:(PXYWebImageDownloader *)downloader {
    if ((self = [super init])) {
        _imageCache = cache;
        _imageDownloader = downloader;
        _failedURLs = [NSMutableSet new];
        _runningOperations = [NSMutableArray new];
    }
    return self;
}


@end
