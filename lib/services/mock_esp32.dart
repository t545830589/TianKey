/// Tian Key V11 simulated ESP32 controller.
///
/// This class deliberately keeps the hardware boundary isolated from Flutter UI.
/// The real BLE/ESP32 implementation can later replace this service without
/// changing the page layer.
class MockESP32 {
  static const String vehicleName = '陕A0P92Y';
  static const String deviceName = 'TianKey BLE';
  static const String initialAdminPassword = '13092991951';

  bool _scanned = false;
  bool _connected = false;
  bool _authenticated = false;
  bool _adminAuthorized = false;
  bool _temporaryAuthorized = false;
  bool _adminSeatOccupied = false;

  String _currentUser = '无';
  String _sessionRole = '无';
  String _adminPassword = initialAdminPassword;
  String _temporaryPassword = '';
  DateTime? _temporaryStart;
  DateTime? _temporaryEnd;
  DateTime? _lastTimeSync;
  String _deviceId = 'ESP32-TIANKEY-001';

  final List<String> logs = <String>[];

  bool get scanned => _scanned;
  bool get authenticated => _authenticated;
  bool get adminAuthorized => _adminAuthorized;
  bool get temporaryAuthorized => _temporaryAuthorized;
  bool get adminSeatOccupied => _adminSeatOccupied;
  String get deviceId => _deviceId;
  String get temporaryPassword => _temporaryPassword;
  DateTime? get temporaryStart => _temporaryStart;
  DateTime? get temporaryEnd => _temporaryEnd;
  DateTime? get lastTimeSync => _lastTimeSync;

  String get sessionRole => _sessionRole;

  String getCurrentUser() => _currentUser;

  String get temporaryAuthorizationStatus {
    if (!_temporaryAuthorized) return '无临时授权';
    if (_temporaryEnd != null && DateTime.now().isAfter(_temporaryEnd!)) {
      _temporaryAuthorized = false;
      _authenticated = false;
      _sessionRole = '无';
      _currentUser = '无';
      return '临时授权已过期';
    }
    return '临时授权有效';
  }

  /// Simulates BLE discovery. No vehicle control is possible merely by scanning.
  List<String> scanDevices() {
    _scanned = true;
    logs.add('BLE扫描完成：发现 $vehicleName');
    return <String>[vehicleName];
  }

  /// Authentication happens before the simulated formal BLE connection.
  bool authenticateAdmin(String password, {bool migrate = false}) {
    if (password != _adminPassword) {
      logs.add('管理员认证失败');
      return false;
    }

    if (_adminSeatOccupied && !migrate) {
      logs.add('管理员席位已被其他设备占用');
      return false;
    }

    if (migrate) {
      logs.add('管理员席位迁移确认');
    }

    _adminSeatOccupied = true;
    _authenticated = true;
    _adminAuthorized = true;
    _temporaryAuthorized = false;
    _currentUser = '管理员';
    _sessionRole = 'admin';
    logs.add('管理员认证成功');
    return true;
  }

  bool adminLogin(String password) => authenticateAdmin(password);

  bool temporaryLogin(String password) {
    if (password.isEmpty || password != _temporaryPassword) {
      logs.add('临时密码错误');
      return false;
    }

    if (_temporaryEnd == null || DateTime.now().isAfter(_temporaryEnd!)) {
      logs.add('临时密码已过期');
      return false;
    }

    _authenticated = true;
    _temporaryAuthorized = true;
    _adminAuthorized = false;
    _currentUser = '临时借车';
    _sessionRole = 'temporary';
    logs.add('临时借车认证成功');
    return true;
  }

  /// Generates a new temporary credential for the selected duration.
  String generateTemporaryPassword(Duration duration) {
    final now = DateTime.now();
    final seed = now.millisecondsSinceEpoch % 900000 + 100000;
    _temporaryPassword = seed.toString();
    _temporaryStart = now;
    _temporaryEnd = now.add(duration);
    _temporaryAuthorized = false;
    logs.add('生成临时密码，有效至 ${_temporaryEnd!.toIso8601String()}');
    return _temporaryPassword;
  }

  void cancelTemporaryLoan() {
    _temporaryPassword = '';
    _temporaryStart = null;
    _temporaryEnd = null;
    _temporaryAuthorized = false;
    if (_sessionRole == 'temporary') {
      _authenticated = false;
      _sessionRole = '无';
      _currentUser = '无';
    }
    logs.add('临时借车已取消');
  }

  /// Backwards-compatible BLE connect used by the early prototype.
  /// It now refuses to connect before authentication.
  bool connectBLE() {
    if (!_scanned) scanDevices();
    if (!_authenticated) {
      logs.add('BLE连接拒绝：尚未完成身份认证');
      return false;
    }
    _connected = true;
    logs.add('BLE正式连接成功');
    syncTime();
    return true;
  }

  bool disconnectBLE() {
    _connected = false;
    logs.add('BLE连接断开，进入安全保护');
    return true;
  }

  bool isConnected() => _connected;

  bool autoReconnect() {
    if (!_authenticated) {
      logs.add('自动重连拒绝：当前无有效授权');
      return false;
    }
    _connected = true;
    logs.add('BLE自动重新连接成功');
    return true;
  }

  bool syncTime() {
    if (!_connected || !_authenticated) {
      logs.add('时间同步失败：设备未处于授权连接状态');
      return false;
    }
    _lastTimeSync = DateTime.now();
    logs.add('时间同步成功');
    return true;
  }

  bool changeAdminPassword(String current, String next) {
    if (!_adminAuthorized || current != _adminPassword || next.length < 8) {
      logs.add('管理员密码修改失败');
      return false;
    }
    _adminPassword = next;
    logs.add('管理员密码修改成功');
    return true;
  }

  bool migrateAdmin(String password) => authenticateAdmin(password, migrate: true);

  void releaseAdminSeat() {
    _adminSeatOccupied = false;
    _adminAuthorized = false;
    if (_sessionRole == 'admin') {
      _authenticated = false;
      _sessionRole = '无';
      _currentUser = '无';
    }
    logs.add('管理员席位已释放');
  }

  void setDeviceName(String name) {
    if (name.trim().isEmpty) return;
    _deviceId = name.trim();
    logs.add('设备名称已修改：$_deviceId');
  }

  String executeCommand(String command) {
    if (!_connected) {
      logs.add('命令拒绝：设备未连接');
      return '设备未连接';
    }
    if (!_authenticated) {
      logs.add('命令拒绝：无有效授权');
      return '无有效授权';
    }
    logs.add('执行车辆动作：$command');
    return '$command执行成功';
  }

  String controlCar(String action) => executeCommand(action);

  List<String> getLogs() {
    _pruneLogs();
    return List<String>.unmodifiable(logs);
  }

  void clearLogs() => logs.clear();

  void _pruneLogs() {
    if (logs.length > 200) {
      logs.removeRange(0, logs.length - 200);
    }
  }

  void factoryReset() {
    _scanned = false;
    _connected = false;
    _authenticated = false;
    _adminAuthorized = false;
    _temporaryAuthorized = false;
    _adminSeatOccupied = false;
    _currentUser = '无';
    _sessionRole = '无';
    _adminPassword = initialAdminPassword;
    _temporaryPassword = '';
    _temporaryStart = null;
    _temporaryEnd = null;
    _lastTimeSync = null;
    _deviceId = 'ESP32-TIANKEY-001';
    logs.clear();
    logs.add('系统已恢复出厂设置');
  }
}
