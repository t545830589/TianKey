enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  reconnecting,
}

class BleConnectionManager {
  BleConnectionState state = BleConnectionState.disconnected;
  String vehicleName = '';

  void scan() {
    state = BleConnectionState.scanning;
  }

  void connect(String vehicle) {
    vehicleName = vehicle;
    state = BleConnectionState.connected;
  }

  void disconnect() {
    state = BleConnectionState.disconnected;
  }

  void reconnect() {
    state = BleConnectionState.reconnecting;
  }
}
