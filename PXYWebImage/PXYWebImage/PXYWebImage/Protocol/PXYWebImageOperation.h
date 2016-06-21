//
//  PXYWebImageOperation.h
//  PXYWebImage
//
//  Created by pengguang on 16/6/2.
//  Copyright © 2016年 pengxuyuan. All rights reserved.
//

#import <Foundation/Foundation.h>

//协议 cancle 方法 供具体的实现 类似Java的接口
@protocol PXYWebImageOperation <NSObject>

-(void)cancle;

@end
