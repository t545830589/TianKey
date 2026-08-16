class VehicleState {
  const VehicleState({
    this.connected = false,
    this.authorized = false,
    this.locked = false,
    this.battery = 0,
    this.lastAction = '',
    this.updatedAt,
  });

  final bool connected;
  final bool authorized;
  final bool locked;
  final int battery;
  final String lastAction;
  final DateTime? updatedAt;

  VehicleState copyWith({
    bool? connected,
    bool? authorized,
    bool? locked,
    int? battery,
    String? lastAction,
    DateTime? updatedAt,
  }) {
    return VehicleState(
      connected: connected ?? this.connected,
      authorized: authorized ?? this.authorized,
      locked: locked ?? this.locked,
      battery: battery ?? this.battery,
      lastAction: lastAction ?? this.lastAction,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
