/// TianKey V11 permission simulation layer.
class AuthManager {
  static const String initialAdminPassword = '13092991951';

  String role = 'GUEST';
  bool authenticated = false;

  bool loginAdmin(String password) {
    if (password == initialAdminPassword) {
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
