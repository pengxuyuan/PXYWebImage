//
//  NSData+ImageContentType.h
//  PXYWebImage
//
//  Created by pengguang on 16/6/12.
//  Copyright © 2016年 pengxuyuan. All rights reserved.
//  判断图片Data类型

#import <Foundation/Foundation.h>

@interface NSData (ImageContentType)

+(NSString *)pxy_contentTypeForImageData:(NSData *)data;

@end
