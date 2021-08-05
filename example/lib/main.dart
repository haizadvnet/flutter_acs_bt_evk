import 'package:flutter/material.dart';
import 'package:flutter_acs_bt_evk/flutter_acs_bt_evk.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MaterialApp(
    home: HomePage(),
  ));
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final acs = FlutterAcsBtEvk.init();
  String address = '64:69:4E:A4:6F:83';
  String text = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ACS插件Demo'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              child: SingleChildScrollView(child: Text(text)),
            ),
            Container(
              height: 2,
              width: double.infinity,
              color: Colors.black12,
            ),
            Wrap(
              spacing: 5,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    initListener();
                    notifyText('开始连接...');
                    await acs.connectDevice(address);
                  },
                  child: Text('打开'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.clear();
                    setState(() {
                      text = '';
                    });
                  },
                  child: Text('关闭'),
                ),
              ],
            ),
            Container(
              height: 2,
              width: double.infinity,
              color: Colors.black12,
            ),
            Wrap(
              spacing: 5,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    if (await Permission.location.request().isGranted) {
                      print('已获取权限');
                    }
                    await acs.scanDevice(true);
                  },
                  child: Text('扫描设备'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.scanDevice(false);
                  },
                  child: Text('停止扫描'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.connectDevice(address);
                  },
                  child: Text('连接设备'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.disconnectDevice();
                  },
                  child: Text('断开连接'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.authenticate();
                  },
                  child: Text('身份认证'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.startPolling();
                  },
                  child: Text('开启轮询'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.stopPolling();
                  },
                  child: Text('停止轮询'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.powerOnCard();
                  },
                  child: Text('卡片上电'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.powerOffCard();
                  },
                  child: Text('卡片下电'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.transmitApdu('FFCA000000');
                  },
                  child: Text('获取卡号'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.transmitEscapeCommand('E000004804');
                  },
                  child: Text('禁用休眠'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.getBatteryLevel();
                  },
                  child: Text('获取电量'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.clear();
                  },
                  child: Text('销毁'),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                bool isBluetoothEnable = await acs.isBluetoothEnabled();
                if (!isBluetoothEnable) {
                  _openBluetooth();
                } else {
                  print('main.dart:163 --> ${'蓝牙已经打开,可以使用'}');
                }
              },
              child: Text('打开蓝牙'),
            ),
          ],
        ),
      ),
    );
  }

  /// 打开蓝牙提醒
  _openBluetooth() async {
    bool isOpen = await showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(
              '打开蓝牙提醒',
            ),
            content: Text(
              '蓝牙暂未打开，是否确定打开蓝牙？',
            ),
            actions: [
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text(
                  '取消',
                ),
              ),
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text(
                  '确定',
                ),
              )
            ],
          );
        });
    if (isOpen) {
      acs.openBluetooth();
    }
  }

  void initListener() {
    acs.onEscapeResponseAvailableCallback = (String response) {
      if ("E1 00 00 00 01 04" == response) {
        notifyText("onEscapeResponseAvailableCallback:禁用休眠设置成功");
      }
    };
    acs.onBatteryLevelAvailableCallback = (int batteryLevel) {
      notifyText("onBatteryLevelAvailableCallback:电池电量:$batteryLevel");
    };
    acs.onEnableNotificationCompleteCallback = () {
      notifyText("onEnableNotificationCompleteCallback:设备已连接");
      acs.authenticate();
    };
    acs.onAuthenticationCompleteCallback = () {
      notifyText("onAuthenticationCompleteCallback:设备已授权");
      acs.startPolling();
    };
    acs.onCardStatusChangeCallback = (int cardStatus) {
      if (cardStatus == 2) {
        notifyText("onCardStatusChangeCallback:有卡");
        acs.powerOnCard();
      } else {
        notifyText("onCardStatusChangeCallback:无卡");
        acs.powerOffCard();
      }
    };
    acs.onAtrAvailableCallback = (String atr) {
      notifyText("onAtrAvailableCallback:卡片已连接");
      acs.transmitApdu('FFCA000000');
    };
    acs.onResponseApduAvailableCallback = (String response) {
      notifyText(
          "onResponseApduAvailableCallback:卡号:${response.substring(0, 14)}");
    };
    acs.onLeScanCallback = (List devices) {
      BluetoothDevice device = devices.first;
      address = device.address;
      print('发现设备:$device');
    };
  }

  void notifyText(String msg) {
    setState(() {
      text = "$msg\r\n" + text;
    });
  }
}
