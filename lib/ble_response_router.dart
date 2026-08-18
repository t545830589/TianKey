import 'ble_protocol_layer.dart';

/// Routes BLE protocol responses back to higher layers.
///
/// This layer intentionally does not decode vehicle-specific frames because
/// real hardware protocol details are not available yet.
class BleResponseRouter {
  BleProtocolResponse? _lastResponse;

  BleProtocolResponse? get lastResponse => _lastResponse;

  void accept(BleProtocolResponse response) {
    _lastResponse = response;
  }

  BleProtocolResult validateLastResponse() {
    final response = _lastResponse;
    if (response == null) {
      return const BleProtocolResult(
        success: false,
        message: 'no BLE response available',
      );
    }

    return BleProtocolResult(success: true);
  }

  void clear() {
    _lastResponse = null;
  }
}
