import 'vehicle_status_provider.dart';

class HudStateBinding {
  final VehicleStatusProvider status;

  HudStateBinding(this.status);

  Map<String, dynamic> snapshot() {
    return {
      'connected': status.connected,
      'role': status.role,
      'vehicleLocked': status.locked,
      'lastAction': status.lastAction,
    };
  }
}
