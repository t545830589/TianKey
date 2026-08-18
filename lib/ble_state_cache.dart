/// BLE runtime state cache foundation.
///
/// This intentionally stores runtime state only and does not define any
/// vehicle protocol, UUID, or ESP32 command frames.
class BleStateCache {
  bool _connected = false;
  String? _deviceId;
  DateTime? _lastUpdated;

  bool get connected => _connected;

  String? get deviceId => _deviceId;

  DateTime? get lastUpdated => _lastUpdated;

  void updateConnection({required bool connected, String? deviceId}) {
    _connected = connected;
    _deviceId = deviceId ?? _deviceId;
    _lastUpdated = DateTime.now();
  }

  void clear() {
    _connected = false;
    _deviceId = null;
    _lastUpdated = DateTime.now();
  }
}
