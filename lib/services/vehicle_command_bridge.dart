import 'esp32_simulator.dart';

class VehicleCommandBridge {
  final Esp32Simulator esp32;

  VehicleCommandBridge(this.esp32);

  Future<String> sendLock() async {
    return esp32.executeCommand('LOCK');
  }

  Future<String> sendUnlock() async {
    return esp32.executeCommand('UNLOCK');
  }

  Future<String> sendTrunk() async {
    return esp32.executeCommand('TRUNK');
  }
}
