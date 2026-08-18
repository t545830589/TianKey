class BleStateSnapshot {
  final bool connected;
  final String deviceId;
  final DateTime updatedAt;

  const BleStateSnapshot({
    required this.connected,
    required this.deviceId,
    required this.updatedAt,
  });
}

/// Lightweight state synchronization layer.
/// Real device values should come from the actual BLE protocol implementation.
class BleStateSync {
  BleStateSnapshot? _snapshot;

  BleStateSnapshot? get snapshot => _snapshot;

  void update(BleStateSnapshot snapshot) {
    _snapshot = snapshot;
  }

  void clear() {
    _snapshot = null;
  }
}
