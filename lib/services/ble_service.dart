import 'mock_esp32.dart';

/// BLE abstraction layer.
///
/// UI and controller only communicate through this service. The ESP32
/// implementation can later be replaced without changing business logic.
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

  bool authenticateAdmin(String password) {
    return device.authenticateAdmin(password);
  }

  String executeCommand(String command) {
    return device.executeCommand(command);
  }

  List<String> getLogs() {
    return device.getLogs();
  }
}
