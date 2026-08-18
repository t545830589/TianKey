/// BLE connection lifecycle model.
///
/// This keeps connection state separate from transport and protocol layers.
/// It intentionally does not contain device-specific UUIDs or commands.
enum BleConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class BleConnectionState {
  const BleConnectionState({
    required this.status,
    this.deviceId,
    this.message = '',
  });

  final BleConnectionStatus status;
  final String? deviceId;
  final String message;

  bool get isConnected => status == BleConnectionStatus.connected;

  BleConnectionState copyWith({
    BleConnectionStatus? status,
    String? deviceId,
    String? message,
  }) {
    return BleConnectionState(
      status: status ?? this.status,
      deviceId: deviceId ?? this.deviceId,
      message: message ?? this.message,
    );
  }
}
