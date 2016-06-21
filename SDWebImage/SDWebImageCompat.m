//
//  SDWebImageCompat.m
//  SDWebImage
//
//  Created by Olivier Poitrey on 11/12/12.
//  Copyright (c) 2012 Dailymotion. All rights reserved.
//

#import "SDWebImageCompat.h"

#if !__has_feature(objc_arc)
#error SDWebImage is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

/**
 iOS安全–使用static inline方式编译函数，防止静态分析
 我们知道一般的函数调用都会通过call的方式来调用，这样让攻击很容易对一个函数做手脚，如果是以inline的方式编译的会，会把该函数的code拷贝到每次调用该函数的地方。而static会让生成的二进制文件中没有清晰的符号表，让逆向的人很难弄清楚逻辑。
 
 static inline function
 如果你的.m文件需要频繁调用一个函数,可以用static inline来声明,这相当于把函数体当做一个大号的宏定义.不过这也不是百分之百有效,到底能不能把函数体转换为大号宏定义来用要看编译器心情,它要是觉得你的方法太复杂,他就不转了.他直接调用函数.
 
*/

/**
UIImage.images // default is nil for non-animated images

UIImage还可以加载多张图片，并按指定时间间隔依次显示多张图片，这就可以非常方便地实现动画效果。UImage提供了如下方法来加载多张图片实现动画。
 
 Ø + animatedImageNamed:duration:：根据指定的图片名来加载系列图片。例如，调用该方法时的第一个参数名为butterfly，该方法将会自动加载butterfly0.png、butterfly1.png、butterfly2.png等图片。
 
 Ø + animatedImageWithImages:duration:：该方法需要传入一个NSArray作为多张动画图片。该NSArray中的每个元素都是UIImage对象。
 
 Ø + imageWithCGImage:scale:orientation:：该方法用于根据指定的CGImageRef对象来创建UIImage，并将图片缩放到指定比例。该方法的最后一个参数指定对图片执行旋转、镜像等变换操作。
 
*/

//返回一张适配好当前设备的 图片   缩放
inline UIImage *SDScaledImageForKey(NSString *key, UIImage *image) {
    if (!image) {
        return nil;
    }
    
    if ([image.images count] > 0) { // > 0  表示是一个特殊的图片 多张图片 这里要转换成一张具有动画效果的图片
        NSMutableArray *scaledImages = [NSMutableArray array];

        for (UIImage *tempImage in image.images) { //这里不直接食用images 也是要找到最适合的图片 同时防止 漏图片
            [scaledImages addObject:SDScaledImageForKey(key, tempImage)];
        }

        return [UIImage animatedImageWithImages:scaledImages duration:image.duration];
    }
    else {  //images == nil 正常一张图片
#warning  why?
        if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
            CGFloat scale = 1;
            if (key.length >= 8) {
                NSRange range = [key rangeOfString:@"@2x."];
                if (range.location != NSNotFound) {
                    scale = 2.0;
                }
                
                range = [key rangeOfString:@"@3x."];
                if (range.location != NSNotFound) {
                    scale = 3.0;
                }
            }
            //这里根据 图片key 来判断这张图片对映的 比例
            UIImage *scaledImage = [[UIImage alloc] initWithCGImage:image.CGImage scale:scale orientation:image.imageOrientation];
            image = scaledImage;
        }
        return image;
    }
}

NSString *const SDWebImageErrorDomain = @"SDWebImageErrorDomain";
