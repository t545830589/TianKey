import '../core/vehicle_protocol.dart';
import '../models/vehicle_state.dart';
import 'ble_service.dart';

enum VehicleConnectionState {
  disconnected,
  scanning,
  connected,
  authorized,
  ready,
  executing,
}

enum VehicleCommand {
  lock,
  unlock,
  findCar,
  windowUp,
  windowDown,
  trunk,
}

class VehicleController {
  VehicleController(this.transport);

  final BleService transport;
  List<String> vehicles = <String>[];
  VehicleConnectionState state = VehicleConnectionState.disconnected;
  VehicleState vehicleState = const VehicleState();

  Future<void> scan() async {
    vehicles = await transport.scanVehicles();
    state = VehicleConnectionState.scanning;
  }

  Future<bool> connect(String deviceId) async {
    final result = await transport.connect(deviceId);
    if (result) {
      state = VehicleConnectionState.connected;
      vehicleState = vehicleState.copyWith(
        connected: true,
        updatedAt: DateTime.now(),
      );
    }
    return result;
  }

  Future<bool> authorize(String password) async {
    if (password.isEmpty) return false;
    final result = transport.device.authenticateAdmin(password);
    if (result) {
      state = VehicleConnectionState.authorized;
      vehicleState = vehicleState.copyWith(
        authorized: true,
        updatedAt: DateTime.now(),
      );
    }
    return result;
  }

  Future<void> ready() async {
    if (state == VehicleConnectionState.authorized ||
        state == VehicleConnectionState.connected) {
      state = VehicleConnectionState.ready;
    }
  }

  Future<void> execute(VehicleCommand command) async {
    if (state != VehicleConnectionState.ready) {
      throw StateError('Vehicle is not ready');
    }

    state = VehicleConnectionState.executing;
    final protocolCommand = switch (command) {
      VehicleCommand.lock => VehicleProtocol.lock,
      VehicleCommand.unlock => VehicleProtocol.unlock,
      VehicleCommand.findCar => VehicleProtocol.findCar,
      VehicleCommand.windowUp => VehicleProtocol.windowUp,
      VehicleCommand.windowDown => VehicleProtocol.windowDown,
      VehicleCommand.trunk => VehicleProtocol.trunk,
    };

    transport.device.executeCommand(protocolCommand);
    vehicleState = vehicleState.copyWith(
      locked: command == VehicleCommand.lock
          ? true
          : command == VehicleCommand.unlock
              ? false
              : vehicleState.locked,
      lastAction: protocolCommand,
      updatedAt: DateTime.now(),
    );
    state = VehicleConnectionState.ready;
  }
}
