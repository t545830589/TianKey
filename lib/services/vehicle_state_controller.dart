import 'esp32_simulator.dart';
import 'vehicle_command_bridge.dart';

/// V11 vehicle runtime controller.
/// Connects HUD actions with ESP32 simulation without changing UI structure.
class VehicleStateController {
  final Esp32Simulator esp32;
  late final VehicleCommandBridge bridge;

  bool locked = true;
  String lastCommand = '';
  String lastMessage = '';

  VehicleStateController(this.esp32) {
    bridge = VehicleCommandBridge(esp32);
  }

  Future<Esp32Response> lock() async {
    final result = await bridge.sendLock();
    _update('LOCK', result);
    return result;
  }

  Future<Esp32Response> unlock() async {
    final result = await bridge.sendUnlock();
    _update('UNLOCK', result);
    return result;
  }

  Future<Esp32Response> trunk() async {
    final result = await bridge.sendTrunk();
    _update('TRUNK', result);
    return result;
  }

  void _update(String command, Esp32Response response) {
    lastCommand = command;
    lastMessage = response.message;
    if (command == 'LOCK' && response.success) locked = true;
    if (command == 'UNLOCK' && response.success) locked = false;
  }
}
