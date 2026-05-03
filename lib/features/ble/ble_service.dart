import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_constants.dart';
import 'ble_decoder.dart';
import 'package:permission_handler/permission_handler.dart';

class BleService {
  BluetoothDevice? _device;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notifySubscription;

  final _chugDurationController = StreamController<int>.broadcast();
  final _connectionStateController =
      StreamController<BluetoothConnectionState>.broadcast();

  Stream<int> get chugDurationStream => _chugDurationController.stream;

  Stream<BluetoothConnectionState> get connectionState =>
      _connectionStateController.stream;

  String? get connectedDeviceId => _device?.remoteId.str;

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults.map(
    (results) => results
  //      .where(
  //        (r) => r.advertisementData.serviceUuids.any(
  //          (u) => u.str.toUpperCase() == kServiceUuid.toUpperCase(),
 //        ),
 //       )
        .toList(),
  );

  Future<void> startScan() async {
    // Request permissions first
    await [Permission.bluetoothScan, Permission.bluetoothConnect].request();

    await FlutterBluePlus.startScan(
      withServices: [Guid(kServiceUuid)],
      timeout: const Duration(seconds: 10),
    );
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connect(BluetoothDevice device) async {
    _device = device;

    _connectionSubscription = device.connectionState.listen((state) {
      _connectionStateController.add(state);
      if (state == BluetoothConnectionState.disconnected) {
        _notifySubscription?.cancel();
        _notifySubscription = null;
      }
    });

    await device.connect();
    await _subscribeToChugResult(device);
  }

  Future<void> _subscribeToChugResult(BluetoothDevice device) async {
    final services = await device.discoverServices();
    for (final service in services) {
    debugPrint('SERVICE: ${service.serviceUuid.str}');
    for (final char in service.characteristics) {
      debugPrint('  CHAR: ${char.characteristicUuid.str} | properties: ${char.properties}');
    }
    for (final service in services) {
      if (service.serviceUuid.str.toUpperCase() != kServiceUuid.toUpperCase()) {
        continue;
      }
      for (final char in service.characteristics) {
        if (char.characteristicUuid.str.toUpperCase() !=
            kChugResultCharUuid.toUpperCase()) {
          continue;
        }
        await char.setNotifyValue(true);
        _notifySubscription = char.lastValueStream.listen((bytes) {
          try {
            final ms = decodeChugDuration(bytes);
            _chugDurationController.add(ms);
          } catch (e) {
            debugPrint('BLE: failed to decode chug payload: $e');
          }
        });
        return;
      }
    }
    debugPrint('BLE: chug-result characteristic not found');
    }
  }

  Future<void> disconnect() async {
    await _notifySubscription?.cancel();
    _notifySubscription = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    await _device?.disconnect();
    _device = null;
  }

  void dispose() {
    _notifySubscription?.cancel();
    _connectionSubscription?.cancel();
    _chugDurationController.close();
    _connectionStateController.close();
  }
}
