import 'mock_esp32.dart';

/// BLE abstraction layer.
///
/// This interface keeps the app independent from the ESP32 transport.
/// MockESP32 is used during development; production BLE implementation can
/// replace this service without changing UI logic.
class BleService {
  BleService(this.device);

  final MockESP32 device;

  bool get connected => device.isConnected();

  Future<List<String>> scanVehicles() async {
    return device.scanDevices();
  }

  Future<bool> connect(String deviceId) async {
    if (deviceId.isEmpty) {
      throw ArgumentError('deviceId is empty');
    }
    return device.connectBLE();
  }

  Future<bool> disconnect() async {
    return device.disconnectBLE();
  }
}
