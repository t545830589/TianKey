class VehicleState {
  final bool connected;
  final bool authorized;
  final String userRole;
  final String vehicleName;

  const VehicleState({
    this.connected = false,
    this.authorized = false,
    this.userRole = '无',
    this.vehicleName = '陕A0P92Y',
  });

  VehicleState copyWith({
    bool? connected,
    bool? authorized,
    String? userRole,
    String? vehicleName,
  }) {
    return VehicleState(
      connected: connected ?? this.connected,
      authorized: authorized ?? this.authorized,
      userRole: userRole ?? this.userRole,
      vehicleName: vehicleName ?? this.vehicleName,
    );
  }
}
