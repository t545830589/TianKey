class ControlGuard {
  bool canControl({required bool connected, required String role}) {
    if (!connected) return false;
    return role == 'ADMIN' || role == 'GUEST';
  }

  String denyReason({required bool connected, required String role}) {
    if (!connected) return 'DEVICE_NOT_CONNECTED';
    if (role == 'NONE') return 'AUTH_REQUIRED';
    return 'UNKNOWN';
  }
}
