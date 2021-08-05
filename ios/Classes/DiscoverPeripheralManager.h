//
//  DiscoverPeripheralManager.h
//  flutter_acs_bt_evk
//
//  Created by 李晓康 on 2021/4/27.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DiscoverPeripheralManager : NSObject

@property(nonatomic, strong)NSMutableArray * peripherals;

+(instancetype)shareManager;
@end

NS_ASSUME_NONNULL_END
