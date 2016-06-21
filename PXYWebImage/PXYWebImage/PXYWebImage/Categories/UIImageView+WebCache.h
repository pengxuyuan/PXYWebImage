//
//  UIImageView+WebCache.h
//  PXYWebImage
//
//  Created by pengguang on 16/6/12.
//  Copyright © 2016年 pengxuyuan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PXYWebImageManager.h"

@interface UIImageView (WebCache)

//获取当前的UIImageView 请求的image URL
//直接使用 sd_setImage 这个属性可能不会同步....
- (NSURL *)sd_imageURL;

//异步下载图片并缓存
- (void)sd_setImageWithURL:(NSURL *)url;

//异步下载图片并缓存
- (void)sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder;

//异步下载图片并缓存
- (void)sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(PXYWebImageOptions)options;

//异步下载图片并缓存
- (void)sd_setImageWithURL:(NSURL *)url completed:(PXYWebImageCompletionBlock)completedBlock;

//异步下载图片并缓存
- (void)sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(PXYWebImageCompletionBlock)completedBlock;

//异步下载图片并缓存
- (void)sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(PXYWebImageOptions)options completed:(PXYWebImageCompletionBlock)completedBlock;

//异步下载图片并缓存 进度 这里可以做一个UI交互 转圈圈的动画
- (void)sd_setImageWithURL:(NSURL *)url
          placeholderImage:(UIImage *)placeholder
                   options:(PXYWebImageOptions)options
                  progress:(PXYWebImageDownloaderProgressBlock)progressBlock
                 completed:(PXYWebImageCompletionBlock)completedBlock;

//异步下载图片并缓存 任选一个占位符图像。
- (void)sd_setImageWithPreviousCachedImageWithURL:(NSURL *)url
                                 placeholderImage:(UIImage *)placeholder
                                          options:(PXYWebImageOptions)options
                                         progress:(PXYWebImageDownloaderProgressBlock)progressBlock
                                        completed:(PXYWebImageCompletionBlock)completedBlock;

//动画图片
- (void)sd_setAnimationImagesWithURLs:(NSArray *)arrayOfURLs;

//取消当前下载的操作
- (void)sd_cancelCurrentImageLoad;

- (void)sd_cancelCurrentAnimationImagesLoad;

//显示正在下载的菊花
- (void)setShowActivityIndicatorView:(BOOL)show;

//设置菊花的样式
- (void)setIndicatorStyle:(UIActivityIndicatorViewStyle)style;

@end
