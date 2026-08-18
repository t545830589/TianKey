import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleScanItem {
  const BleScanItem({required this.device, required this.name, required this.remoteId});

  final BluetoothDevice device;
  final String name;
  final String remoteId;
}

class TianKeyBleService {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final Map<String, BleScanItem> _found = <String, BleScanItem>{};
  BluetoothDevice? device;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  bool get isConnected => device?.isConnected ?? false;
  List<BleScanItem> get foundDevices => _found.values.toList(growable: false);

  Future<bool> isSupported() async => FlutterBluePlus.isSupported;

  Future<List<BleScanItem>> scan({Duration timeout = const Duration(seconds: 6)}) async {
    _found.clear();
    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        final name = result.advertisementData.advName.trim().isNotEmpty
            ? result.advertisementData.advName.trim()
            : result.device.platformName.trim();
        _found[result.device.remoteId.str] = BleScanItem(
          device: result.device,
          name: name.isEmpty ? '未命名 BLE 设备' : name,
          remoteId: result.device.remoteId.str,
        );
      }
    });
    try {
      await FlutterBluePlus.startScan(timeout: timeout);
      await FlutterBluePlus.isScanning.where((value) => value == false).first;
    } finally {
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    }
    return foundDevices;
  }

  Future<void> connect(BluetoothDevice target) async {
    await _connectionSubscription?.cancel();
    device = target;
    _connectionSubscription = target.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        device = null;
      }
    });
    try {
      await target.connect(timeout: const Duration(seconds: 15), autoConnect: false);
      await target.discoverServices();
    } catch (error) {
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;
      device = null;
      rethrow;
    }
  }

  Future<void> disconnect() async {
    final current = device;
    device = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    if (current != null && current.isConnected) {
      await current.disconnect();
    }
  }

  Future<void> dispose() async {
    await _scanSubscription?.cancel();
    await _connectionSubscription?.cancel();
    _scanSubscription = null;
    _connectionSubscription = null;
    if (device?.isConnected ?? false) {
      await device!.disconnect();
    }
    device = null;
  }
}
