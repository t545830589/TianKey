import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleScanItem {
  const BleScanItem({this.device, required this.name, required this.remoteId});

  final BluetoothDevice? device;
  final String name;
  final String remoteId;
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
  List<BleScanItem> get foundDevices => _found.values.toList(growable: false);
  List<BluetoothService> get discoveredServices => List<BluetoothService>.unmodifiable(_services);

  /// UUID-only inventory of the GATT services actually returned by the
  /// connected peripheral. This is diagnostic data only: no service UUID is
  /// treated as a TianKey protocol UUID here.
  List<String> get discoveredServiceUuids => List<String>.unmodifiable(
        _services.map((service) => service.serviceUuid.toString()),
      );

  /// UUID-only inventory of characteristics actually returned by the
  /// peripheral, grouped as `serviceUuid/characteristicUuid` strings.
  /// This deliberately does not assign protocol meanings to any UUID.
  List<String> get discoveredCharacteristicUuids => List<String>.unmodifiable(
        _services.expand(
          (service) => service.characteristics.map(
            (characteristic) => '${service.serviceUuid}/${characteristic.characteristicUuid}',
          ),
        ),
      );

  /// Stable, human-readable diagnostic snapshot for protocol integration.
  /// The returned values come only from FlutterBluePlus discovery results.
  List<String> get discoveredGattInventory => List<String>.unmodifiable(<String>[
        ...discoveredServiceUuids.map((uuid) => 'service:$uuid'),
        ...discoveredCharacteristicUuids.map((uuid) => 'characteristic:$uuid'),
      ]);

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

  Future<List<BluetoothService>> discoverServices() async {
    final current = device;
    if (current == null || !current.isConnected) {
      _services = <BluetoothService>[];
      throw StateError('BLE设备未连接，无法发现服务');
    }
    final services = await current.discoverServices().timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw StateError('服务发现超时，请重试'),
    );
    _services = List<BluetoothService>.from(services);
    return discoveredServices;
  }

  /// Reconnect using the exact platform remoteId previously persisted by the
  /// app. This does not scan, guess a device name, or invent a protocol UUID.
  Future<void> reconnectSavedRemoteId(String remoteId) async {
    final normalized = remoteId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(remoteId, 'remoteId', 'BLE remoteId不能为空');
    }
    await connect(BluetoothDevice.fromId(normalized));
  }

  Future<void> connect(BluetoothDevice target, {Duration timeout = const Duration(seconds: 3)}) async {
    await _connectionSubscription?.cancel();
    await _servicesResetSubscription?.cancel();
    device = target;
    _services = <BluetoothService>[];

    _connectionSubscription = target.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        device = null;
        _services = <BluetoothService>[];
        onDisconnect?.call();
      }
    });

    // FlutterBluePlus clears the discovered GATT service cache when the
    // peripheral reports a Services Changed event. Re-discover immediately
    // so the real connection remains ready for the future protocol layer.
    // No service/characteristic UUID is invented here.
    _servicesResetSubscription = target.onServicesReset.listen((_) async {
      if (!target.isConnected) return;
      try {
        await discoverServices();
      } catch (_) {
        // The app-level connection state remains authoritative; the next
        // operation can retry discovery after the peripheral is stable.
      }
    });

    try {
      await target.connect(timeout: timeout, autoConnect: false);
      // 等待ESP32 GATT服务就绪
      for (int i = 0; i < 2; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!target.isConnected) throw StateError('BLE设备未连接');
        try {
          await discoverServices();
          break;
        } catch (e) {
          if (i == 1) rethrow;
        }
      }
    } catch (error) {
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
    await _scanSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _servicesResetSubscription?.cancel();
    _scanSubscription = null;
    _connectionSubscription = null;
    _servicesResetSubscription = null;
    if (device?.isConnected ?? false) {
      await device!.disconnect();
    }
    _services = <BluetoothService>[];
    device = null;
  }
}
