import 'esp32_simulator.dart';

class VehicleCommandBridge {
  final Esp32Simulator esp32;

  VehicleCommandBridge(this.esp32);

  Future<Esp32Response> sendLock() async {
    return esp32.execute('LOCK');
  }

  Future<Esp32Response> sendUnlock() async {
    return esp32.execute('UNLOCK');
  }

  Future<Esp32Response> sendTrunk() async {
    return esp32.execute('TRUNK');
  }
}
