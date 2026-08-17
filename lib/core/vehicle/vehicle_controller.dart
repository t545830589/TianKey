import 'dart:async';

import 'vehicle_state.dart';
import 'vehicle_service_bridge.dart';

/// TianKey V11 vehicle control orchestration layer.
class VehicleController {
  final VehicleServiceBridge bridge;

  VehicleState state = VehicleState();
  final StreamController<VehicleState> _stateEvents = StreamController.broadcast();

  VehicleController(this.bridge);

  Stream<VehicleState> get stateEvents => _stateEvents.stream;

  Future<String> execute(String command) async {
    final result = await bridge.execute(command);

    if (command == 'LOCK') {
      state.locked = true;
    }
    if (command == 'UNLOCK') {
      state.locked = false;
    }

    _stateEvents.add(state);
    return result;
  }

  void dispose() {
    _stateEvents.close();
  }
}
