enum VehicleCommand {
  lock,
  unlock,
  find,
  windowUp,
  windowDown,
  trunk,
}

extension VehicleCommandValue on VehicleCommand {
  String get protocol {
    switch (this) {
      case VehicleCommand.lock:
        return 'suoche';
      case VehicleCommand.unlock:
        return 'jiesuo';
      case VehicleCommand.find:
        return 'xunche';
      case VehicleCommand.windowUp:
        return 'chuangsheng';
      case VehicleCommand.windowDown:
        return 'chuangjiang';
      case VehicleCommand.trunk:
        return 'houbeixiang';
    }
  }
}
