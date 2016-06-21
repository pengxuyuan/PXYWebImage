/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIView+WebCacheOperation.h"
#import "objc/runtime.h"

static char loadOperationKey;

@implementation UIView (WebCacheOperation)

/**
 objc_setAssociatedObject作用是对已存在的类在扩展中添加自定义的属性 ,通常推荐的做法是添加属性的key最好是static char类型的,通常来说该属性的key应该是常量唯一的.
 objc_getAssociatedObject根据key获得与对象绑定的属性.
 
 文／missummer（簡書作者）
 原文鏈接：http://www.jianshu.com/p/82c7f2865c92
 著作權歸作者所有，轉載請聯繫作者獲得授權，並標註“簡書作者”。
 */

/*
 这个loadOperationKey 的定义是:static char loadOperationKey;
 它对应的绑定在UIView的属性是operationDictionary(NSMutableDictionary类型)
 operationDictionary的value是操作,key是针对不同类型视图和不同类型的操作设定的字符串
 注意:&是一元运算符结果是右操作对象的地址(&loadOperationKey返回static char loadOperationKey的地址)
 */
- (NSMutableDictionary *)operationDictionary {
    NSMutableDictionary *operations = objc_getAssociatedObject(self, &loadOperationKey);
    if (operations) {
        return operations;
    }
    operations = [NSMutableDictionary dictionary];
    objc_setAssociatedObject(self, &loadOperationKey, operations, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return operations;
}

- (void)sd_setImageLoadOperation:(id)operation forKey:(NSString *)key {
    [self sd_cancelImageLoadOperationWithKey:key];
    NSMutableDictionary *operationDictionary = [self operationDictionary];
    [operationDictionary setObject:operation forKey:key];
}

////用这个key找到当前UIView上面的所有操作并取消
- (void)sd_cancelImageLoadOperationWithKey:(NSString *)key {
    // Cancel in progress downloader from queue
    // 取消正在下载的队列
    NSMutableDictionary *operationDictionary = [self operationDictionary];
    id operations = [operationDictionary objectForKey:key];
    if (operations) {
        if ([operations isKindOfClass:[NSArray class]]) {
            for (id <SDWebImageOperation> operation in operations) {
                if (operation) {
                    [operation cancel];
                }
            }
        } else if ([operations conformsToProtocol:@protocol(SDWebImageOperation)]){
            [(id<SDWebImageOperation>) operations cancel];
        }
        [operationDictionary removeObjectForKey:key];
    }
}

- (void)sd_removeImageLoadOperationWithKey:(NSString *)key {
    NSMutableDictionary *operationDictionary = [self operationDictionary];
    [operationDictionary removeObjectForKey:key];
}

@end
