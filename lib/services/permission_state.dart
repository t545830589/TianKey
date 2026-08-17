enum TianKeyPermission {
  none,
  guest,
  admin,
}

class PermissionState {
  TianKeyPermission current = TianKeyPermission.none;

  bool get canControlVehicle {
    return current == TianKeyPermission.admin ||
        current == TianKeyPermission.guest;
  }
}
