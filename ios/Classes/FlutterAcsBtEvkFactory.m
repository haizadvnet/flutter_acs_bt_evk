//
//  FlutterAcsBtEvkFactory.m
//  flutter_acs_bt_evk
//
//  Created by 李晓康 on 2021/4/26.
//

#import "FlutterAcsBtEvkFactory.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <ACSBluetooth/ACSBluetooth.h>

#import "ABDHex.h"
#import "AcsBtEvkCallBackConst.h"
#import "DiscoverPeripheralManager.h"

@interface FlutterAcsBtEvkFactory ()<CBCentralManagerDelegate, ABTBluetoothReaderManagerDelegate, ABTBluetoothReaderDelegate, UIAlertViewDelegate>
{
    FlutterMethodChannel * _channel;
    
    CBCentralManager *_centralManager;
    CBPeripheral *_peripheral;

    ABTBluetoothReaderManager *_bluetoothReaderManager;
    ABTBluetoothReader *_bluetoothReader;
    
    NSData *_masterKey;
    NSData *_commandApdu;
    NSData *_escapeCommand;

}

@end

@implementation FlutterAcsBtEvkFactory


- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger> *)messager {
    self = [super init];
    if (self) {
        _channel = [FlutterMethodChannel methodChannelWithName:@"flutter_acs_bt_evk" binaryMessenger:messager];
        __weak __typeof__(self) weakSelf = self;
        [_channel setMethodCallHandler:^(FlutterMethodCall *  call, FlutterResult  result) {
            [weakSelf onMethodCall:call result:result];
        }];
    }
    return self;
}

-(void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result{
    if ([@"init" isEqualToString:call.method]) {
        [self initParams];
        result(@YES);
    } else if ([@"scanDevice" isEqualToString:call.method]) {
        BOOL enable = [call.arguments boolValue];
        if (enable) {
            [self startScanPeripherals];
        } else {
            [self stopScanPeripherals];
        }
        result(@YES);
    } else if ([@"connectDevice" isEqualToString:call.method]) {
        NSString * deviceAddress = call.arguments;
        if (deviceAddress == nil || deviceAddress.length == 0) {
            result(@NO);
        } else {
            [self connectDevice: call.arguments];
            result(@YES);
        }
    } else if ([@"disconnectDevice" isEqualToString:call.method]) {
        [self disconnectDevice];
        result(@YES);
    } else if ([@"authenticate" isEqualToString:call.method]) {
        BOOL authen = [self authenticate];
        result(@(authen));
    } else if ([@"startPolling" isEqualToString:call.method]) {
        result(@([self startPolling]));
    } else if ([@"stopPolling" isEqualToString:call.method]) {
        result(@([self stopPolling]));
    } else if ([@"powerOnCard" isEqualToString:call.method]) {
        result(@([self powerOnCard]));
    } else if ([@"powerOffCard" isEqualToString:call.method]) {
        result(@([self powerOffCard]));
    } else if ([@"transmitApdu" isEqualToString:call.method]) {
        NSString * apduStr = call.arguments;
        if (apduStr != nil && apduStr.length > 0) {
            _commandApdu = [ABDHex byteArrayFromHexString:apduStr];
        }
        result(@([self transmitApdu:_commandApdu]));
    } else if ([@"transmitEscapeCommand" isEqualToString:call.method]) {
        NSString * escapeStr = call.arguments;
        if (escapeStr != nil && escapeStr.length > 0) {
            _escapeCommand = [ABDHex byteArrayFromHexString:escapeStr];
        }
        result(@([self transmitEscapeCommand:_escapeCommand]));
    } else if ([@"getBatteryLevel" isEqualToString:call.method]) {
        [self getBatteryLevel];
        result(@YES);
    } else if ([@"clear" isEqualToString:call.method]) {
        [self clear];
        result(@YES);
    } else if ([@"isBluetoothEnabled" isEqualToString:call.method]) {
        result(@([self isBluetoothEnabled]));
    } else if ([@"openBluetooth" isEqualToString:call.method]) {
        [self openBluetooth];
        result(@YES);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)dealloc {
    NSLog(@"dealloc");
    _bluetoothReader = nil;
    _centralManager = nil;
    _bluetoothReaderManager = nil;
}

#pragma mark - method
/// 初始化蓝牙参数
- (void)initParams{
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    _bluetoothReaderManager = [[ABTBluetoothReaderManager alloc] init];
    _bluetoothReaderManager.delegate = self;
    
    /// 蓝牙关键key,写死,无需修改
    _masterKey = [ABDHex byteArrayFromHexString:@"41 43 52 31 32 35 35 55 2D 4A 31 20 41 75 74 68"];
    _commandApdu = [ABDHex byteArrayFromHexString:@"FFCA000000"];
    _escapeCommand = [ABDHex byteArrayFromHexString:@"04 00"];
}

/// 开始扫描设备
- (void)startScanPeripherals {
    if ([self ABD_checkBluetooth]) {
        if (_centralManager != nil) {
            
            if (_bluetoothReader != nil) {
                [_bluetoothReader detach];
            }
            
            if (_peripheral != nil) {
                [self disconnectDevice];
                _peripheral = nil;
            }
            
            [[DiscoverPeripheralManager shareManager].peripherals removeAllObjects];
            
            [_centralManager scanForPeripheralsWithServices:nil options:nil];
        }
    }
}

/// 停止扫描设备
- (void)stopScanPeripherals {
    if (_centralManager != nil) {
        [_centralManager stopScan];
    }
}

/// 链接设备
/// deviceAddress: 即扫描设备时传递回去的name
- (void)connectDevice:(NSString *)deviceAddress {
    [self stopScanPeripherals];
    
    if (_peripheral != nil) {
        [self disconnectDevice];
        _peripheral = nil;
    }
    for (CBPeripheral * peripheral in [DiscoverPeripheralManager shareManager].peripherals) {
        if ([peripheral.name isEqualToString:deviceAddress]) {
            if (_centralManager != nil) {
                _peripheral = peripheral;
                [_centralManager connectPeripheral:_peripheral options:nil];
            }
        }
    }
}

/// 断开设备
- (void)disconnectDevice {
    if (_peripheral != nil) {
        [_centralManager cancelPeripheralConnection:_peripheral];
        _peripheral = nil;
    }
}

/// 身份认证
- (BOOL)authenticate {
    if (_bluetoothReader != nil) {
        return [_bluetoothReader authenticateWithMasterKey:_masterKey];
    }
    return NO;
}

/// 开始卡片轮询
- (BOOL)startPolling {
    if (_bluetoothReader != nil) {
        if ([_bluetoothReader isKindOfClass:[ABTAcr1255uj1Reader class]]) {
            uint8_t command[] = { 0xE0, 0x00, 0x00, 0x40, 0x01 };
            return [_bluetoothReader transmitEscapeCommand:command length:sizeof(command)];
        }
        return NO;
    }
    return NO;;
}

/// 结束轮询
- (BOOL)stopPolling {
    if (_bluetoothReader != nil) {
        if ([_bluetoothReader isKindOfClass:[ABTAcr1255uj1Reader class]]) {
            uint8_t command[] = { 0xE0, 0x00, 0x00, 0x40, 0x00 };
            return [_bluetoothReader transmitEscapeCommand:command length:sizeof(command)];
        }
        return NO;
    }
    return NO;
}

/// 卡片上电
- (BOOL)powerOnCard {
    if (_bluetoothReader != nil) {
        return [_bluetoothReader powerOnCard];
    }
    return NO;
}

/// 卡片下电
- (BOOL)powerOffCard {
    if (_bluetoothReader != nil) {
        return [_bluetoothReader powerOffCard];
    }
    return NO;
}

/// 发送APDU指令
- (BOOL)transmitApdu:(NSData *)commandApdu {
    if (_bluetoothReader != nil) {
        return [_bluetoothReader transmitApdu:commandApdu];
    }
    return NO;
}

/// 发送escape指令
- (BOOL)transmitEscapeCommand:(NSData *)escapeCommand {
    if (_bluetoothReader != nil) {
        return [_bluetoothReader transmitEscapeCommand:escapeCommand];
    }
    return NO;
}

/// 销毁
- (void)clear {
    NSLog(@"销毁");
    [self stopPolling];
    [self stopScanPeripherals];
    [self disconnectDevice];
    
    _peripheral = nil;
}

/// 获取蓝牙状态
- (BOOL)isBluetoothEnabled {
    return [self ABD_checkBluetooth];
}

/// 打开蓝牙设置
- (void)openBluetooth {
    NSURL *url = [NSURL URLWithString:@"App-Prefs:root=Bluetooth"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

///// 打开蓝牙设置
//- (void)bluetoothEnable {
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"打开蓝牙" message:@"是否前往设置中打开蓝牙?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles: @"确定", nil];
//    [alert show];
//}
//
//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
//    if (buttonIndex == 1) {
//        NSURL *url = [NSURL URLWithString:@"App-Prefs:root=Bluetooth"];
//        if ([[UIApplication sharedApplication] canOpenURL:url]) {
//            [[UIApplication sharedApplication] openURL:url];
//        }
//    }
//}


#pragma mark - other method
- (void)getDeviceInfo {

    // Get the device information.
    [_bluetoothReader getDeviceInfoWithType:ABTBluetoothReaderDeviceInfoSystemId];
    [_bluetoothReader getDeviceInfoWithType:ABTBluetoothReaderDeviceInfoModelNumberString];
    [_bluetoothReader getDeviceInfoWithType:ABTBluetoothReaderDeviceInfoSerialNumberString];
    [_bluetoothReader getDeviceInfoWithType:ABTBluetoothReaderDeviceInfoFirmwareRevisionString];
    [_bluetoothReader getDeviceInfoWithType:ABTBluetoothReaderDeviceInfoHardwareRevisionString];
    [_bluetoothReader getDeviceInfoWithType:ABTBluetoothReaderDeviceInfoManufacturerNameString];
}

- (void)getBatteryStatus {

    if ([_bluetoothReader isKindOfClass:[ABTAcr3901us1Reader class]]) {

        ABTAcr3901us1Reader *reader = (ABTAcr3901us1Reader *) _bluetoothReader;

        // Get the battery status.
        [reader getBatteryStatus];
    }
}

- (void)getBatteryLevel {

    if ([_bluetoothReader isKindOfClass:[ABTAcr1255uj1Reader class]]) {

        ABTAcr1255uj1Reader *reader = (ABTAcr1255uj1Reader *) _bluetoothReader;
        
        // Get the battery level.
        [reader getBatteryLevel];
    }
}

- (void)getCardStatus {

    // Get the card status.
    [_bluetoothReader getCardStatus];
}

#pragma mark - Central Manager

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {

    static BOOL firstRun = YES;
    NSString *message = nil;
    NSLog(@"centralManagerDidUpdateState: %@", central);
    switch (central.state) {

        case CBCentralManagerStateUnknown:
        case CBCentralManagerStateResetting:
            message = @"The update is being started. Please wait until Bluetooth is ready.";
            break;

        case CBCentralManagerStateUnsupported:
            message = @"此设备不支持蓝牙低功耗.";
            break;

        case CBCentralManagerStateUnauthorized:
            message = @"此应用程序未被授权使用蓝牙低能耗.";
            break;

        case CBCentralManagerStatePoweredOff:
            if (!firstRun) {
                message = @"你必须在设置中打开蓝牙才能使用阅读器!!!";
            }
            break;
        case CBManagerStatePoweredOn:
            [self startScanPeripherals];
            break;
        default:
            break;
    }

    if (message != nil) {

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Bluetooth" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }

    firstRun = NO;
}

/// 扫描设备回调
/// 找到名称前缀为ACR的那个设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSMutableArray * temp = [NSMutableArray array];
    if ([peripheral.name hasPrefix:@"ACR"]) {
        [[DiscoverPeripheralManager shareManager].peripherals addObject:peripheral];
        /// peripheral.identifier会根据设备的改变而变化,所以暂时放peripheral.name,name也是唯一的
        NSDictionary * arguments = @{
            @"name": peripheral.name,
            @"address": peripheral.name
        };
        [temp addObject:arguments];
    }
    if (temp.count > 0) {
        [_channel invokeMethod:onLeScan arguments:@{@"result": temp} result:nil];
    }
}

/// 链接设备的回调
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {

    // Detect the Bluetooth reader.
    [_bluetoothReaderManager detectReaderWithPeripheral:peripheral];
}

/// 设备连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {

    // Show the error
    if (error != nil) {
        [self ABD_showError:error];
    }
}

/// 断开链接的回调
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {

    if (error != nil) {

        // Show the error
        [self ABD_showError:error];

    } else {

//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Information" message:@"The reader is disconnected successfully." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
//        [alert show];
    }
}

#pragma mark - Bluetooth Reader Manager
/// 当检测到蓝牙阅读器时调用。
- (void)bluetoothReaderManager:(ABTBluetoothReaderManager *)bluetoothReaderManager didDetectReader:(ABTBluetoothReader *)reader peripheral:(CBPeripheral *)peripheral error:(NSError *)error {

    if (error != nil) {

        // Show the error
        [self ABD_showError:error];

    } else {

        // Store the Bluetooth reader.
        _bluetoothReader = reader;
        _bluetoothReader.delegate = self;

        // Attach the peripheral to the Bluetooth reader.
        [_bluetoothReader attachPeripheral:peripheral];
    }
}

#pragma mark - Bluetooth Reader
/// 设备连接成功
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didAttachPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {

    if (error != nil) {

        // Show the error
        [self ABD_showError:error];

    } else {
        [_channel invokeMethod:onEnableNotificationComplete arguments:nil result:nil];
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Information" message:@"The reader is attached to the peripheral successfully." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
//        [alert show];
    }
}

/// 设备信息
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didReturnDeviceInfo:(NSObject *)deviceInfo type:(ABTBluetoothReaderDeviceInfo)type error:(NSError *)error {

    // Show the error
    if (error != nil) {

        [self ABD_showError:error];

    } else {

        switch (type) {
                
            case ABTBluetoothReaderDeviceInfoSystemId:
                // Show the system ID.
                NSLog(@"ABTBluetoothReaderDeviceInfoSystemId: %@", [ABDHex hexStringFromByteArray:(NSData *)deviceInfo]);
                break;
                
            case ABTBluetoothReaderDeviceInfoModelNumberString:
                // Show the model number.
                NSLog(@"ABTBluetoothReaderDeviceInfoModelNumberString: %@", (NSString *) deviceInfo);
            
                break;
                
            case ABTBluetoothReaderDeviceInfoSerialNumberString:
                // Show the serial number.
                NSLog(@"ABTBluetoothReaderDeviceInfoSerialNumberString: %@", (NSString *) deviceInfo);
            
                break;
                
            case ABTBluetoothReaderDeviceInfoFirmwareRevisionString:
                // Show the firmware revision.
                NSLog(@"ABTBluetoothReaderDeviceInfoFirmwareRevisionString: %@", (NSString *) deviceInfo);

                break;
                
            case ABTBluetoothReaderDeviceInfoHardwareRevisionString:
                // Show the hardware revision.
                NSLog(@"ABTBluetoothReaderDeviceInfoHardwareRevisionString: %@", (NSString *) deviceInfo);
            
                break;
                
            case ABTBluetoothReaderDeviceInfoManufacturerNameString:
                // Show the manufacturer name.
                NSLog(@"ABTBluetoothReaderDeviceInfoHardwareRevisionString: %@", (NSString *) deviceInfo);
                break;
                
            default:
                break;
        }
    }
}

/// 身份验证回调
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didAuthenticateWithError:(NSError *)error {

    if (error != nil) {

        // Show the error
        [self ABD_showError:error];

    } else {
        [_channel invokeMethod:onAuthenticationComplete arguments:nil result:nil];
    }
}

/// atr回调
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didReturnAtr:(NSData *)atr error:(NSError *)error {

    if (error != nil) {

        // Show the error
        [self ABD_showError:error];

    } else {

        // Show the ATR string.
        NSString * atrStr = [ABDHex hexStringFromByteArray:atr];
        atrStr = [atrStr stringByReplacingOccurrencesOfString:@" " withString:@""];
        [_channel invokeMethod:onAtrAvailable arguments:@{@"result": atrStr} result:nil];
    }
}

/// 下电
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didPowerOffCardWithError:(NSError *)error {

    // Show the error
    if (error != nil) {
        [self ABD_showError:error];
    }
}

/// 返回卡片状态
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didReturnCardStatus:(ABTBluetoothReaderCardStatus)cardStatus error:(NSError *)error {

    if (error != nil) {

        // Show the error
        [self ABD_showError:error];

    } else {

        // Show the card status.
        NSLog(@"didReturnCardStatus: %@", [self ABD_stringFromCardStatus:cardStatus]);
    }
}

/// 发送APDU消息成功
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didReturnResponseApdu:(NSData *)apdu error:(NSError *)error {

    if (error != nil) {

        // Show the error
        [self ABD_showError:error];

    } else {

        // Show the response APDU.
        NSString * cardNumber = [ABDHex hexStringFromByteArray:apdu];
        cardNumber = [cardNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSLog(@"didReturnResponseApdu: %@", cardNumber);
        [_channel invokeMethod:onResponseApduAvailable arguments:@{@"result": cardNumber} result:nil];
    }
}

/// 发送escape消息成功
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didReturnEscapeResponse:(NSData *)response error:(NSError *)error {

    if (error != nil) {

        // Show the error
        [self ABD_showError:error];

    } else {

        // Show the escape response.
        NSString * escape = [ABDHex hexStringFromByteArray:response];
//        escape = [escape stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSLog(@"didReturnEscapeResponse: %@", escape);
        [_channel invokeMethod:onEscapeResponseAvailable arguments:@{@"result": escape} result:nil];
    }
}

/// 卡片状态改变
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didChangeCardStatus:(ABTBluetoothReaderCardStatus)cardStatus error:(NSError *)error {

    if (error != nil) {

        // Show the error
        [self ABD_showError:error];

    } else {

        // Show the card status.
        NSLog(@"didChangeCardStatus: %@", [self ABD_stringFromCardStatus:cardStatus]);
        NSNumber * status;
        if (cardStatus == ABTBluetoothReaderCardStatusPresent) {
            status = @2;
        } else {
            status = @1;
        }
        [_channel invokeMethod:onCardStatusChange arguments:@{@"result": status} result:nil];
    }
}

/// 电池状态改变
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didChangeBatteryStatus:(ABTBluetoothReaderBatteryStatus)batteryStatus error:(NSError *)error {

    if (error != nil) {

        // Show the error
        [self ABD_showError:error];

    } else {

        // Show the battery status.
        NSLog(@"didChangeBatteryStatus: %@", [self ABD_stringFromBatteryStatus:batteryStatus]);

    }
}

/// 电池电量
- (void)bluetoothReader:(ABTBluetoothReader *)bluetoothReader didChangeBatteryLevel:(NSUInteger)batteryLevel error:(NSError *)error {

    if (error != nil) {

        // Show the error
        [self ABD_showError:error];

    } else {

        // Show the battery level.
        NSLog(@"didChangeBatteryLevel: %@", [NSString stringWithFormat:@"%lu%%", (unsigned long) batteryLevel]);
        NSNumber * level = [NSNumber numberWithUnsignedInteger:batteryLevel];
        [_channel invokeMethod:onBatteryLevelAvailable arguments:@{@"result": level} result:nil];
    }
}

#pragma mark - Private Methods

/**
 * Returns YES if Bluetooth is ready.
 */
- (BOOL)ABD_checkBluetooth {

    NSString *message = nil;

    switch (_centralManager.state) {

        case CBCentralManagerStateUnsupported:
            message = @"此设备不支持蓝牙低功耗.";
            break;

        case CBCentralManagerStateUnauthorized:
            message = @"此应用程序未被授权使用蓝牙低能耗.";
            break;

        case CBCentralManagerStatePoweredOff:
            message = @"你必须在设置中打开蓝牙才能使用阅读器!!!";
            break;

        case CBCentralManagerStatePoweredOn:
            break;

        default:
            message = @"The update is being started. Please wait until Bluetooth is ready.";
            break;
    }

//    if (message != nil) {
//
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Bluetooth" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
//        [alert show];
//    }
    

    return (message == nil);
}

/**
 * Returns the description from the card status.
 * @param cardStatus the card status.
 * @return the description.
 */
- (NSString *)ABD_stringFromCardStatus:(ABTBluetoothReaderCardStatus)cardStatus {

    NSString *string = nil;

    switch (cardStatus) {

        case ABTBluetoothReaderCardStatusUnknown:
            string = @"Unknown";
            break;

        case ABTBluetoothReaderCardStatusAbsent:
            string = @"Absent";
            break;

        case ABTBluetoothReaderCardStatusPresent:
            string = @"Present";
            break;

        case ABTBluetoothReaderCardStatusPowered:
            string = @"Powered";
            break;

        case ABTBluetoothReaderCardStatusPowerSavingMode:
            string = @"Power Saving Mode";
            break;

        default:
            string = @"Unknown";
            break;
    }

    return string;
}

/**
 * Returns the description from the battery status.
 * @param batteryStatus the battery status.
 * @return the description.
 */
- (NSString *)ABD_stringFromBatteryStatus:(ABTBluetoothReaderBatteryStatus)batteryStatus {

    NSString *string = nil;

    switch (batteryStatus) {

        case ABTBluetoothReaderBatteryStatusNone:
            string = @"No Battery";
            break;

        case ABTBluetoothReaderBatteryStatusFull:
            string = @"Full";
            break;

        case ABTBluetoothReaderBatteryStatusUsbPlugged:
            string = @"USB Plugged";
            break;

        default:
            string = @"Low";
            break;
    }

    return string;
}

- (void)ABD_showError:(NSError *)error {

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Error %ld", (long)[error code]] message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

@end
