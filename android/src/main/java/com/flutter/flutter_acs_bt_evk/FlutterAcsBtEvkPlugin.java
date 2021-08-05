package com.flutter.flutter_acs_bt_evk;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import androidx.annotation.NonNull;

import com.acs.bluetooth.Acr1255uj1Reader;
import com.acs.bluetooth.BluetoothReader;
import com.acs.bluetooth.BluetoothReaderGattCallback;
import com.acs.bluetooth.BluetoothReaderManager;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * FlutterAcsBtEvkPlugin
 */
public class FlutterAcsBtEvkPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    private MethodChannel channel;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_acs_bt_evk");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding activityPluginBinding) {

    }

    @Override
    public void onDetachedFromActivity() {

    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding activityPluginBinding) {
        activity = activityPluginBinding.getActivity();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        Log.e(TAG, "调用Native方法: " + call.method + "," + call.arguments);

        switch (call.method) {
            case "init":
                init();
                result.success(true);
                break;
            case "scanDevice":
                boolean enable = call.arguments();
                if (enable) {
                    result.success(scanDevice());
                } else {
                    stopScanDevice();
                    result.success(true);
                }
                break;
            case "connectDevice":
                String deviceAddress = call.arguments();
                if (deviceAddress != null && !deviceAddress.isEmpty()) {
                    connectDevice(deviceAddress);
                }
                result.success(true);
                break;
            case "disconnectDevice":
                result.success(disconnectDevice());
                break;
            case "authenticate":
                result.success(authenticate());
                break;
            case "startPolling":
                result.success(startPolling());
                break;
            case "stopPolling":
                result.success(stopPolling());
                break;
            case "powerOnCard":
                result.success(powerOnCard());
                break;
            case "powerOffCard":
                result.success(powerOffCard());
                break;
            case "transmitApdu":
                String apduCommand = call.arguments();
                if (apduCommand != null && !apduCommand.isEmpty()) {
                    result.success(transmitApdu(apduCommand));
                }
                break;
            case "transmitEscapeCommand":
                String escapeCommand = call.arguments();
                if (escapeCommand != null && !escapeCommand.isEmpty()) {
                    result.success(transmitEscapeCommand(escapeCommand));
                }
                break;
            case "getBatteryLevel":
                result.success(getBatteryLevel());
                break;
            case "clear":
                result.success(clear());
                break;
            case "openBluetooth":
                result.success(openBluetooth());
                break;
            case "isBluetoothEnabled":
                result.success(isBluetoothEnabled());
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private static final String TAG = "FlutterAcsBtEvkPlugin";
    private static final byte[] AUTO_POLLING_START = {(byte) 0xE0, 0x00, 0x00, 0x40, 0x01};
    private static final byte[] AUTO_POLLING_STOP = {(byte) 0xE0, 0x00, 0x00, 0x40, 0x00};
    private Activity activity;
    private final List<BluetoothDevice> mLeDevices = new ArrayList<>();
    private BluetoothAdapter mBluetoothAdapter;
    private BluetoothReader mBluetoothReader;
    private BluetoothGatt mBluetoothGatt;
    /**
     * 阅读管理器
     */
    final BluetoothReaderManager mBluetoothReaderManager = new BluetoothReaderManager();
    /**
     * 阅读管理器回到
     */
    final BluetoothReaderGattCallback mGattCallback = new BluetoothReaderGattCallback();
    /**
     * 蓝牙扫描回调,用于发现蓝牙设备
     */
    BluetoothAdapter.LeScanCallback mLeScanCallback = new BluetoothAdapter.LeScanCallback() {
        @Override
        public void onLeScan(BluetoothDevice device, int rssi, byte[] scanRecord) {
            if (device != null && device.getName() != null && device.getName().startsWith("ACR")) {
                if (!mLeDevices.contains(device)) {
                    Log.e(TAG, "发现新设备: " + device.getName());
                    mLeDevices.add(device);
                    notifyLeScan();
                }
            }
        }
    };

    /**
     * 初始化蓝牙阅读器监听
     */
    void initBluetoothReaderListener() {
        // Acr1255uj1Reader
        if (mBluetoothReader != null && mBluetoothReader instanceof Acr1255uj1Reader) {
            // 电池信息可用
            ((Acr1255uj1Reader) mBluetoothReader)
                    .setOnBatteryLevelAvailableListener(new Acr1255uj1Reader.OnBatteryLevelAvailableListener() {
                        @Override
                        public void onBatteryLevelAvailable(BluetoothReader bluetoothReader, final int batteryLevel,
                                                            int status) {
                            Log.e(TAG, "onBatteryLevelAvailable: 电池信息" + batteryLevel);
                            Map<String, Integer> ret = new HashMap<>();
                            ret.put("result", batteryLevel);
                            postMessage("onBatteryLevelAvailable", ret);
                        }
                    });
            // 卡状态可用
            mBluetoothReader.setOnCardStatusAvailableListener(new BluetoothReader.OnCardStatusAvailableListener() {
                @Override
                public void onCardStatusAvailable(BluetoothReader bluetoothReader, final int cardStatus,
                                                  final int errorCode) {
                    Log.e(TAG, "onCardStatusAvailable: 卡片状态可用");
                }
            });
            // 设备信息可用监听
            mBluetoothReader.setOnDeviceInfoAvailableListener(new BluetoothReader.OnDeviceInfoAvailableListener() {
                @Override
                public void onDeviceInfoAvailable(BluetoothReader bluetoothReader, final int infoId, final Object o,
                                                  final int status) {
                    Log.e(TAG, "onDeviceInfoAvailable: 设备信息可用");
                }
            });
            // 电池电量变化监听
            ((Acr1255uj1Reader) mBluetoothReader)
                    .setOnBatteryLevelChangeListener(new Acr1255uj1Reader.OnBatteryLevelChangeListener() {
                        @Override
                        public void onBatteryLevelChange(BluetoothReader bluetoothReader, int batteryLevel) {
                            Log.e(TAG, "onBatteryLevelChange: 电池电量变化" + batteryLevel);
                        }
                    });
            // 卡上电源关闭完成监听
            mBluetoothReader.setOnCardPowerOffCompleteListener(new BluetoothReader.OnCardPowerOffCompleteListener() {
                @Override
                public void onCardPowerOffComplete(BluetoothReader bluetoothReader, final int result) {
                    Log.e(TAG, "onCardPowerOffComplete: 卡片下电完成");
                }
            });

            // atr可用监听
            mBluetoothReader.setOnAtrAvailableListener(new BluetoothReader.OnAtrAvailableListener() {
                @Override
                public void onAtrAvailable(BluetoothReader bluetoothReader, final byte[] atr, final int errorCode) {
                    Log.e(TAG, "onAtrAvailable: atr可用:" + Utils.toHexString(atr));
                    Map<String, String> ret = new HashMap<>();
                    ret.put("result", Utils.toHexString(atr));
                    postMessage("onAtrAvailable", ret);
                }
            });

            // APDU可用监听
            mBluetoothReader.setOnResponseApduAvailableListener(new BluetoothReader.OnResponseApduAvailableListener() {
                @Override
                public void onResponseApduAvailable(BluetoothReader bluetoothReader, final byte[] response,
                                                    final int errorCode) {
                    Log.e(TAG, "onResponseApduAvailable: APDU可用:"
                            + Utils.toHexString(response).replace(" ", "").substring(0, 14));
                    Map<String, String> ret = new HashMap<>();
                    ret.put("result", Utils.toHexString(response));
                    postMessage("onResponseApduAvailable", ret);
                }
            });
            // escape可用监听
            mBluetoothReader
                    .setOnEscapeResponseAvailableListener(new BluetoothReader.OnEscapeResponseAvailableListener() {
                        @Override
                        public void onEscapeResponseAvailable(BluetoothReader bluetoothReader, final byte[] response,
                                                              final int errorCode) {
                            Log.e(TAG, "onEscapeResponseAvailable: escape可用:" + Utils.toHexString(response));
                            Map<String, String> ret = new HashMap<>();
                            ret.put("result", Utils.toHexString(response));
                            postMessage("onEscapeResponseAvailable", ret);

                        }
                    });

            // 在启用通知完成监听
            mBluetoothReader.setOnEnableNotificationCompleteListener(
                    new BluetoothReader.OnEnableNotificationCompleteListener() {
                        @Override
                        public void onEnableNotificationComplete(BluetoothReader bluetoothReader, final int result) {
                            Log.e(TAG, "onEnableNotificationComplete: 启动通知完成");
                            postMessage("onEnableNotificationComplete", null);
                        }
                    });
            // 身份验证完成监听
            mBluetoothReader
                    .setOnAuthenticationCompleteListener(new BluetoothReader.OnAuthenticationCompleteListener() {
                        @Override
                        public void onAuthenticationComplete(BluetoothReader bluetoothReader, final int errorCode) {
                            Log.e(TAG, "onAuthenticationComplete: 认证完成");
                            postMessage("onAuthenticationComplete", null);
                        }
                    });
            // 卡状态更改监听,有无卡状态
            mBluetoothReader.setOnCardStatusChangeListener(new BluetoothReader.OnCardStatusChangeListener() {
                @Override
                public void onCardStatusChange(BluetoothReader bluetoothReader, int cardStatus) {
                    Log.e(TAG, "onCardStatusChange: 卡片状态改变" + cardStatus);
                    Map<String, Integer> ret = new HashMap<>();
                    ret.put("result", cardStatus);
                    postMessage("onCardStatusChange", ret);
                }
            });
        }
    }

    // 发送数据
    void postMessage(final String method, final Map msg) {
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                channel.invokeMethod(method, msg);
            }
        });
    }

    // 通知flutter层
    void notifyLeScan() {
        if (mLeDevices.isEmpty()) {
            return;
        }
        Map<String, List<Map<String, String>>> ret = new HashMap<>();
        List<Map<String, String>> devices = new ArrayList<>();
        for (BluetoothDevice device : mLeDevices) {
            Map<String, String> map = new HashMap<>();
            map.put("name", device.getName());
            map.put("address", device.getAddress());
            devices.add(map);
        }
        ret.put("result", devices);
        channel.invokeMethod("onLeScan", ret);
    }


    /**
     * 初始化蓝牙管理器
     */
    void init() {
        if (mBluetoothAdapter == null) {
            // 蓝牙管理器
            BluetoothManager bluetoothManager = (BluetoothManager) activity.getSystemService(Context.BLUETOOTH_SERVICE);
            mBluetoothAdapter = bluetoothManager.getAdapter();
        }
    }

    /**
     * 蓝牙是否可用
     *
     * @return
     */
    boolean isBluetoothEnabled() {
        if (mBluetoothAdapter == null) {
            return false;
        }
        return mBluetoothAdapter.isEnabled();
    }


    /**
     * 申请打开蓝牙
     *
     * @return
     */
    boolean openBluetooth() {
        //蓝牙是否可用
        if (!isBluetoothEnabled()) {
            //打开蓝牙
            Intent enabler = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            activity.startActivityForResult(enabler, 1);
        }
        return true;
    }

    /**
     * 开始扫描蓝牙设备
     */
    boolean scanDevice() {
        if (mBluetoothAdapter != null) {
            return mBluetoothAdapter.startLeScan(mLeScanCallback);
        }
        return false;
    }

    /**
     * 停止扫描蓝牙设备
     */
    void stopScanDevice() {
        if (mBluetoothAdapter != null) {
            mBluetoothAdapter.stopLeScan(mLeScanCallback);
        }
    }

    /**
     * 连接设备
     */
    void connectDevice(String deviceAddress) {
        mBluetoothReaderManager.setOnReaderDetectionListener(new BluetoothReaderManager.OnReaderDetectionListener() {
            @Override
            public void onReaderDetection(BluetoothReader reader) {
                if (reader instanceof Acr1255uj1Reader) {
                    mBluetoothReader = reader;
                    // 设置蓝牙读取器的各种监听
                    initBluetoothReaderListener();
                    // 启用通知
                    mBluetoothReader.enableNotification(true);
                }
            }
        });

        mGattCallback
                .setOnConnectionStateChangeListener(new BluetoothReaderGattCallback.OnConnectionStateChangeListener() {
                    @Override
                    public void onConnectionStateChange(BluetoothGatt gatt, int state, int newState) {
                        Log.e(TAG, "onConnectionStateChange: " + newState);
                        if (newState == BluetoothProfile.STATE_CONNECTED) {// 设备连接
                            mBluetoothReaderManager.detectReader(gatt, mGattCallback);
                        } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {// 设备断开连接,销毁
                            disconnectDevice();
                        }
                    }
                });
        // 断开已有连接
        disconnectDevice();
        // 连接蓝牙设备
        if (mBluetoothAdapter != null) {
            BluetoothDevice device = mBluetoothAdapter.getRemoteDevice(deviceAddress);
            mBluetoothGatt = device.connectGatt(activity, false, mGattCallback);
        }
    }

    /**
     * 断开设备
     */
    boolean disconnectDevice() {
        if (mBluetoothGatt != null) {
            mBluetoothGatt.disconnect();
            mBluetoothGatt.close();
            mBluetoothGatt = null;
        }
        return true;
    }

    /**
     * 设备认证,使用默认认证秘钥
     */
    boolean authenticate() {
        byte[] masterKey = Utils.getTextHexBytes("41 43 52 31 32 35 35 55 2D 4A 31 20 41 75 74 68");
        if (mBluetoothReader != null) {
            return mBluetoothReader.authenticate(masterKey);
        }
        return false;
    }

    /**
     * 开始卡轮询
     *
     * @return
     */
    boolean startPolling() {
        if (mBluetoothReader != null) {
            return mBluetoothReader.transmitEscapeCommand(AUTO_POLLING_START);
        }
        return false;
    }

    /**
     * 停止卡轮询
     *
     * @return
     */
    boolean stopPolling() {
        if (mBluetoothReader != null) {
            return mBluetoothReader.transmitEscapeCommand(AUTO_POLLING_STOP);
        }
        return false;
    }

    /**
     * 卡片上电
     *
     * @return
     */
    boolean powerOnCard() {
        if (mBluetoothReader != null) {
            return mBluetoothReader.powerOnCard();
        }
        return false;
    }

    /**
     * 卡片下电
     *
     * @return
     */
    boolean powerOffCard() {
        if (mBluetoothReader != null) {
            return mBluetoothReader.powerOffCard();
        }
        return false;
    }

    /**
     * 发送APDU指令 卡片通讯
     *
     * @return
     */
    boolean transmitApdu(String apduCommand) {
        if (mBluetoothReader != null) {
            byte[] hexBytes = Utils.getTextHexBytes(apduCommand);
            if (hexBytes != null) {
                return mBluetoothReader.transmitApdu(hexBytes);
            }
        }
        return false;
    }

    /**
     * 发送escape指令 蓝牙设备通讯
     *
     * @return
     */
    boolean transmitEscapeCommand(String escapeCommand) {
        if (mBluetoothReader != null) {
            byte[] hexBytes = Utils.getTextHexBytes(escapeCommand);
            if (hexBytes != null) {
                return mBluetoothReader.transmitEscapeCommand(hexBytes);
            }
        }
        return false;
    }

    /**
     * 获取电量信息
     *
     * @return
     */
    boolean getBatteryLevel() {
        if (mBluetoothReader != null) {
            if (mBluetoothReader instanceof Acr1255uj1Reader) {
                return ((Acr1255uj1Reader) mBluetoothReader).getBatteryLevel();
            }
        }
        return false;
    }

    /**
     * 销毁,释放内存
     */
    boolean clear() {
        stopPolling();
        stopScanDevice();
        disconnectDevice();
        mBluetoothReader = null;
        mLeDevices.clear();
        return true;
    }
}
