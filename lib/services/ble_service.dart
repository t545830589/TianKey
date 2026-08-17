/// V11 BLE simulation service.
///
/// Simulates the communication layer between the APK and ESP32.
class BleService {
  bool connected = false;
  String deviceName = '';

  Future<List<String>> scan() async {
    return ['TianKey-ESP32-V11'];
  }

  Future<bool> connect(String device) async {
    deviceName = device;
    connected = true;
    return connected;
  }

  Future<void> disconnect() async {
    connected = false;
    deviceName = '';
  }

  String get status => connected ? 'CONNECTED' : 'DISCONNECTED';
}
