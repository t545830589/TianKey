class VehicleStatusProvider {
  bool connected = false;
  String role = 'NONE';
  bool locked = true;
  String battery = '100%';
  String lastAction = 'IDLE';

  void updateConnection(bool value) {
    connected = value;
  }

  void updateRole(String value) {
    role = value;
  }

  void updateLock(bool value) {
    locked = value;
    lastAction = value ? 'LOCK' : 'UNLOCK';
  }

  Map<String, String> snapshot() {
    return {
      'connection': connected ? 'CONNECTED' : 'DISCONNECTED',
      'role': role,
      'lock': locked ? 'LOCKED' : 'UNLOCKED',
      'battery': battery,
      'action': lastAction,
    };
  }
}
