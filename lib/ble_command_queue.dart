import 'dart:async';

/// Protocol-independent BLE command queue.
///
/// This intentionally does not define TianKey device commands or UUIDs.
/// It only provides ordering and completion handling for the future layer
/// that will connect real characteristic writes and responses.
class BleCommandQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> enqueue<T>(Future<T> Function() operation) {
    final completer = Completer<T>();

    _tail = _tail.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
  }

  void clear() {
    _tail = Future<void>.value();
  }
}
