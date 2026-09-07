import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleScanItem {
  const BleScanItem({this.device, required this.name, required this.remoteId, this.rssi = 0});

  final BluetoothDevice? device;
  final String name;
  final String remoteId;
  final int rssi;
}

class TianKeyBleService {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final Map<String, BleScanItem> _found = <String, BleScanItem>{};
  BluetoothDevice? device;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<void>? _servicesResetSubscription;
  List<BluetoothService> _services = <BluetoothService>[];
  VoidCallback? onDisconnect;

  bool get isConnected => device?.isConnected ?? false;
  String? get connectedRemoteId => device?.remoteId.str;
  BluetoothDevice? get connectedDevice => device;
  List<BleScanItem> get foundDevices => _found.values.toList(growable: false);
  List<BluetoothService> get discoveredServices => List<BluetoothService>.unmodifiable(_services);

  List<String> get discoveredServiceUuids => List<String>.unmodifiable(
        _services.map((service) => service.serviceUuid.toString()),
      );

  List<String> get discoveredCharacteristicUuids => List<String>.unmodifiable(
        _services.expand(
          (service) => service.characteristics.map(
            (characteristic) => '${service.serviceUuid}/${characteristic.characteristicUuid}',
          ),
        ),
      );

  List<String> get discoveredGattInventory => List<String>.unmodifiable(<String>[
        ...discoveredServiceUuids.map((uuid) => 'service:$uuid'),
        ...discoveredCharacteristicUuids.map((uuid) => 'characteristic:$uuid'),
      ]);

  Future<bool> isSupported() async => FlutterBluePlus.isSupported;

  /// 真正停止当前BLE扫描，等待扫描彻底结束后再返回
  Future<void> stopCurrentScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    try { await FlutterBluePlus.stopScan(); } catch (_) {}
  }

  Future<List<BleScanItem>> scan({Duration timeout = const Duration(seconds: 6)}) async {
    _found.clear();
    // 确保旧扫描真正停止后再开始新扫描
    await stopCurrentScan();
    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        final name = result.advertisementData.advName.trim().isNotEmpty
            ? result.advertisementData.advName.trim()
            : result.device.platformName.trim();
        _found[result.device.remoteId.str] = BleScanItem(
          device: result.device,
          name: name.isEmpty ? '未命名 BLE 设备' : name,
          remoteId: result.device.remoteId.str,
          rssi: result.rssi,
        );
      }
    });
    try {
      await FlutterBluePlus.startScan(timeout: timeout);
      await FlutterBluePlus.isScanning.where((value) => value == false).first;
    } finally {
      await stopCurrentScan();
    }
    return foundDevices;
  }

  Future<List<BluetoothService>> discoverServices() async {
    final current = device;
    if (current == null || !current.isConnected) {
      _services = <BluetoothService>[];
      throw StateError('BLE设备未连接，无法发现服务');
    }
    final services = await current.discoverServices();
    _services = List<BluetoothService>.from(services);
    return discoveredServices;
  }

  Future<void> reconnectSavedRemoteId(String remoteId) async {
    final normalized = remoteId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(remoteId, 'remoteId', 'BLE remoteId不能为空');
    }
    await connect(BluetoothDevice.fromId(normalized));
  }

  Future<void> connect(BluetoothDevice target, {Duration timeout = const Duration(seconds: 10)}) async {
    await _connectionSubscription?.cancel();
    await _servicesResetSubscription?.cancel();
    // 确保旧扫描真正停止
    await stopCurrentScan();
    device = target;
    _services = <BluetoothService>[];

    _servicesResetSubscription = target.onServicesReset.listen((_) async {
      if (!target.isConnected) return;
      try {
        await discoverServices();
      } catch (_) {}
    });

    try {
      await target.connect(timeout: timeout);

      // 连接成功后才监听掉线，避免连接阶段的瞬断清空device
      _connectionSubscription = target.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          device = null;
          _services = <BluetoothService>[];
          onDisconnect?.call();
        }
      });

      for (int i = 0; i < 3; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!target.isConnected) throw StateError('BLE设备未连接');
        try {
          await discoverServices();
          break;
        } catch (e) {
          if (i == 2) rethrow;
        }
      }
    } catch (error) {
      try { await target.disconnect(); } catch (_) {}
      await _connectionSubscription?.cancel();
      await _servicesResetSubscription?.cancel();
      _connectionSubscription = null;
      _servicesResetSubscription = null;
      _services = <BluetoothService>[];
      device = null;
      rethrow;
    }
  }

  Future<void> disconnect() async {
    final current = device;
    device = null;
    _services = <BluetoothService>[];
    await _connectionSubscription?.cancel();
    await _servicesResetSubscription?.cancel();
    _connectionSubscription = null;
    _servicesResetSubscription = null;
    if (current != null && current.isConnected) {
      await current.disconnect();
    }
  }

  Future<void> dispose() async {
    await stopCurrentScan();
    await _connectionSubscription?.cancel();
    await _servicesResetSubscription?.cancel();
    _connectionSubscription = null;
    _servicesResetSubscription = null;
    if (device?.isConnected ?? false) {
      await device!.disconnect();
    }
    _services = <BluetoothService>[];
    device = null;
  }
}
