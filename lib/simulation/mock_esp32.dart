/// Tian Key Mock ESP32 foundation.
///
/// This layer keeps vehicle logic separate from Flutter pages so the BLE
/// transport can later switch between simulation and a real ESP32 protocol.
class MockEsp32 {
  bool authenticated = false;
  bool timeSynced = false;
  bool locked = true;

  bool verifyAdminPassword(String input, String password) {
    authenticated = input == password;
    return authenticated;
  }

  bool syncTime() {
    timeSynced = true;
    return true;
  }

  String executeCommand(String command) {
    if (!authenticated) return 'AUTH_REQUIRED';
    switch (command) {
      case 'suoche':
        locked = true;
        return 'LOCK_OK';
      case 'jiesuo':
        locked = false;
        return 'UNLOCK_OK';
      default:
        return 'UNKNOWN_COMMAND';
    }
  }
}
