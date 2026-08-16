import '../core/vehicle_protocol.dart';
import 'mock_esp32.dart';

/// High level vehicle control state machine.
/// Keeps UI independent from ESP32 transport details.
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
  VehicleController(this.device);

  final MockESP32 device;

  VehicleConnectionState state = VehicleConnectionState.disconnected;

  Future<void> scan() async {
    device.scanDevices();
    state = VehicleConnectionState.scanning;
  }

  Future<void> connect() async {
    device.connectBLE();
    state = VehicleConnectionState.connected;
  }

  Future<bool> authorize(String password) async {
    if (password.isEmpty) return false;
    final result = device.authenticateAdmin(password);
    if (result) {
      state = VehicleConnectionState.authorized;
    }
    return result;
  }

  Future<void> ready() async {
    if (state == VehicleConnectionState.authorized) {
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

    device.executeCommand(protocolCommand);
    state = VehicleConnectionState.ready;
  }
}
