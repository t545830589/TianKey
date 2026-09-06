import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleCharacteristicGateway {
  StreamSubscription<List<int>>? _notifySubscription;
  StreamController<List<int>>? _notifyController;

  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;

  bool get readyForWrite => _writeCharacteristic != null;
  bool get readyForNotify => _notifyCharacteristic != null;

  // 串行命令队列：防止多个sendAndWait同时监听导致响应串线
  final List<_PendingCommand> _queue = [];
  bool _processing = false;
  _PendingCommand? _activeCommand;

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
    await characteristic.write(data, withoutResponse: withoutResponse);
  }

  Future<String?> sendAndWait(List<int> data, {Duration timeout = const Duration(seconds: 2), String? expectPrefix}) async {
    final characteristic = _writeCharacteristic;
    if (characteristic == null) {
      throw StateError('未绑定可写 characteristic');
    }

    final completer = Completer<String?>();
    final cmd = _PendingCommand(data: data, completer: completer, expectPrefix: expectPrefix, timeout: timeout);
    _queue.add(cmd);
    _processQueue();
    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_processing) return;
    _processing = true;

    try {
      while (_queue.isNotEmpty) {
        final cmd = _queue.removeAt(0);
        await _executeCommand(cmd);
      }
    } finally {
      _processing = false;
    }
  }

  Future<void> _executeCommand(_PendingCommand cmd) async {
    _activeCommand = cmd;
    StreamSubscription<List<int>>? sub;

    try {
      final characteristic = _writeCharacteristic;
      if (characteristic == null) {
        if (!cmd.completer.isCompleted) cmd.completer.complete(null);
        return;
      }

      // 为当前命令创建listener — 按expectPrefix过滤，ERR始终放行
      sub = _notifyController?.stream.listen((value) {
        if (cmd.completer.isCompleted) return;
        final msg = String.fromCharCodes(value);

        // ERR始终放行，不管expectPrefix是什么
        if (msg.startsWith('ERR') || msg.startsWith('err')) {
          cmd.completer.complete(msg);
          return;
        }

        // 无expectPrefix：收到任何非ERR回复即匹配
        if (cmd.expectPrefix == null || cmd.expectPrefix!.isEmpty) {
          cmd.completer.complete(msg);
          return;
        }

        // 有expectPrefix：回复必须以该prefix开头
        if (msg.startsWith(cmd.expectPrefix!)) {
          cmd.completer.complete(msg);
        }
        // 不匹配则忽略，继续等待
      });

      await characteristic.write(cmd.data, withoutResponse: true);

      // 等待响应或超时
      try {
        await cmd.completer.future.timeout(cmd.timeout, onTimeout: () {
          if (!cmd.completer.isCompleted) cmd.completer.complete(null);
          return null;
        });
      } catch (_) {
        if (!cmd.completer.isCompleted) cmd.completer.complete(null);
      }
    } catch (_) {
      if (!cmd.completer.isCompleted) cmd.completer.complete(null);
    } finally {
      await sub?.cancel();
      _activeCommand = null;
    }
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
    // 完成未执行的队列命令
    for (final cmd in _queue) {
      if (!cmd.completer.isCompleted) cmd.completer.complete(null);
    }
    _queue.clear();

    // 完成正在执行的命令
    final active = _activeCommand;
    if (active != null && !active.completer.isCompleted) {
      active.completer.complete(null);
    }
    _activeCommand = null;
    _processing = false;

    await _notifySubscription?.cancel();
    await _notifyController?.close();
    _notifySubscription = null;
    _notifyController = null;
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
  }
}

class _PendingCommand {
  final List<int> data;
  final Completer<String?> completer;
  final String? expectPrefix;
  final Duration timeout;

  _PendingCommand({
    required this.data,
    required this.completer,
    this.expectPrefix,
    required this.timeout,
  });
}
