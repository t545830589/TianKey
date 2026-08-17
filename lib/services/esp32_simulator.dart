/// TianKey V11 ESP32 simulation core
///
/// This module simulates the future BLE -> ESP32 -> GPIO flow.
/// It is isolated so real ESP32 BLE communication can replace it later.

class Esp32Response {
  final bool success;
  final String command;
  final String message;
  final DateTime timestamp;

  const Esp32Response({
    required this.success,
    required this.command,
    required this.message,
    required this.timestamp,
  });
}

class Esp32Simulator {
  bool connected = false;
  bool authorized = true;
  bool locked = true;
  DateTime? syncedTime;

  Future<Esp32Response> connect() async {
    connected = true;
    return _ok('CONNECT', 'ESP32模拟连接成功');
  }

  Future<Esp32Response> syncTime(DateTime time) async {
    if (!connected) return _fail('TIME_SYNC', '设备未连接');
    syncedTime = time;
    return _ok('TIME_SYNC', 'ESP32时间同步成功');
  }

  Future<Esp32Response> execute(String command) async {
    if (!connected) return _fail(command, '设备未连接');
    if (!authorized) return _fail(command, '权限关闭');

    switch (command) {
      case 'LOCK':
        locked = true;
        return _ok(command, '车辆锁定完成');
      case 'UNLOCK':
        locked = false;
        return _ok(command, '车辆解锁完成');
      default:
        return _ok(command, '指令执行完成');
    }
  }

  Esp32Response _ok(String command, String message) => Esp32Response(
        success: true,
        command: command,
        message: message,
        timestamp: DateTime.now(),
      );

  Esp32Response _fail(String command, String message) => Esp32Response(
        success: false,
        command: command,
        message: message,
        timestamp: DateTime.now(),
      );
}
