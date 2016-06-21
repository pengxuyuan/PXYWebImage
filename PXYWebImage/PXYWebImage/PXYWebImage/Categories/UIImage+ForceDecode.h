//
//  UIImage+ForceDecode.h
//  PXYWebImage
//
//  Created by pengguang on 16/6/12.
//  Copyright © 2016年 pengxuyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ForceDecode)

//解码 为什么需要？
+ (UIImage *)decodedImageWithImage:(UIImage *)image;

@end
