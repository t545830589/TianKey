import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleCharacteristicGateway {
  StreamSubscription<List<int>>? _notifySubscription;
  StreamController<List<int>>? _notifyController;

  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;

  bool get readyForWrite => _writeCharacteristic != null;
  bool get readyForNotify => _notifyCharacteristic != null;

  // 串行命令队列
  final List<_PendingCommand> _queue = [];
  bool _processing = false;
  _PendingCommand? _activeCommand;
  // 跟当前processor的Future，dispose时等它退出
  Future<void>? _processorFuture;
  // generation计数：每次新processor启动时+1，旧processor检查此值判断自己是否过期
  int _generation = 0;

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

  Future<String?> sendAndWait(
    List<int> data, {
    Duration timeout = const Duration(seconds: 2),
    String? expectPrefix,
    bool Function(String reply)? replyMatcher,
  }) async {
    final characteristic = _writeCharacteristic;
    if (characteristic == null) {
      throw StateError('未绑定可写 characteristic');
    }

    final completer = Completer<String?>();
    final cmd = _PendingCommand(
      data: data,
      completer: completer,
      expectPrefix: expectPrefix,
      replyMatcher: replyMatcher,
      timeout: timeout,
    );
    _queue.add(cmd);
    _processQueue();
    return completer.future;
  }

  void _processQueue() {
    if (_processing) return;
    _processing = true;
    _generation++;
    _processorFuture = _processorLoop(_generation);
  }

  Future<void> _processorLoop(int myGeneration) async {
    try {
      while (_queue.isNotEmpty) {
        // 如果自己已经过期（新processor已启动），停止处理
        if (myGeneration != _generation) break;
        final cmd = _queue.removeAt(0);
        await _executeCommand(cmd, myGeneration);
      }
    } finally {
      // 只有自己还是当前generation时才清理状态
      if (myGeneration == _generation) {
        _processing = false;
        _activeCommand = null;
      }
    }
  }

  Future<void> _executeCommand(_PendingCommand cmd, int myGeneration) async {
    _activeCommand = cmd;
    StreamSubscription<List<int>>? sub;

    try {
      final characteristic = _writeCharacteristic;
      if (characteristic == null) {
        if (!cmd.completer.isCompleted) cmd.completer.complete(null);
        return;
      }

      sub = _notifyController?.stream.listen((value) {
        if (cmd.completer.isCompleted) return;
        // 如果自己已过期，忽略所有notify
        if (myGeneration != _generation) return;
        final msg = String.fromCharCodes(value);

        // ERR始终放行
        if (msg.startsWith('ERR') || msg.startsWith('err')) {
          cmd.completer.complete(msg);
          return;
        }

        // 优先使用replyMatcher精确匹配
        if (cmd.replyMatcher != null) {
          if (cmd.replyMatcher!(msg)) {
            cmd.completer.complete(msg);
          }
          return;
        }

        // 回退到expectPrefix匹配
        if (cmd.expectPrefix == null || cmd.expectPrefix!.isEmpty) {
          cmd.completer.complete(msg);
          return;
        }

        if (msg.startsWith(cmd.expectPrefix!)) {
          cmd.completer.complete(msg);
        }
      });

      await characteristic.write(cmd.data, withoutResponse: true);

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
    // 1. 完成未执行的队列命令
    for (final cmd in _queue) {
      if (!cmd.completer.isCompleted) cmd.completer.complete(null);
    }
    _queue.clear();

    // 2. 完成正在执行的active command
    final active = _activeCommand;
    if (active != null && !active.completer.isCompleted) {
      active.completer.complete(null);
    }

    // 3. 递增generation使旧processor过期
    _generation++;

    // 4. 等待旧processor真正退出
    final processor = _processorFuture;
    if (processor != null) {
      try { await processor.timeout(const Duration(seconds: 3)); } catch (_) {}
    }
    _processorFuture = null;
    _processing = false;
    _activeCommand = null;

    // 5. 清理notify/characteristic
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
  final bool Function(String reply)? replyMatcher;
  final Duration timeout;

  _PendingCommand({
    required this.data,
    required this.completer,
    this.expectPrefix,
    this.replyMatcher,
    required this.timeout,
  });
}
