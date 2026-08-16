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
    state = VehicleConnectionState.scanning;
  }

  Future<void> connect() async {
    state = VehicleConnectionState.connected;
  }

  Future<bool> authorize(String password) async {
    if (password.isEmpty) return false;
    state = VehicleConnectionState.authorized;
    return true;
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
        await device.lock();
      case VehicleCommand.unlock:
        await device.unlock();
      case VehicleCommand.findCar:
        await device.findCar();
      case VehicleCommand.windowUp:
        await device.windowUp();
      case VehicleCommand.windowDown:
        await device.windowDown();
      case VehicleCommand.trunk:
        await device.trunk();
    }

    state = VehicleConnectionState.ready;
  }
}
