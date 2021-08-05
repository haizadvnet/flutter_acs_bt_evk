//
//  FlutterAcsBtEvkFactory.h
//  flutter_acs_bt_evk
//
//  Created by 李晓康 on 2021/4/26.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface FlutterAcsBtEvkFactory : NSObject
- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger> *)messager;
@end

NS_ASSUME_NONNULL_END
