import 'dart:async';
import 'package:flutter/services.dart';

///扫描回调事件监听
typedef OnLeScanCallback = void Function(List<BluetoothDevice> devices);

///蓝牙通知开启完成回调
typedef OnEnableNotificationCompleteCallback = void Function();

///设备身份认证完成回调
typedef OnAuthenticationCompleteCallback = void Function();

///Escape命令可用回调
///在执行Escape命令成功后调用该方法
///跟设备通信
typedef OnEscapeResponseAvailableCallback = void Function(String response);

///电量信息可用回调
///跟设备通信
typedef OnBatteryLevelAvailableCallback = void Function(int batteryLevel);

///卡状态变动回调
/// 1,无卡
/// 2,有卡
typedef OnCardStatusChangeCallback = void Function(int cardStatus);

///atr可用回调
///卡片上电后
typedef OnAtrAvailableCallback = void Function(String atr);

///APDU命令可用回调
///在执行APDU命令成功后调用该方法
///跟NFC卡片通信
typedef OnResponseApduAvailableCallback = void Function(String response);

///蓝牙设备
class BluetoothDevice {
  String name;
  String address;

  BluetoothDevice(this.name, this.address);

  @override
  String toString() {
    return 'BluetoothDevice{name: $name, address: $address}';
  }
}

class FlutterAcsBtEvk {
  static const MethodChannel _channel =
      const MethodChannel('flutter_acs_bt_evk');

  OnEnableNotificationCompleteCallback _onEnableNotificationCompleteCallback;
  OnAuthenticationCompleteCallback _onAuthenticationCompleteCallback;
  OnEscapeResponseAvailableCallback _onEscapeResponseAvailableCallback;
  OnCardStatusChangeCallback _onCardStatusChangeCallback;
  OnAtrAvailableCallback _onAtrAvailableCallback;
  OnResponseApduAvailableCallback _onResponseApduAvailableCallback;
  OnLeScanCallback _onLeScanCallback;
  OnBatteryLevelAvailableCallback _onBatteryLevelAvailableCallback;

  set onBatteryLevelAvailableCallback(OnBatteryLevelAvailableCallback value) {
    _onBatteryLevelAvailableCallback = value;
  }

  set onEnableNotificationCompleteCallback(
      OnEnableNotificationCompleteCallback value) {
    _onEnableNotificationCompleteCallback = value;
  }

  set onAuthenticationCompleteCallback(OnAuthenticationCompleteCallback value) {
    _onAuthenticationCompleteCallback = value;
  }

  set onEscapeResponseAvailableCallback(
      OnEscapeResponseAvailableCallback value) {
    _onEscapeResponseAvailableCallback = value;
  }

  set onCardStatusChangeCallback(OnCardStatusChangeCallback value) {
    _onCardStatusChangeCallback = value;
  }

  set onAtrAvailableCallback(OnAtrAvailableCallback value) {
    _onAtrAvailableCallback = value;
  }

  set onResponseApduAvailableCallback(OnResponseApduAvailableCallback value) {
    _onResponseApduAvailableCallback = value;
  }

  set onLeScanCallback(OnLeScanCallback value) {
    _onLeScanCallback = value;
  }

  FlutterAcsBtEvk.init() {
    //初始化
    _init();
    //设置native->flutter方法回调
    _channel.setMethodCallHandler((methodCall) {
      print('调用flutter方法: ${methodCall.method},${methodCall.arguments}');
      Map arg = methodCall.arguments;
      switch (methodCall.method) {
        case 'onEnableNotificationComplete':
          if (_onEnableNotificationCompleteCallback != null) {
            _onEnableNotificationCompleteCallback();
          }
          break;
        case 'onAuthenticationComplete':
          if (_onAuthenticationCompleteCallback != null) {
            _onAuthenticationCompleteCallback();
          }
          break;
        case 'onEscapeResponseAvailable':
          if (_onEscapeResponseAvailableCallback != null) {
            _onEscapeResponseAvailableCallback(arg['result']);
          }
          break;
        case 'onCardStatusChange':
          if (_onCardStatusChangeCallback != null) {
            _onCardStatusChangeCallback(arg['result']);
          }
          break;
        case 'onAtrAvailable':
          if (_onAtrAvailableCallback != null) {
            _onAtrAvailableCallback(arg['result']);
          }
          break;
        case 'onResponseApduAvailable':
          if (_onResponseApduAvailableCallback != null) {
            _onResponseApduAvailableCallback(arg['result']);
          }
          break;
        case 'onBatteryLevelAvailable':
          if (_onBatteryLevelAvailableCallback != null) {
            _onBatteryLevelAvailableCallback(arg['result']);
          }
          break;
        case 'onLeScan':
          if (_onLeScanCallback != null) {
            List ret = arg['result'];
            var devices = ret
                .map((device) =>
                    BluetoothDevice(device['name'], device['address']))
                .toList();
            _onLeScanCallback(devices);
          }
          break;
      }
      return;
    });
  }

  ///初始化
  Future _init() async {
    await _channel.invokeMethod('init');
  }

  ///扫描设备
  Future scanDevice(bool enable) async {
    await _channel.invokeMethod('scanDevice', enable);
  }

  ///连接设备
  Future connectDevice(String deviceAddress) async {
    await _channel.invokeMethod('connectDevice', deviceAddress);
  }

  ///断开设备
  Future disconnectDevice() async {
    await _channel.invokeMethod('disconnectDevice');
  }

  ///设备认证
  Future authenticate() async {
    await _channel.invokeMethod('authenticate');
  }

  ///开始卡轮询
  Future startPolling() async {
    await _channel.invokeMethod('startPolling');
  }

  ///停止卡轮询
  Future stopPolling() async {
    await _channel.invokeMethod('stopPolling');
  }

  ///卡片上电
  Future powerOnCard() async {
    await _channel.invokeMethod('powerOnCard');
  }

  ///卡片下电
  Future powerOffCard() async {
    await _channel.invokeMethod('powerOffCard');
  }

  ///发送APDU指令
  ///和NFC卡片通讯
  Future transmitApdu(String apduCommand) async {
    await _channel.invokeMethod('transmitApdu', apduCommand);
  }

  ///发送escape指令
  ///和蓝牙设备通讯
  Future transmitEscapeCommand(String escapeCommand) async {
    await _channel.invokeMethod('transmitEscapeCommand', escapeCommand);
  }

  ///获取蓝牙设备电量
  ///和蓝牙设备通讯
  Future getBatteryLevel() async {
    await _channel.invokeMethod('getBatteryLevel');
  }

  ///打开手机蓝牙
  Future openBluetooth() async {
    await _channel.invokeMethod('openBluetooth');
  }

  ///蓝牙是否可用
  Future isBluetoothEnabled() async {
    return await _channel.invokeMethod('isBluetoothEnabled');
  }

  ///销毁
  Future clear() async {
    await _channel.invokeMethod('clear');
  }
}
