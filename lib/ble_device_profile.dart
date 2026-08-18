import 'dart:typed_data';

/// Describes a discovered BLE device without assuming hardware-specific UUIDs.
/// Real service mappings can be attached after the target hardware protocol is confirmed.
class BleDeviceProfile {
  BleDeviceProfile({required this.deviceId, this.name = ''});

  final String deviceId;
  final String name;

  final Map<String, BleServiceProfile> services = {};

  void addService(BleServiceProfile service) {
    services[service.uuid] = service;
  }
}

class BleServiceProfile {
  BleServiceProfile({required this.uuid});

  final String uuid;
  final Map<String, BleCharacteristicProfile> characteristics = {};

  void addCharacteristic(BleCharacteristicProfile characteristic) {
    characteristics[characteristic.uuid] = characteristic;
  }
}

class BleCharacteristicProfile {
  BleCharacteristicProfile({
    required this.uuid,
    this.canRead = false,
    this.canWrite = false,
    this.canNotify = false,
  });

  final String uuid;
  final bool canRead;
  final bool canWrite;
  final bool canNotify;
}

class BleStateCache {
  String? connectedDeviceId;
  bool connected = false;
  Uint8List? lastReceivedPacket;

  void updateConnection(String? deviceId) {
    connectedDeviceId = deviceId;
    connected = deviceId != null;
  }
}
