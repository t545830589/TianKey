import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Tian Key V11 simulated ESP32 controller.
///
/// Hardware behavior remains isolated here so a real BLE/ESP32 adapter can
/// replace this class later without rewriting the Flutter pages.
class MockESP32 {
  static const String vehicleName = '陕A0P92Y';
  static const String deviceName = 'TianKey BLE';
  static const String initialAdminPassword = '13092991951';
  static const int maxLogCount = 200;
  static const Duration logRetention = Duration(days: 7);

  bool _scanned = false;
  bool _connected = false;
  bool _authenticated = false;
  bool _adminAuthorized = false;
  bool _temporaryAuthorized = false;
  bool _adminSeatOccupied = false;
  bool _autoConnectEnabled = true;

  String _currentUser = '无';
  String _sessionRole = '无';
  String _adminPassword = initialAdminPassword;
  String _temporaryPassword = '';
  DateTime? _temporaryStart;
  DateTime? _temporaryEnd;
  DateTime? _lastTimeSync;
  String _deviceId = 'ESP32-TIANKEY-001';

  final List<_LogEntry> _logEntries = <_LogEntry>[];
  Future<void>? _restoreFuture;

  bool get scanned => _scanned;
  bool get authenticated => _authenticated;
  bool get adminAuthorized => _adminAuthorized;
  bool get temporaryAuthorized => _temporaryAuthorized;
  bool get adminSeatOccupied => _adminSeatOccupied;
  bool get autoConnectEnabled => _autoConnectEnabled;
  String get deviceId => _deviceId;
  String get temporaryPassword => _temporaryPassword;
  DateTime? get temporaryStart => _temporaryStart;
  DateTime? get temporaryEnd => _temporaryEnd;
  DateTime? get lastTimeSync => _lastTimeSync;
  String get sessionRole => _sessionRole;

  String getCurrentUser() => _currentUser;

  Future<void> restoreState() {
    return _restoreFuture ??= _restoreStateInternal();
  }

  Future<void> _restoreStateInternal() async {
    final prefs = await SharedPreferences.getInstance();
    _adminPassword = prefs.getString('adminPassword') ?? initialAdminPassword;
    _deviceId = prefs.getString('deviceId') ?? 'ESP32-TIANKEY-001';
    _autoConnectEnabled = prefs.getBool('autoConnectEnabled') ?? true;
    _adminSeatOccupied = prefs.getBool('adminSeatOccupied') ?? false;
    _adminAuthorized = prefs.getBool('adminAuthorized') ?? false;
    _authenticated = _adminAuthorized;
    _currentUser = prefs.getString('currentUser') ?? (_adminAuthorized ? '管理员' : '无');
    _sessionRole = prefs.getString('sessionRole') ?? (_adminAuthorized ? 'admin' : '无');
    _temporaryPassword = prefs.getString('temporaryPassword') ?? '';
    _temporaryStart = _readDate(prefs.getString('temporaryStart'));
    _temporaryEnd = _readDate(prefs.getString('temporaryEnd'));

    if (_sessionRole == 'temporary') {
      final status = temporaryAuthorizationStatus;
      if (status != '临时授权有效') {
        _sessionRole = '无';
        _currentUser = '无';
        _authenticated = false;
        _temporaryAuthorized = false;
      } else {
        _temporaryAuthorized = true;
      }
    }

    if (_autoConnectEnabled && _authenticated) {
      _scanned = true;
      autoReconnect();
    }
  }

  DateTime? _readDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  void _persistSoon() {
    unawaited(_persist());
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adminPassword', _adminPassword);
    await prefs.setString('deviceId', _deviceId);
    await prefs.setBool('autoConnectEnabled', _autoConnectEnabled);
    await prefs.setBool('adminSeatOccupied', _adminSeatOccupied);
    await prefs.setBool('adminAuthorized', _adminAuthorized);
    await prefs.setString('currentUser', _currentUser);
    await prefs.setString('sessionRole', _sessionRole);
    await prefs.setString('temporaryPassword', _temporaryPassword);
    if (_temporaryStart == null) {
      await prefs.remove('temporaryStart');
    } else {
      await prefs.setString('temporaryStart', _temporaryStart!.toIso8601String());
    }
    if (_temporaryEnd == null) {
      await prefs.remove('temporaryEnd');
    } else {
      await prefs.setString('temporaryEnd', _temporaryEnd!.toIso8601String());
    }
  }

  String get temporaryAuthorizationStatus {
    if (!_temporaryAuthorized) return '无临时授权';
    if (_temporaryEnd != null && DateTime.now().isAfter(_temporaryEnd!)) {
      _temporaryAuthorized = false;
      _authenticated = false;
      _connected = false;
      _sessionRole = '无';
      _currentUser = '无';
      _persistSoon();
      _addLog('临时授权已过期，连接已断开');
      return '临时授权已过期';
    }
    return '临时授权有效';
  }

  List<String> scanDevices() {
    _scanned = true;
    _addLog('BLE扫描完成：发现 $vehicleName');
    return <String>[vehicleName];
  }

  bool authenticateAdmin(String password, {bool migrate = false}) {
    if (password != _adminPassword) {
      _addLog('管理员认证失败');
      return false;
    }
    if (_adminSeatOccupied && !migrate) {
      _addLog('管理员席位已被其他设备占用');
      return false;
    }
    if (migrate) _addLog('管理员席位迁移确认：旧管理员应立即失效');

    _adminSeatOccupied = true;
    _authenticated = true;
    _adminAuthorized = true;
    _temporaryAuthorized = false;
    _currentUser = '管理员';
    _sessionRole = 'admin';
    _persistSoon();
    _addLog(migrate ? '管理员迁移认证成功' : '管理员认证成功');
    return true;
  }

  bool adminLogin(String password) => authenticateAdmin(password);

  bool temporaryLogin(String password) {
    if (password.isEmpty || password != _temporaryPassword) {
      _addLog('临时密码错误');
      return false;
    }
    if (_temporaryStart == null || _temporaryEnd == null) {
      _addLog('临时授权失败：未配置有效时间窗口');
      return false;
    }
    final now = DateTime.now();
    if (now.isBefore(_temporaryStart!) || now.isAfter(_temporaryEnd!)) {
      _addLog('临时密码不在有效时间窗口');
      return false;
    }

    _authenticated = true;
    _temporaryAuthorized = true;
    _adminAuthorized = false;
    _currentUser = '临时借车';
    _sessionRole = 'temporary';
    _persistSoon();
    _addLog('临时借车认证成功');
    return true;
  }

  String generateTemporaryPassword(Duration duration) {
    final now = DateTime.now();
    final seed = (now.microsecondsSinceEpoch % 900000) + 100000;
    _temporaryPassword = seed.toString();
    _temporaryStart = now;
    _temporaryEnd = now.add(duration);
    _temporaryAuthorized = false;
    _persistSoon();
    _addLog('生成临时密码，有效至 ${_temporaryEnd!.toIso8601String()}');
    return _temporaryPassword;
  }

  void cancelTemporaryLoan() {
    _temporaryPassword = '';
    _temporaryStart = null;
    _temporaryEnd = null;
    _temporaryAuthorized = false;
    if (_sessionRole == 'temporary') {
      _authenticated = false;
      _connected = false;
      _sessionRole = '无';
      _currentUser = '无';
    }
    _persistSoon();
    _addLog('临时借车已取消');
  }

  bool connectBLE() {
    if (!_scanned) scanDevices();
    if (!_authenticated) {
      _addLog('BLE连接拒绝：尚未完成身份认证');
      return false;
    }
    if (_sessionRole == 'temporary') {
      final status = temporaryAuthorizationStatus;
      if (status != '临时授权有效') return false;
    }
    _connected = true;
    _addLog('BLE正式连接成功');
    syncTime();
    return true;
  }

  bool disconnectBLE() {
    _connected = false;
    _addLog('BLE连接断开，进入安全保护');
    return true;
  }

  bool isConnected() => _connected;

  bool autoReconnect() {
    if (!_authenticated) {
      _addLog('自动重连拒绝：当前无有效授权');
      return false;
    }
    if (_sessionRole == 'temporary' && temporaryAuthorizationStatus != '临时授权有效') {
      _addLog('自动重连拒绝：临时授权已失效');
      return false;
    }
    _connected = true;
    _addLog('BLE自动重新连接成功');
    syncTime();
    return true;
  }

  void setAutoConnectEnabled(bool enabled) {
    _autoConnectEnabled = enabled;
    _persistSoon();
    _addLog('自动连接已${enabled ? '开启' : '关闭'}');
  }

  bool syncTime() {
    if (!_connected || !_authenticated) {
      _addLog('时间同步失败：设备未处于授权连接状态');
      return false;
    }
    _lastTimeSync = DateTime.now();
    _addLog('时间同步成功');
    return true;
  }

  bool changeAdminPassword(String current, String next) {
    if (!_adminAuthorized || current != _adminPassword || next.length < 8) {
      _addLog('管理员密码修改失败');
      return false;
    }
    _adminPassword = next;
    _persistSoon();
    _addLog('管理员密码修改成功');
    return true;
  }

  bool migrateAdmin(String password) => authenticateAdmin(password, migrate: true);

  void releaseAdminSeat() {
    _adminSeatOccupied = false;
    _adminAuthorized = false;
    if (_sessionRole == 'admin') {
      _authenticated = false;
      _connected = false;
      _sessionRole = '无';
      _currentUser = '无';
    }
    _persistSoon();
    _addLog('管理员席位已释放');
  }

  void setDeviceName(String name) {
    final value = name.trim();
    if (value.isEmpty) {
      _addLog('设备名称修改失败：名称为空');
      return;
    }
    _deviceId = value;
    _persistSoon();
    _addLog('设备名称已修改：$_deviceId');
  }

  /// Adds an event from the vehicle/GPIO simulation into the unified TianKey log.
  void recordVehicleEvent(String event) {
    _addLog('车辆硬件事件：$event');
  }

  String executeCommand(String command) {
    if (!_connected) {
      _addLog('命令拒绝：设备未连接');
      return '设备未连接';
    }
    if (!_authenticated) {
      _addLog('命令拒绝：无有效授权');
      return '无有效授权';
    }
    if (_sessionRole == 'temporary' && temporaryAuthorizationStatus != '临时授权有效') {
      _connected = false;
      _addLog('命令拒绝：临时授权已失效');
      return '临时授权已失效';
    }
    _addLog('执行车辆动作：$command');
    return '$command执行成功';
  }

  String controlCar(String action) => executeCommand(action);

  List<String> getLogs() {
    _pruneLogs();
    return List<String>.unmodifiable(
      _logEntries.map((entry) => entry.render()).toList(growable: false),
    );
  }

  void clearLogs() {
    _logEntries.clear();
  }

  void _addLog(String message) {
    _pruneLogs();
    _logEntries.add(_LogEntry(DateTime.now(), message));
    if (_logEntries.length > maxLogCount) {
      _logEntries.removeRange(0, _logEntries.length - maxLogCount);
    }
  }

  void _pruneLogs() {
    final cutoff = DateTime.now().subtract(logRetention);
    _logEntries.removeWhere((entry) => entry.time.isBefore(cutoff));
    if (_logEntries.length > maxLogCount) {
      _logEntries.removeRange(0, _logEntries.length - maxLogCount);
    }
  }

  void factoryReset() {
    _scanned = false;
    _connected = false;
    _authenticated = false;
    _adminAuthorized = false;
    _temporaryAuthorized = false;
    _adminSeatOccupied = false;
    _autoConnectEnabled = true;
    _currentUser = '无';
    _sessionRole = '无';
    _adminPassword = initialAdminPassword;
    _temporaryPassword = '';
    _temporaryStart = null;
    _temporaryEnd = null;
    _lastTimeSync = null;
    _deviceId = 'ESP32-TIANKEY-001';
    _logEntries.clear();
    _addLog('系统已恢复出厂设置');
    _persistSoon();
  }
}

class _LogEntry {
  final DateTime time;
  final String message;

  const _LogEntry(this.time, this.message);

  String render() {
    String two(int value) => value.toString().padLeft(2, '0');
    final stamp = '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
    return '[$stamp] $message';
  }
}
