import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ble_service.dart';

final bleServiceProvider = Provider<BleService>((ref) {
  final service = BleService();
  ref.onDispose(service.dispose);
  return service;
});

final connectionStateProvider = StreamProvider<BluetoothConnectionState>((ref) {
  return ref.watch(bleServiceProvider).connectionState;
});

final connectedDeviceIdProvider = Provider<String?>((ref) {
  return ref.watch(bleServiceProvider).connectedDeviceId;
});

final connectedDeviceNameProvider = Provider<String?>((ref) {
  return ref.watch(bleServiceProvider).connectedDeviceName;
});

final chugDurationProvider = StreamProvider<int>((ref) {
  return ref.watch(bleServiceProvider).chugDurationStream;
});
