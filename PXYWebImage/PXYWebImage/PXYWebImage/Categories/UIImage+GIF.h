//
//  UIImage+GIF.h
//  PXYWebImage
//
//  Created by pengguang on 16/6/12.
//  Copyright © 2016年 pengxuyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (GIF)

+ (UIImage *)sd_animatedGIFNamed:(NSString *)name;

+ (UIImage *)sd_animatedGIFWithData:(NSData *)data;

- (UIImage *)sd_animatedImageByScalingAndCroppingToSize:(CGSize)size;

@end
