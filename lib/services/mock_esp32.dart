import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class MockESP32 {
  final String deviceName = '陕A0P92Y';

  static const String defaultDeviceId =
      'TianKey-V11-001';

  final String adminPassword =
      '13092991951';

  bool connected = false;

  bool adminAuthorized = false;

  String sessionRole = 'none';

  DateTime? deviceTime;

  String? temporaryPassword;

  DateTime? temporaryStart;

  DateTime? temporaryEnd;

  bool autoLockOnAbnormalDisconnect =
      true;

  String? _deviceId;

  String? _adminOwnerDeviceId;

  String? _originalDeviceId;

  final List<String> logs = [];

  static const String _deviceIdKey =
      'tiankey_device_id';

  static const String _originalDeviceIdKey =
      'tiankey_original_device_id';

  static const String _adminOwnerDeviceIdKey =
      'tiankey_admin_owner_device_id';

  static const String _savedRoleKey =
      'tiankey_saved_role';

  static const String _savedTempPasswordKey =
      'tiankey_saved_temp_password';

  static const String _savedTempStartKey =
      'tiankey_saved_temp_start';

  static const String _savedTempEndKey =
      'tiankey_saved_temp_end';

  String get deviceId {
    return _deviceId ??
        defaultDeviceId;
  }

  String? get adminOwnerDeviceId {
    return _adminOwnerDeviceId;
  }

  bool get isCurrentDeviceAdmin {
    return _adminOwnerDeviceId ==
            deviceId &&
        sessionRole == 'admin';
  }

  bool get temporaryAuthorizationConfigured {
    return temporaryPassword != null &&
        temporaryStart != null &&
        temporaryEnd != null;
  }

  bool get temporaryAuthorizationValid {
    if (!temporaryAuthorizationConfigured) {
      return false;
    }

    final now = DateTime.now();

    return !now.isBefore(
          temporaryStart!,
        ) &&
        now.isBefore(
          temporaryEnd!,
        );
  }

  String get temporaryAuthorizationStatus {
    if (!temporaryAuthorizationConfigured) {
      return '未设置';
    }

    final now = DateTime.now();

    if (now.isBefore(temporaryStart!)) {
      return '尚未开始';
    }

    if (!now.isBefore(temporaryEnd!)) {
      return '已过期';
    }

    return '有效';
  }

  Future<void>
      loadSavedAuthorization() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    _deviceId =
        prefs.getString(
      _deviceIdKey,
    );

    _originalDeviceId =
        prefs.getString(
      _originalDeviceIdKey,
    );

    _adminOwnerDeviceId =
        prefs.getString(
      _adminOwnerDeviceIdKey,
    );

    if (_deviceId == null ||
        _deviceId!.isEmpty) {
      _deviceId =
          _generateDeviceId();

      await prefs.setString(
        _deviceIdKey,
        _deviceId!,
      );
    }

    if (_originalDeviceId == null ||
        _originalDeviceId!.isEmpty) {
      _originalDeviceId =
          _deviceId;

      await prefs.setString(
        _originalDeviceIdKey,
        _originalDeviceId!,
      );
    }

    final savedRole =
        prefs.getString(
      _savedRoleKey,
    );

    final savedTempPassword =
        prefs.getString(
      _savedTempPasswordKey,
    );

    final savedTempStart =
        prefs.getString(
      _savedTempStartKey,
    );

    final savedTempEnd =
        prefs.getString(
      _savedTempEndKey,
    );

    if (savedTempPassword != null) {
      temporaryPassword =
          savedTempPassword;
    }

    if (savedTempStart != null) {
      temporaryStart =
          DateTime.tryParse(
        savedTempStart,
      );
    }

    if (savedTempEnd != null) {
      temporaryEnd =
          DateTime.tryParse(
        savedTempEnd,
      );
    }

    if (savedRole == 'admin') {
      if (_adminOwnerDeviceId ==
          deviceId) {
        sessionRole = 'admin';
        adminAuthorized = true;
      } else {
        sessionRole = 'none';
        adminAuthorized = false;

        await prefs.remove(
          _savedRoleKey,
        );

        addLog(
          '自动连接拒绝：当前管理员席位属于其他设备',
        );
      }
    }

    if (savedRole == 'temporary') {
      if (temporaryAuthorizationValid) {
        sessionRole =
            'temporary';
      } else {
        sessionRole = 'none';

        await prefs.remove(
          _savedRoleKey,
        );

        addLog(
          '临时授权已过期，自动授权清除',
        );
      }
    }
  }

  String _generateDeviceId() {
    final random =
        Random.secure();

    final value =
        List.generate(
      8,
      (_) => random
          .nextInt(16)
          .toRadixString(16),
    ).join();

    return 'TianKey-$value';
  }

  Future<void> _saveRole(
    String role,
  ) async {
    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.setString(
      _savedRoleKey,
      role,
    );
  }

  Future<void>
      _saveAdminOwner() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    if (_adminOwnerDeviceId ==
        null) {
      await prefs.remove(
        _adminOwnerDeviceIdKey,
      );
    } else {
      await prefs.setString(
        _adminOwnerDeviceIdKey,
        _adminOwnerDeviceId!,
      );
    }
  }

  Future<void>
      clearSavedAuthorization() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.remove(
      _savedRoleKey,
    );

    sessionRole = 'none';

    adminAuthorized = false;
  }

  Future<void>
      clearTemporaryAuthorization() async {
    final prefs =
        await SharedPreferences
            .getInstance();

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

    if (sessionRole ==
        'temporary') {
      sessionRole = 'none';

      await prefs.remove(
        _savedRoleKey,
      );
    }

    addLog(
      '临时借车授权已撤销',
    );
  }

  void addLog(
    String message,
  ) {
    final now =
        DateTime.now();

    logs.add(
      '${now.toString()} : $message',
    );

    _cleanupLogs();
  }

  void _cleanupLogs() {
    final sevenDaysAgo =
        DateTime.now().subtract(
      const Duration(
        days: 7,
      ),
    );

    logs.removeWhere(
      (log) {
        final match =
            RegExp(
          r'^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})',
        ).firstMatch(
          log,
        );

        if (match == null) {
          return false;
        }

        final time =
            DateTime.tryParse(
          match.group(1)!,
        );

        if (time == null) {
          return false;
        }

        return time.isBefore(
          sevenDaysAgo,
        );
      },
    );

    while (logs.length > 200) {
      logs.removeAt(0);
    }
  }

  bool connect() {
    connected = true;

    addLog(
      'BLE连接成功',
    );

    return true;
  }

  Future<bool>
      autoReconnect() async {
    if (sessionRole ==
        'admin') {
      if (_adminOwnerDeviceId !=
          deviceId) {
        connected = false;

        adminAuthorized = false;

        sessionRole = 'none';

        await clearSavedAuthorization();

        addLog(
          '自动连接拒绝：管理员席位已被其他设备占用',
        );

        return false;
      }

      connected = true;

      adminAuthorized = true;

      syncTime();

      addLog(
        '管理员已有授权，自动连接成功',
      );

      return true;
    }

    if (sessionRole ==
            'temporary' &&
        temporaryAuthorizationValid) {
      connected = true;

      syncTime();

      addLog(
        '临时授权仍有效，自动连接成功',
      );

      return true;
    }

    if (sessionRole ==
            'temporary' &&
        !temporaryAuthorizationValid) {
      sessionRole =
          'none';

      connected = false;

      addLog(
        '临时授权已失效，自动连接拒绝',
      );

      await clearSavedAuthorization();

      return false;
    }

    return false;
  }

  void disconnect({
    bool abnormal = false,
  }) {
    if (!connected) {
      return;
    }

    if (abnormal &&
        autoLockOnAbnormalDisconnect) {
      addLog(
        'BLE异常断开保护启动',
      );

      addLog(
        '自动落锁 GPIO12',
      );
    } else {
      addLog(
        'BLE正常断开',
      );
    }

    connected = false;

    adminAuthorized = false;

    sessionRole = 'none';

    addLog(
      '连接状态清理完成',
    );
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

    if (password !=
        adminPassword) {
      addLog(
        '管理员密码错误',
      );

      return false;
    }

    final oldOwner =
        _adminOwnerDeviceId;

    _adminOwnerDeviceId =
        deviceId;

    await _saveAdminOwner();

    adminAuthorized = true;

    sessionRole = 'admin';

    await _saveRole(
      'admin',
    );

    syncTime();

    if (oldOwner == null) {
      addLog(
        '首次管理员绑定成功',
      );
    } else if (oldOwner !=
        deviceId) {
      addLog(
        '管理员席位已从旧设备迁移到当前设备',
      );
    } else {
      addLog(
        '当前管理员设备重新认证成功',
      );
    }

    addLog(
      '管理员认证成功',
    );

    return true;
  }

  void syncTime() {
    deviceTime =
        DateTime.now();

    addLog(
      '手机时间已同步到ESP32',
    );
  }

  Future<String>
      generateTemporaryPassword({
    required DateTime start,
    required DateTime end,
  }) async {
    if (!end.isAfter(start)) {
      throw ArgumentError(
        '结束时间必须晚于开始时间',
      );
    }

    final random =
        Random.secure();

    temporaryPassword =
        List.generate(
      6,
      (_) => random.nextInt(10),
    ).join();

    temporaryStart = start;

    temporaryEnd = end;

    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.setString(
      _savedTempPasswordKey,
      temporaryPassword!,
    );

    await prefs.setString(
      _savedTempStartKey,
      temporaryStart!
          .toIso8601String(),
    );

    await prefs.setString(
      _savedTempEndKey,
      temporaryEnd!
          .toIso8601String(),
    );

    addLog(
      '生成临时借车密码：$temporaryPassword',
    );

    addLog(
      '临时授权开始：$temporaryStart',
    );

    addLog(
      '临时授权结束：$temporaryEnd',
    );

    return temporaryPassword!;
  }

  Future<bool>
      verifyTemporaryUser(
    String password,
  ) async {
    if (!connected) {
      addLog(
        '临时借车认证失败：BLE未连接',
      );

      return false;
    }

    if (!temporaryAuthorizationConfigured) {
      addLog(
        '临时借车认证失败：没有设置临时授权',
      );

      return false;
    }

    final now =
        DateTime.now();

    if (now.isBefore(
      temporaryStart!,
    )) {
      addLog(
        '临时借车认证失败：授权尚未开始',
      );

      return false;
    }

    if (!now.isBefore(
      temporaryEnd!,
    )) {
      addLog(
        '临时借车认证失败：临时授权已过期',
      );

      return false;
    }

    if (password !=
        temporaryPassword) {
      addLog(
        '临时借车密码错误',
      );

      return false;
    }

    sessionRole =
        'temporary';

    await _saveRole(
      'temporary',
    );

    syncTime();

    addLog(
      '临时借车认证成功',
    );

    return true;
  }

  Future<void>
      simulateTemporaryExpired() async {
    if (!temporaryAuthorizationConfigured) {
      addLog(
        '无法模拟过期：没有临时授权',
      );

      return;
    }

    temporaryEnd = DateTime.now()
        .subtract(
      const Duration(
        minutes: 1,
      ),
    );

    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.setString(
      _savedTempEndKey,
      temporaryEnd!
          .toIso8601String(),
    );

    if (sessionRole ==
        'temporary') {
      sessionRole =
          'none';

      connected = false;

      await prefs.remove(
        _savedRoleKey,
      );
    }

    addLog(
      '测试：临时授权已强制设置为过期',
    );
  }

  String getTemporaryAuthorizationInfo() {
    if (!temporaryAuthorizationConfigured) {
      return '暂无临时借车授权';
    }

    return '密码：$temporaryPassword\n'
        '开始：$temporaryStart\n'
        '结束：$temporaryEnd\n'
        '状态：$temporaryAuthorizationStatus';
  }

  Future<void>
      simulateNewPhone() async {
    _originalDeviceId ??=
        deviceId;

    final newDeviceId =
        _generateDeviceId();

    _deviceId =
        newDeviceId;

    connected = false;

    adminAuthorized = false;

    sessionRole = 'none';

    await _saveDeviceId();

    await clearSavedAuthorization();

    addLog(
      '已模拟切换到新手机：$newDeviceId',
    );
  }

  Future<bool>
      simulateOriginalPhoneAndAutoReconnect()
          async {
    if (_originalDeviceId ==
        null) {
      addLog(
        '没有可切回的原手机身份',
      );

      return false;
    }

    _deviceId =
        _originalDeviceId;

    connected = false;

    adminAuthorized = false;

    sessionRole = 'admin';

    await _saveDeviceId();

    await _saveRole(
      'admin',
    );

    addLog(
      '已模拟切回原管理员手机',
    );

    return autoReconnect();
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

    if (sessionRole !=
            'admin' &&
        sessionRole !=
            'temporary') {
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
