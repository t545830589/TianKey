import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Real GATT characteristic gateway.
///
/// No TianKey protocol UUID or vehicle command is assumed here.
/// Characteristics must come from actual discovery results.
class BleCharacteristicGateway {
  StreamSubscription<List<int>>? _notifySubscription;
  StreamController<List<int>>? _notifyController;

  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;

  bool get readyForWrite => _writeCharacteristic != null;
  bool get readyForNotify => _notifyCharacteristic != null;

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

  Future<String?> sendAndWait(List<int> data, {Duration timeout = const Duration(seconds: 2), String? expectPrefix}) async {
    final characteristic = _writeCharacteristic;
    if (characteristic == null) {
      throw StateError('未绑定可写 characteristic');
    }

    final completer = Completer<String?>();
    final sub = _notifyController?.stream.listen((value) {
      if (completer.isCompleted) return;
      final msg = String.fromCharCodes(value);
      if (msg.startsWith('!TIMEREQ')) return;
      if (expectPrefix != null && !msg.startsWith(expectPrefix)) return;
      completer.complete(msg);
    });

    await characteristic.write(data, withoutResponse: true);

    final result = await completer.future.timeout(timeout, onTimeout: () {
      return null;
    });

    sub?.cancel();
    return result;
  }

  Future<Stream<List<int>>> startNotify() async {
    final characteristic = _notifyCharacteristic;
    if (characteristic == null) {
      throw StateError('未绑定 notify characteristic');
    }

    await _notifySubscription?.cancel();
    await characteristic.setNotifyValue(true);

    _notifyController ??= StreamController<List<int>>.broadcast();
    _notifySubscription = characteristic.onValueReceived.listen(
      (value) => _notifyController?.add(List<int>.from(value)),
      onError: _notifyController?.addError,
    );

    return _notifyController!.stream;
  }

  Future<void> dispose() async {
    await _notifySubscription?.cancel();
    await _notifyController?.close();
    _notifySubscription = null;
    _notifyController = null;
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
  }
}
