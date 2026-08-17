enum BleConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  reconnecting,
}

class ConnectionManager {
  BleConnectionStatus status = BleConnectionStatus.disconnected;

  Future<void> scan() async {
    status = BleConnectionStatus.scanning;
  }

  Future<void> connect() async {
    status = BleConnectionStatus.connecting;
    status = BleConnectionStatus.connected;
  }

  Future<void> disconnect() async {
    status = BleConnectionStatus.disconnected;
  }

  Future<void> reconnect() async {
    status = BleConnectionStatus.reconnecting;
    await connect();
  }
}
