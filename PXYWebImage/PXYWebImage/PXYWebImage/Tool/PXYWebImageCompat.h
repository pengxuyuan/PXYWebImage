//
//  PXYWebImageCompat.h
//  PXYWebImage
//
//  Created by pengguang on 16/6/2.
//  Copyright © 2016年 pengxuyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//一个公共类样的 写一些整个库可能需要的宏或者方法
//这里有一个 更具屏幕的scale来拉伸图片的方法
//这里姑且将它理解一个工具类吧



//#if OS_OBJECT_USE_OBJC
//#undef SDDispatchQueueRelease
//#undef SDDispatchQueueSetterSementics
//#define SDDispatchQueueRelease(q)
//#define SDDispatchQueueSetterSementics strong
//#else
//#undef SDDispatchQueueRelease
//#undef SDDispatchQueueSetterSementics
//#define SDDispatchQueueRelease(q) (dispatch_release(q))
//#define SDDispatchQueueSetterSementics assign
//#endif








//拉伸图片的
extern UIImage *PXYScaleImageForKey(NSString *key, UIImage *image);

//一个block  没有返回值 没有返回参数的
typedef void(^PXYWebImageNoParamsBlock)();

//发生错误时 错误信息 可以作为Key
extern NSString *const PXYWebImageErrorDomain;

//这里定义一个宏 同步 异步 但是要在主线程
#define dispatch_main_sync_safe(block)\
    if ([NSThread isMainThread]) {\
        block();\
    } else {\
        dispatch_sync(dispatch_get_main_queue(), block);\
    }

#define dispatch_main_async_safe(block)\
    if ([NSThread isMainThread]) {\
        block();\
    } else {\
        dispatch_async(dispatch_get_main_queue(), block);\
    }


/*
 extern 访问全局变量 拓展 全局使用
 static 修饰的  也称私有全局变量，只在该源文件中可用
 */