class MockVehicle {
  int battery = 86;
  bool doorOpen = false;
  bool locked = true;
  double temperature = 26.0;
  bool windowMoving = false;
  bool trunkMoving = false;
  DateTime? lastActionAt;
  String lastHardwareTrace = '无';

  String getBattery() => '$battery%';
  String getDoorStatus() => doorOpen ? '开启' : '关闭';
  String getLockStatus() => locked ? '已锁' : '未锁';
  String getTemperature() => '$temperature℃';

  void openDoor() => doorOpen = true;
  void closeDoor() => doorOpen = false;
  void lockCar() => locked = true;
  void unlockCar() => locked = false;

  String lock() {
    locked = true;
    lastActionAt = DateTime.now();
    lastHardwareTrace = 'suoche → GPIO12 高电平脉冲';
    return lastHardwareTrace;
  }

  String unlock() {
    locked = false;
    lastActionAt = DateTime.now();
    lastHardwareTrace = 'jiesuo → GPIO13 高电平脉冲';
    return lastHardwareTrace;
  }

  String search() {
    lastActionAt = DateTime.now();
    lastHardwareTrace = 'xunche → GPIO12 连续两次锁车脉冲';
    return lastHardwareTrace;
  }

  Future<String> raiseWindow() async {
    windowMoving = true;
    lastHardwareTrace = 'chuangsheng → GPIO12 持续7秒';
    await Future<void>.delayed(const Duration(seconds: 7));
    windowMoving = false;
    lastActionAt = DateTime.now();
    return lastHardwareTrace;
  }

  Future<String> lowerWindow() async {
    windowMoving = true;
    lastHardwareTrace = 'chuangjiang → GPIO13 持续7秒';
    await Future<void>.delayed(const Duration(seconds: 7));
    windowMoving = false;
    lastActionAt = DateTime.now();
    return lastHardwareTrace;
  }

  Future<String> openTrunk() async {
    trunkMoving = true;
    doorOpen = true;
    lastHardwareTrace = 'houbeixiang → GPIO14 持续7秒';
    await Future<void>.delayed(const Duration(seconds: 7));
    trunkMoving = false;
    lastActionAt = DateTime.now();
    return lastHardwareTrace;
  }

  void factoryReset() {
    battery = 86;
    doorOpen = false;
    locked = true;
    temperature = 26.0;
    windowMoving = false;
    trunkMoving = false;
    lastActionAt = null;
    lastHardwareTrace = '无';
  }
}
