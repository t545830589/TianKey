import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class MockESP32 {
  final String deviceName = '陕A0P92Y';
  final String deviceId = 'TianKey-V11-001';

  // Tian Key V11 最终确认的初始管理员密码
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

  static const String _savedRoleKey =
      'tiankey_saved_role';

  static const String _savedTempPasswordKey =
      'tiankey_saved_temp_password';

  static const String _savedTempStartKey =
      'tiankey_saved_temp_start';

  static const String _savedTempEndKey =
      'tiankey_saved_temp_end';

  Future<void> loadSavedAuthorization() async {
    final prefs = await SharedPreferences.getInstance();

    final savedRole = prefs.getString(_savedRoleKey);

    final savedTempPassword =
        prefs.getString(_savedTempPasswordKey);

    final savedTempStart =
        prefs.getString(_savedTempStartKey);

    final savedTempEnd =
        prefs.getString(_savedTempEndKey);

    if (savedTempPassword != null) {
      temporaryPassword = savedTempPassword;
    }

    if (savedTempStart != null) {
      temporaryStart = DateTime.tryParse(
        savedTempStart,
      );
    }

    if (savedTempEnd != null) {
      temporaryEnd = DateTime.tryParse(
        savedTempEnd,
      );
    }

    if (savedRole == 'admin') {
      sessionRole = 'admin';
      adminAuthorized = true;
    }

    if (savedRole == 'temporary' &&
        temporaryAuthorizationValid) {
      sessionRole = 'temporary';
    }

    // 临时授权已经失效时，不恢复临时身份。
    if (savedRole == 'temporary' &&
        !temporaryAuthorizationValid) {
      await prefs.remove(_savedRoleKey);
      sessionRole = 'none';
    }
  }

  Future<void> _saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _savedRoleKey,
      role,
    );
  }

  Future<void> clearSavedAuthorization() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_savedRoleKey);

    sessionRole = 'none';
    adminAuthorized = false;
  }

  Future<void> clearTemporaryAuthorization() async {
    final prefs = await SharedPreferences.getInstance();

    temporaryPassword = null;
    temporaryStart = null;
    temporaryEnd = null;

    await prefs.remove(
      _savedTempPasswordKey,
    );

    await prefs.remove(
      _savedTempStartKey,
    );

    await prefs.remove(
      _savedTempEndKey,
    );

    if (sessionRole == 'temporary') {
      sessionRole = 'none';
    }
  }

  void addLog(String message) {
    final now = DateTime.now();

    logs.add(
      '${now.toString()} : $message',
    );

    _cleanupLogs();
  }

  void _cleanupLogs() {
    final sevenDaysAgo =
        DateTime.now().subtract(
      const Duration(days: 7),
    );

    logs.removeWhere((log) {
      final match = RegExp(
        r'^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})',
      ).firstMatch(log);

      if (match == null) {
        return false;
      }

      final time = DateTime.tryParse(
        match.group(1)!,
      );

      if (time == null) {
        return false;
      }

      return time.isBefore(
        sevenDaysAgo,
      );
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

  Future<void> autoReconnect() async {
    if (sessionRole == 'admin') {
      connected = true;
      adminAuthorized = true;

      syncTime();

      addLog(
        '管理员已有授权，自动连接成功',
      );

      return;
    }

    if (sessionRole == 'temporary' &&
        temporaryAuthorizationValid) {
      connected = true;

      syncTime();

      addLog(
        '临时授权仍有效，自动连接成功',
      );

      return;
    }
  }

  void disconnect({
    bool abnormal = false,
  }) {
    if (!connected) {
      return;
    }

    if (abnormal &&
        autoLockOnAbnormalDisconnect) {
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

  Future<bool> verifyAdmin(
    String password,
  ) async {
    if (!connected) {
      addLog(
        '管理员认证失败：BLE未连接',
      );

      return false;
    }

    if (password != adminPassword) {
      addLog('管理员密码错误');

      return false;
    }

    adminAuthorized = true;
    sessionRole = 'admin';

    await _saveRole('admin');

    syncTime();

    addLog('管理员认证成功');

    return true;
  }

  void syncTime() {
    deviceTime = DateTime.now();

    addLog(
      '手机时间已同步到ESP32',
    );
  }

  Future<String> generateTemporaryPassword({
    Duration validity =
        const Duration(hours: 24),
  }) async {
    final random = Random.secure();

    temporaryPassword =
        List.generate(
      6,
      (_) => random.nextInt(10),
    ).join();

    temporaryStart = DateTime.now();

    temporaryEnd =
        temporaryStart!.add(
      validity,
    );

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _savedTempPasswordKey,
      temporaryPassword!,
    );

    await prefs.setString(
      _savedTempStartKey,
      temporaryStart!.toIso8601String(),
    );

    await prefs.setString(
      _savedTempEndKey,
      temporaryEnd!.toIso8601String(),
    );

    addLog(
      '生成临时借车密码：$temporaryPassword',
    );

    return temporaryPassword!;
  }

  Future<bool> verifyTemporaryUser(
    String password,
  ) async {
    if (!connected) {
      addLog(
        '临时借车认证失败：BLE未连接',
      );

      return false;
    }

    if (temporaryPassword == null ||
        temporaryStart == null ||
        temporaryEnd == null) {
      addLog(
        '临时借车认证失败：没有有效临时授权',
      );

      return false;
    }

    final now = DateTime.now();

    if (now.isBefore(temporaryStart!)) {
      addLog(
        '临时借车认证失败：授权尚未开始',
      );

      return false;
    }

    if (now.isAfter(temporaryEnd!)) {
      addLog(
        '临时借车认证失败：临时授权已过期',
      );

      return false;
    }

    if (password != temporaryPassword) {
      addLog(
        '临时借车密码错误',
      );

      return false;
    }

    sessionRole = 'temporary';

    await _saveRole('temporary');

    syncTime();

    addLog(
      '临时借车认证成功',
    );

    return true;
  }

  bool get temporaryAuthorizationValid {
    if (temporaryPassword == null ||
        temporaryStart == null ||
        temporaryEnd == null) {
      return false;
    }

    final now = DateTime.now();

    return !now.isBefore(
          temporaryStart!,
        ) &&
        !now.isAfter(
          temporaryEnd!,
        );
  }

  String executeCommand(
    String command,
  ) {
    if (!connected) {
      addLog(
        '车辆指令拒绝：BLE未连接',
      );

      return '未连接';
    }

    if (sessionRole != 'admin' &&
        sessionRole != 'temporary') {
      addLog(
        '车辆指令拒绝：未授权',
      );

      return '无权限';
    }

    switch (command) {
      case 'suoche':
        addLog(
          '锁车 GPIO12 短脉冲执行',
        );
        return '锁车成功';

      case 'jiesuo':
        addLog(
          '解锁 GPIO13 短脉冲执行',
        );
        return '解锁成功';

      case 'xunche':
        addLog(
          '寻车 GPIO12 连续双脉冲执行',
        );
        return '寻车成功';

      case 'chuangsheng':
        addLog(
          '升窗 GPIO12 保持7秒执行',
        );
        return '升窗成功';

      case 'chuangjiang':
        addLog(
          '降窗 GPIO13 保持7秒执行',
        );
        return '降窗成功';

      case 'houbeixiang':
        addLog(
          '后备箱 GPIO14 保持7秒执行',
        );
        return '后备箱成功';

      default:
        addLog(
          '未知车辆指令：$command',
        );
        return '未知指令';
    }
  }
}
