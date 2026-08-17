enum UserRole {
  admin,
  guest,
}

class SessionManager {
  UserRole role = UserRole.guest;
  bool authenticated = false;

  void login(UserRole userRole) {
    role = userRole;
    authenticated = true;
  }

  void logout() {
    authenticated = false;
    role = UserRole.guest;
  }

  bool canControlVehicle() {
    return authenticated;
  }
}
