//
//  DiscoverPeripheralManager.m
//  flutter_acs_bt_evk
//
//  Created by 李晓康 on 2021/4/27.
//

#import "DiscoverPeripheralManager.h"

@implementation DiscoverPeripheralManager

//提供一个全局静态变量
static DiscoverPeripheralManager * _instance;

+(instancetype)shareManager{
    return [[self alloc]init];
}

//当调用alloc的时候会调用allocWithZone
+(instancetype)allocWithZone:(struct _NSZone *)zone{
    //dispatch_onec,本身是线程安全的,保证整个程序中只会执行一次
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}
//严谨
//遵从NSCopying协议,可以通过copy方式创建对象
- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return _instance;
}
//遵从NSMutableCopying协议,可以通过mutableCopy方式创建对象
- (nonnull id)mutableCopyWithZone:(nullable NSZone *)zone {
    return _instance;
}

- (NSMutableArray *)peripherals {
    if (!_peripherals) {
        _peripherals = [NSMutableArray array];
    }
    return _peripherals;
}

@end
