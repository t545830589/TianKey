class VehicleState {
  bool connected;
  bool locked;
  bool authorized;
  bool timeSynced;
  String status;
  String lastCommand;

  VehicleState({
    this.connected = false,
    this.locked = true,
    this.authorized = true,
    this.timeSynced = false,
    this.status = '系统待机',
    this.lastCommand = '',
  });
}
