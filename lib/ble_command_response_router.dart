import 'ble_protocol_layer.dart';

/// Routes BLE command responses between protocol and application layers.
///
/// This layer intentionally does not define hardware-specific commands or
/// TianKey/ESP32 frames. Real command mapping should be added only after the
/// hardware protocol specification is available.
class BleCommandResponseRouter {
  BleProtocolResponse? _lastResponse;

  BleProtocolResponse? get lastResponse => _lastResponse;

  BleProtocolResult handleResponse(BleProtocolResponse response) {
    final result = TianKeyBleProtocolLayer().validatePacket(response.packet);
    if (!result.success) {
      return result;
    }

    _lastResponse = response;
    return const BleProtocolResult(success: true);
  }

  void clear() {
    _lastResponse = null;
  }
}
