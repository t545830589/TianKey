import 'mock_esp32.dart';

/// High level vehicle control state machine.
/// Keeps UI independent from real ESP32 BLE implementation.
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

    switch (command) {
      case VehicleCommand.lock:
        device.executeCommand('LOCK');
      case VehicleCommand.unlock:
        device.executeCommand('UNLOCK');
      case VehicleCommand.findCar:
        device.executeCommand('FIND');
      case VehicleCommand.windowUp:
        device.executeCommand('WINDOW_UP');
      case VehicleCommand.windowDown:
        device.executeCommand('WINDOW_DOWN');
      case VehicleCommand.trunk:
        device.executeCommand('TRUNK');
    }

    state = VehicleConnectionState.ready;
  }
}
