import 'dart:math';

class MockESP32 {
  final String deviceName = '陕A0P92Y';
  final String deviceId = 'TianKey-V11-001';

  final String adminPassword = '13092991951';

  bool connected = false;
  bool adminAuthorized = false;

  String sessionRole = 'none';

  DateTime? deviceTime;

  String? temporaryPassword;
  DateTime? temporaryStart;
  DateTime? temporaryEnd;

  bool autoLockOnAbnormalDisconnect = true;

  final List<String> logs = [];

  void addLog(String message) {
    final now = DateTime.now();

    logs.add(
      '${now.toString()} : $message',
    );

    _cleanupLogs();
  }

  void _cleanupLogs() {
    final sevenDaysAgo = DateTime.now().subtract(
      const Duration(days: 7),
    );

    logs.removeWhere((log) {
      final match = RegExp(
        r'^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})',
      ).firstMatch(log);

      if (match == null) {
        return false;
      }

      final time = DateTime.tryParse(match.group(1)!);

      if (time == null) {
        return false;
      }

      return time.isBefore(sevenDaysAgo);
    });

    while (logs.length > 200) {
      logs.removeAt(0);
    }
  }

  bool connect() {
    connected = true;

    addLog('BLE连接成功');

    return true;
  }

  void disconnect({bool abnormal = false}) {
    if (!connected) {
      return;
    }

    if (abnormal && autoLockOnAbnormalDisconnect) {
      addLog('BLE异常断开保护启动');
      addLog('自动落锁 GPIO12');
    } else {
      addLog('BLE正常断开');
    }

    connected = false;
    adminAuthorized = false;
    sessionRole = 'none';

    addLog('连接状态清理完成');
  }

  bool verifyAdmin(String password) {
    if (!connected) {
      addLog('管理员认证失败：BLE未连接');
      return false;
    }

    if (password != adminPassword) {
      addLog('管理员密码错误');
      return false;
    }

    adminAuthorized = true;
    sessionRole = 'admin';

    syncTime();

    addLog('管理员认证成功');

    return true;
  }

  void syncTime() {
    deviceTime = DateTime.now();

    addLog('手机时间已同步到ESP32');
  }

  String generateTemporaryPassword({
    Duration validity = const Duration(hours: 24),
  }) {
    final random = Random.secure();

    temporaryPassword = List.generate(
      6,
      (_) => random.nextInt(10),
    ).join();

    temporaryStart = DateTime.now();
    temporaryEnd = temporaryStart!.add(validity);

    addLog(
      '生成临时借车密码：$temporaryPassword',
    );

    return temporaryPassword!;
  }

  bool verifyTemporaryUser(String password) {
    if (!connected) {
      addLog('临时借车认证失败：BLE未连接');
      return false;
    }

    if (temporaryPassword == null ||
        temporaryStart == null ||
        temporaryEnd == null) {
      addLog('临时借车认证失败：没有有效临时授权');
      return false;
    }

    final now = DateTime.now();

    if (now.isBefore(temporaryStart!)) {
      addLog('临时借车认证失败：授权尚未开始');
      return false;
    }

    if (now.isAfter(temporaryEnd!)) {
      addLog('临时借车认证失败：临时授权已过期');
      return false;
    }

    if (password != temporaryPassword) {
      addLog('临时借车密码错误');
      return false;
    }

    sessionRole = 'temporary';

    syncTime();

    addLog('临时借车认证成功');

    return true;
  }

  bool get temporaryAuthorizationValid {
    if (temporaryPassword == null ||
        temporaryStart == null ||
        temporaryEnd == null) {
      return false;
    }

    final now = DateTime.now();

    return !now.isBefore(temporaryStart!) &&
        !now.isAfter(temporaryEnd!);
  }

  String executeCommand(String command) {
    if (!connected) {
      addLog('车辆指令拒绝：BLE未连接');
      return '未连接';
    }

    if (sessionRole != 'admin' && sessionRole != 'temporary') {
      addLog('车辆指令拒绝：未授权');
      return '无权限';
    }

    switch (command) {
      case 'suoche':
        addLog('锁车 GPIO12 短脉冲执行');
        return '锁车成功';

      case 'jiesuo':
        addLog('解锁 GPIO13 短脉冲执行');
        return '解锁成功';

      case 'xunche':
        addLog('寻车 GPIO12 连续双脉冲执行');
        return '寻车成功';

      case 'chuangsheng':
        addLog('升窗 GPIO12 保持7秒执行');
        return '升窗成功';

      case 'chuangjiang':
        addLog('降窗 GPIO13 保持7秒执行');
        return '降窗成功';

      case 'houbeixiang':
        addLog('后备箱 GPIO14 保持7秒执行');
        return '后备箱成功';

      default:
        addLog('未知车辆指令：$command');
        return '未知指令';
    }
  }
}
