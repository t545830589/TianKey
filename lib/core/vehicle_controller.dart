import '../services/mock_esp32.dart';
import 'vehicle_protocol.dart';
import 'vehicle_state.dart';

class VehicleController {
  final MockESP32 transport;

  VehicleController(this.transport);

  VehicleState get state => VehicleState(
        connected: transport.isConnected(),
        authorized: transport.authenticated,
        userRole: transport.sessionRole,
      );

  String send(String command) {
    return transport.executeCommand(command);
  }

  String lock() => send(VehicleProtocol.lock);
  String unlock() => send(VehicleProtocol.unlock);
  String findCar() => send(VehicleProtocol.findCar);
  String windowUp() => send(VehicleProtocol.windowUp);
  String windowDown() => send(VehicleProtocol.windowDown);
  String trunk() => send(VehicleProtocol.trunk);
}
