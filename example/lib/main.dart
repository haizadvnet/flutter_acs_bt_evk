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
        title: Text('NFC ACS Demo'),
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
                    notifyText('start connecting...');
                    await acs.connectDevice(address);
                  },
                  child: Text('Start'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.clear();
                    setState(() {
                      text = '';
                    });
                  },
                  child: Text('End'),
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
                      print('Permission has been obtained');
                    }
                    await acs.scanDevice(true);
                  },
                  child: Text('Scan'),
                ),
                /*ElevatedButton(
                  onPressed: () async {
                    await acs.scanDevice(false);
                  },
                  child: Text('Close'),
                ),*/
                ElevatedButton(
                  onPressed: () async {
                    await acs.connectDevice(address);
                  },
                  child: Text('Connect'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.disconnectDevice();
                  },
                  child: Text('Disconnect'),
                ),
                /*ElevatedButton(
                  onPressed: () async {
                    await acs.authenticate();
                  },
                  child: Text('Authenticate'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.startPolling();
                  },
                  child: Text('Start Poll'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.stopPolling();
                  },
                  child: Text('Stop Poll'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.powerOnCard();
                  },
                  child: Text('Card On'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.powerOffCard();
                  },
                  child: Text('Card off'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.transmitApdu('FFCA000000');
                  },
                  child: Text('Card Number'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await acs.transmitEscapeCommand('E000004804');
                  },
                  child: Text('Disable Hibernate'),
                ),*/
                ElevatedButton(
                  onPressed: () async {
                    await acs.getBatteryLevel();
                  },
                  child: Text('Battery'),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                bool isBluetoothEnable = await acs.isBluetoothEnabled();
                if (!isBluetoothEnable) {
                  _openBluetooth();
                } else {
                  print('main.dart:163 --> ${'Bluetooth is turned on and can be used'}');
                }
              },
              child: Text('On Bluetooth'),
            ),
          ],
        ),
      ),
    );
  }

  /// Turn on bluetooth reminders
  _openBluetooth() async {
    bool isOpen = await showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(
              'Turn on bluetooth reminders',
            ),
            content: Text(
              'Bluetooth is not turned on yet, are you sure you want to turn on bluetooth?？',
            ),
            actions: [
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text(
                  'Cancel',
                ),
              ),
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text(
                  'Yes',
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
        notifyText("Disable hibernate setting succeeded");
      }
    };
    acs.onBatteryLevelAvailableCallback = (int batteryLevel) {
      notifyText("Battery : $batteryLevel" + "%");
    };
    acs.onEnableNotificationCompleteCallback = () {
      notifyText("Device is connected");
      acs.authenticate();
    };
    acs.onAuthenticationCompleteCallback = () {
      notifyText("Device is authorized");
      acs.startPolling();
    };
    acs.onCardStatusChangeCallback = (int cardStatus) {
      if (cardStatus == 2) {
        notifyText("Card is available");
        acs.powerOnCard();
      } else {
        notifyText("No card found");
        acs.powerOffCard();
      }
    };
    acs.onAtrAvailableCallback = (String atr) {
      notifyText("Card is connected");
      acs.transmitApdu('FFCA000000');
    };
    acs.onResponseApduAvailableCallback = (String response) {
      notifyText("Card number: ${response.substring(0, 14)}");
    };
    acs.onLeScanCallback = (List devices) {
      BluetoothDevice device = devices.first;
      address = device.address;
      notifyText('Device discovery: $address');
    };
  }

  void notifyText(String msg) {
    setState(() {
      text = "$msg\r\n" + text;
    });
  }
}
