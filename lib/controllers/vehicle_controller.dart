import '../models/vehicle_state.dart';

/// 车辆控制层
///
/// 用于逐步从 main.dart 迁移车辆控制逻辑。
/// 当前阶段只建立职责边界，不改变原有运行流程。
class VehicleController {
  final VehicleState state;

  VehicleController(this.state);

  void updateStatus(String value) {
    state.status = value;
  }

  void recordCommand(String value) {
    state.lastCommand = value;
  }
}
