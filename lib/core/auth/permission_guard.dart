enum UserRole { admin, guest }

class PermissionGuard {
  UserRole role;

  PermissionGuard({this.role = UserRole.guest});

  bool canControlVehicle() {
    return role == UserRole.admin || role == UserRole.guest;
  }

  bool canManageSystem() {
    return role == UserRole.admin;
  }
}
