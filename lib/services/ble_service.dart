/// BLE abstraction layer.
///
/// This interface keeps the app independent from the ESP32 transport.
/// MockESP32 is used during development; production BLE implementation can
/// replace this service without changing UI logic.
class BleService {
  bool _connected = false;

  bool get connected => _connected;

  Future<List<String>> scanVehicles() async {
    return ['陕A0P92Y'];
  }

  Future<void> connect(String deviceId) async {
    if (deviceId.isEmpty) {
      throw ArgumentError('deviceId is empty');
    }
    _connected = true;
  }

  Future<void> disconnect() async {
    _connected = false;
  }
}
