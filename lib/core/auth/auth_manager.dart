/// TianKey V11 permission simulation layer.
/// Provides basic role state before backend/ESP32 authorization is connected.
class AuthManager {
  String role = 'GUEST';
  bool authenticated = false;

  bool loginAdmin(String password) {
    if (password == '123456') {
      role = 'ADMIN';
      authenticated = true;
      return true;
    }
    return false;
  }

  void logout() {
    role = 'GUEST';
    authenticated = false;
  }
}
