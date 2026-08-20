import '../models/vehicle_state.dart';

/// 车辆控制层
///
/// 逐步从 main.dart 接管车辆控制逻辑。
class VehicleController {
  final VehicleState state;

  VehicleController(this.state);

  void updateStatus(String value) {
    state.status = value;
  }

  void recordCommand(String value) {
    state.lastCommand = value;
  }

  void lockVehicle() {
    state.locked = true;
    state.lastCommand = '锁车';
    state.status = '车辆已锁定';
  }

  void unlockVehicle() {
    state.locked = false;
    state.lastCommand = '解锁';
    state.status = '车辆已解锁';
  }

  void findVehicle() {
    state.lastCommand = '寻车';
    state.status = '正在执行寻车';
  }

  void raiseWindow() {
    state.lastCommand = '升窗';
    state.status = '正在执行升窗';
  }

  void lowerWindow() {
    state.lastCommand = '降窗';
    state.status = '正在执行降窗';
  }

  void openTrunk() {
    state.lastCommand = '后备箱';
    state.status = '正在执行后备箱开启';
  }
}
