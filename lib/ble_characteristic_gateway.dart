import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Real GATT characteristic gateway.
///
/// This layer intentionally does not assume any TianKey/vehicle UUID.
/// The caller must provide the characteristic discovered from the real device.
class BleCharacteristicGateway {
  StreamSubscription<List<int>>? _notifySubscription;

  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;

  bool get ready => _writeCharacteristic != null;

  void bind({
    required BluetoothCharacteristic writeCharacteristic,
    BluetoothCharacteristic? notifyCharacteristic,
  }) {
    _writeCharacteristic = writeCharacteristic;
    _notifyCharacteristic = notifyCharacteristic;
  }

  Future<void> writeCommand(List<int> data, {bool withoutResponse = false}) async {
    final characteristic = _writeCharacteristic;
    if (characteristic == null) {
      throw StateError('未绑定可写 characteristic');
    }

    await characteristic.write(
      data,
      withoutResponse: withoutResponse,
    );
  }

  Stream<List<int>> subscribeNotify() async* {
    final characteristic = _notifyCharacteristic;
    if (characteristic == null) {
      throw StateError('未绑定 notify characteristic');
    }

    await characteristic.setNotifyValue(true);
    await _notifySubscription?.cancel();

    final controller = StreamController<List<int>>();
    _notifySubscription = characteristic.lastValueStream.listen(
      controller.add,
      onError: controller.addError,
    );

    yield* controller.stream;
  }

  Future<void> dispose() async {
    await _notifySubscription?.cancel();
    _notifySubscription = null;
  }
}
