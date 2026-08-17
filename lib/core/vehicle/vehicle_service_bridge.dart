import '../esp32/esp32_simulator.dart';
import '../log/log_manager.dart';

class VehicleServiceBridge {
  final Esp32Simulator esp32;
  final LogManager logManager;

  VehicleServiceBridge({
    required this.esp32,
    required this.logManager,
  });

  Future<String> execute(String command) async {
    final result = await esp32.executeCommand(command);
    logManager.add('VEHICLE:$command:$result');
    return result;
  }
}
