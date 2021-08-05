//
//  AcsBtEvkCallBackConst.h
//  Pods
//
//  Created by 李晓康 on 2021/4/26.
//

#ifndef AcsBtEvkCallBackConst_h
#define AcsBtEvkCallBackConst_h

#import <Foundation/Foundation.h>

///扫描回调事件监听
NSString *const onLeScan = @"onLeScan";
///蓝牙通知开启完成回调
NSString *const onEnableNotificationComplete = @"onEnableNotificationComplete";
///设备身份认证完成回调
NSString *const onAuthenticationComplete = @"onAuthenticationComplete";
///Escape命令可用回调
NSString *const onEscapeResponseAvailable = @"onEscapeResponseAvailable";
///卡状态变动回调,1无卡,2有卡
NSString *const onCardStatusChange = @"onCardStatusChange";
///atr可用回调
NSString *const onAtrAvailable = @"onAtrAvailable";
///APDU命令可用回调
NSString *const onResponseApduAvailable = @"onResponseApduAvailable";
/// 获取电量的回调
NSString *const onBatteryLevelAvailable = @"onBatteryLevelAvailable";

#endif /* AcsBtEvkCallBackConst_h */
