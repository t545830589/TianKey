class VehicleState {
  bool locked;
  bool doorsClosed;
  bool windowsClosed;
  int battery;

  VehicleState({
    this.locked = true,
    this.doorsClosed = true,
    this.windowsClosed = true,
    this.battery = 100,
  });

  Map<String, dynamic> toJson() => {
        'locked': locked,
        'doorsClosed': doorsClosed,
        'windowsClosed': windowsClosed,
        'battery': battery,
      };
}
