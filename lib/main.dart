import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TianKeyApp());
}

class TianKeyApp extends StatelessWidget {
  const TianKeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tian Key V11',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF05070A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC9A227),
          secondary: Color(0xFF19D36B),
        ),
      ),
      home: const TianKeyHome(),
    );
  }
}

enum AccessMode { admin, borrower }

class TianKeyHome extends StatefulWidget {
  const TianKeyHome({super.key});

  @override
  State<TianKeyHome> createState() => _TianKeyHomeState();
}

class _TianKeyHomeState extends State<TianKeyHome> {
  static const String defaultDeviceName = '陕A0P92Y';
  static const String defaultAdminPassword = '13092991954';
  static const int lockGpio = 12;
  static const int unlockGpio = 13;
  static const int trunkGpio = 14;
  static const int trunkSeconds = 7;

  final TextEditingController _password = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _deviceName = TextEditingController();
  final TextEditingController _borrowHours = TextEditingController(text: '2');

  SharedPreferences? _prefs;
  int _page = 0;
  bool _ready = false;
  bool _scanning = false;
  bool _found = false;
  bool _connecting = false;
  bool _connected = false;
  bool _timeSynced = false;
  bool _autoConnect = true;
  bool _sound = true;
  bool _authorized = true;
  AccessMode? _mode;
  String _deviceNameValue = defaultDeviceName;
  String _deviceId = 'TIANKEY-AXELA-01';
  String _adminPassword = defaultAdminPassword;
  String? _borrowCode;
  DateTime? _borrowExpires;
  DateTime? _espTime;
  String _status = 'APP已打开：车辆功能锁定，请点击蓝牙扫描';
  String _lastCommand = '';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _password.dispose();
    _newPassword.dispose();
    _deviceName.dispose();
    _borrowHours.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    setState(() {
      _deviceNameValue = p.getString('device_name') ?? defaultDeviceName;
      _deviceId = p.getString('device_id') ?? 'TIANKEY-AXELA-01';
      _adminPassword = p.getString('admin_password') ?? defaultAdminPassword;
      _borrowCode = p.getString('borrow_code');
      final expires = p.getInt('borrow_expires');
      _borrowExpires = expires == null ? null : DateTime.fromMillisecondsSinceEpoch(expires);
      _autoConnect = p.getBool('auto_connect') ?? true;
      _sound = p.getBool('sound') ?? true;
      _authorized = p.getBool('authorized') ?? true;
      _ready = true;
    });
    if (_borrowExpires != null && DateTime.now().isAfter(_borrowExpires!)) {
      await _clearBorrowCode();
    }
  }

  bool get _borrowValid =>
      _borrowCode != null &&
      _borrowExpires != null &&
      DateTime.now().isBefore(_borrowExpires!);

  bool get _vehicleEnabled => _connected && _authorized;

  bool get _adminEnabled => _connected && _mode == AccessMode.admin && _authorized;

  Future<void> _scan() async {
    if (!_ready || _scanning || _connecting) return;
    setState(() {
      _scanning = true;
      _found = false;
      _status = '正在扫描 BLE 设备...';
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _found = true;
      _status = '发现设备：$_deviceNameValue';
    });
  }

  Future<void> _chooseAndConnect() async {
    if (!_found || _connecting || _connected) return;
    final mode = await showDialog<AccessMode>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('请选择登录模式'),
        content: const Text('管理员模式：全部权限\n临时借车模式：只有车辆控制权限'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, AccessMode.borrower),
            child: const Text('临时借车模式'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, AccessMode.admin),
            child: const Text('管理员模式'),
          ),
        ],
      ),
    );
    if (mode == null || !mounted) return;

    _password.clear();
    final verified = await _verifyPassword(mode);
    if (!verified || !mounted) return;

    setState(() {
      _connecting = true;
      _status = '密码验证通过，正在建立 BLE 连接...';
    });
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() {
      _connected = true;
      _mode = mode;
      _connecting = false;
      _timeSynced = false;
      _status = 'BLE连接成功，正在自动同步时间...';
    });

    await _syncTimeAutomatically();
    await _saveConnection();
  }

  Future<bool> _verifyPassword(AccessMode mode) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(mode == AccessMode.admin ? '管理员密码' : '临时借车密码'),
        content: TextField(
          controller: _password,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '请输入密码',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final value = _password.text.trim();
              final ok = mode == AccessMode.admin
                  ? value == _adminPassword
                  : _borrowValid && value == _borrowCode;
              if (ok) {
                Navigator.pop(context, true);
              } else {
                _show('密码错误、授权无效或临时借车密码已过期');
              }
            },
            child: const Text('验证'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _syncTimeAutomatically() async {
    if (!_connected) return;
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _espTime = now;
      _timeSynced = true;
      _status = '已连接 · APP与ESP32时间已自动同步';
    });
  }

  Future<void> _saveConnection() async {
    final p = _prefs;
    if (p == null) return;
    await p.setString('device_id', _deviceId);
    await p.setString('device_name', _deviceNameValue);
  }

  Future<void> _disconnect() async {
    setState(() {
      _connected = false;
      _mode = null;
      _timeSynced = false;
      _espTime = null;
      _status = 'BLE已断开：车辆功能重新锁定';
    });
  }

  Future<void> _generateBorrowCode() async {
    if (!_adminEnabled) return;
    final hours = int.tryParse(_borrowHours.text.trim()) ?? 2;
    final safeHours = hours.clamp(1, 24).toInt();
    final code = (100000 + Random().nextInt(900000)).toString();
    final expires = DateTime.now().add(Duration(hours: safeHours));
    final p = _prefs;
    if (p != null) {
      await p.setString('borrow_code', code);
      await p.setInt('borrow_expires', expires.millisecondsSinceEpoch);
    }
    setState(() {
      _borrowCode = code;
      _borrowExpires = expires;
      _status = '临时借车密码已生成，并模拟同步保存到ESP32';
    });
    _show('临时借车密码：$code\n有效期：$safeHours 小时');
  }

  Future<void> _clearBorrowCode() async {
    final p = _prefs;
    if (p != null) {
      await p.remove('borrow_code');
      await p.remove('borrow_expires');
    }
    if (!mounted) return;
    setState(() {
      _borrowCode = null;
      _borrowExpires = null;
    });
  }

  Future<void> _changeAdminPassword() async {
    if (!_adminEnabled) return;
    _newPassword.clear();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('修改管理员/蓝牙密码'),
        content: TextField(
          controller: _newPassword,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '输入新的密码',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('发送并保存')),
        ],
      ),
    );
    if (ok != true) return;
    final value = _newPassword.text.trim();
    if (value.length < 6) {
      _show('密码至少6位');
      return;
    }
    final p = _prefs;
    if (p != null) await p.setString('admin_password', value);
    setState(() {
      _adminPassword = value;
      _status = '新管理员/蓝牙密码已模拟发送并保存到ESP32';
    });
    _show('密码修改成功：APP与ESP32已同步');
  }

  Future<void> _changeDeviceName() async {
    if (!_adminEnabled) return;
    _deviceName.text = _deviceNameValue;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('修改设备名称'),
        content: TextField(
          controller: _deviceName,
          decoration: const InputDecoration(
            labelText: 'BLE设备名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('发送并保存')),
        ],
      ),
    );
    if (ok != true) return;
    final value = _deviceName.text.trim();
    if (value.isEmpty) return;
    final p = _prefs;
    if (p != null) await p.setString('device_name', value);
    setState(() {
      _deviceNameValue = value;
      _status = '设备名称已模拟发送并保存到ESP32';
    });
  }

  Future<void> _toggleAuthorization() async {
    if (!_adminEnabled) return;
    final next = !_authorized;
    final p = _prefs;
    if (p != null) await p.setBool('authorized', next);
    setState(() {
      _authorized = next;
      _status = next ? 'ESP32授权已恢复，车辆控制可用' : 'ESP32授权已关闭，车辆控制全部锁定';
    });
  }

  Future<void> _toggleAutoConnect(bool value) async {
    final p = _prefs;
    if (p != null) await p.setBool('auto_connect', value);
    setState(() => _autoConnect = value);
    _show(value ? '已开启自动连接：后续可使用已保存设备ID' : '已关闭自动连接');
  }

  Future<void> _toggleSound(bool value) async {
    final p = _prefs;
    if (p != null) await p.setBool('sound', value);
    setState(() => _sound = value);
  }

  void _vehicleCommand(String command, {int? gpio, int seconds = 1, int pulses = 1}) {
    if (!_vehicleEnabled) {
      _show('当前没有车辆控制权限');
      return;
    }
    final gpioText = gpio == null ? '由ESP32指令处理' : 'GPIO$gpio';
    final pulseText = pulses > 1 ? '$pulses次脉冲' : '1次脉冲';
    setState(() {
      _lastCommand = '$command · $gpioText · ${seconds}秒 · $pulseText';
      _status = '已发送车辆指令：$_lastCommand';
    });
    _show('已发送：$command\n$gpioText\n$seconds 秒\n$pulseText');
  }

  void _show(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _statusRow(String title, String value, {bool active = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: Colors.grey))),
          Text(value, style: TextStyle(color: active ? const Color(0xFF19D36B) : Colors.white)),
        ],
      ),
    );
  }

  Widget _control(String title, IconData icon, VoidCallback? action) {
    final enabled = action != null;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: FilledButton(
          onPressed: action,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 70),
            backgroundColor: enabled ? const Color(0xFF123C24) : const Color(0xFF25282D),
            foregroundColor: enabled ? const Color(0xFF19D36B) : Colors.grey,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(icon, size: 23), const SizedBox(height: 4), Text(title)],
          ),
        ),
      ),
    );
  }

  Widget _background(String asset, Widget child) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(image: AssetImage(asset), fit: BoxFit.cover, opacity: 0.55),
      ),
      child: child,
    );
  }

  Widget _homePage() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _background(
          'assets/home_car_bg.png',
          SizedBox(
            height: 190,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                _deviceNameValue,
                style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _statusRow('蓝牙', _connected ? '已连接' : '未连接', active: _connected),
                _statusRow('登录权限', !_connected ? '未授权' : (_mode == AccessMode.admin ? '管理员' : '临时借车'), active: _connected),
                _statusRow('时间', _timeSynced ? '已同步' : '未同步', active: _timeSynced),
                _statusRow('授权状态', _authorized ? '有效' : '已关闭', active: _authorized),
                const SizedBox(height: 8),
                Text(_status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _scanning ? null : _scan,
                icon: const Icon(Icons.bluetooth_searching),
                label: Text(_scanning ? '扫描中...' : '蓝牙扫描'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _found && !_connected && !_connecting ? _chooseAndConnect : null,
                icon: const Icon(Icons.link),
                label: Text(_connecting ? '连接中...' : '连接'),
              ),
            ),
          ],
        ),
        if (_found)
          Card(
            child: ListTile(
              leading: const Icon(Icons.bluetooth),
              title: Text(_deviceNameValue),
              subtitle: Text('设备ID：$_deviceId'),
              trailing: _connected ? const Icon(Icons.check_circle, color: Color(0xFF19D36B)) : const Text('点击连接'),
              onTap: _connected ? null : _chooseAndConnect,
            ),
          ),
        const SizedBox(height: 14),
        _background(
          'assets/home_controls_bg.png',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('车辆控制', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                _control('锁车', Icons.lock, _vehicleEnabled ? () => _vehicleCommand('锁车', gpio: lockGpio) : null),
                _control('解锁', Icons.lock_open, _vehicleEnabled ? () => _vehicleCommand('解锁', gpio: unlockGpio) : null),
                _control('寻车', Icons.directions_car, _vehicleEnabled ? () => _vehicleCommand('寻车', gpio: lockGpio, pulses: 2) : null),
              ]),
              Row(children: [
                _control('升窗', Icons.arrow_upward, _vehicleEnabled ? () => _vehicleCommand('升窗', seconds: 7) : null),
                _control('降窗', Icons.arrow_downward, _vehicleEnabled ? () => _vehicleCommand('降窗', seconds: 7) : null),
                _control('后备箱', Icons.inventory_2, _vehicleEnabled ? () => _vehicleCommand('后备箱', gpio: trunkGpio, seconds: trunkSeconds) : null),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_lastCommand.isNotEmpty)
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('最近模拟指令：$_lastCommand'))),
      ],
    );
  }

  Widget _borrowPage() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _background(
          'assets/borrow_page_bg.png',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('临时借车', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('管理员连接车辆后生成临时借车密码。密码会模拟同步保存到ESP32，朋友连接时选择“临时借车模式”验证。'),
              const SizedBox(height: 18),
              if (_adminEnabled) ...[
                TextField(
                  controller: _borrowHours,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '有效小时数（1～24）', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(onPressed: _generateBorrowCode, icon: const Icon(Icons.key), label: const Text('生成临时借车密码')),
              ] else
                const Text('只有管理员模式可以生成或修改临时借车密码。', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: _borrowValid
                      ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('当前临时密码', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 5),
                          Text(_borrowCode!, style: const TextStyle(fontSize: 32, letterSpacing: 4, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('有效至：${_borrowExpires!}'),
                          if (_adminEnabled) TextButton(onPressed: _clearBorrowCode, child: const Text('立即作废')),
                        ])
                      : const Text('当前没有有效的临时借车密码。'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingsPage() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _background(
          'assets/settings_page_bg.png',
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('设置', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('管理员权限下修改的信息会模拟发送到ESP32并保存。'),
          ]),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.bluetooth),
                title: const Text('自动连接'),
                subtitle: const Text('保存设备ID后，后续可自动连接；首次连接仍按扫描→选择模式→密码→时间同步流程。'),
                trailing: Switch(value: _autoConnect, onChanged: _toggleAutoConnect),
              ),
              ListTile(
                leading: const Icon(Icons.volume_up),
                title: const Text('声音反馈'),
                trailing: Switch(value: _sound, onChanged: _toggleSound),
              ),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('时间同步状态'),
                subtitle: Text(_timeSynced ? '连接后已自动同步：${_espTime ?? ''}' : '每次BLE连接成功后自动同步'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.devices),
                title: const Text('设备名称'),
                subtitle: Text(_deviceNameValue),
                trailing: IconButton(onPressed: _adminEnabled ? _changeDeviceName : null, icon: const Icon(Icons.edit)),
              ),
              ListTile(
                leading: const Icon(Icons.password),
                title: const Text('管理员/蓝牙密码'),
                subtitle: const Text('修改后模拟发送给ESP32并保存'),
                trailing: IconButton(onPressed: _adminEnabled ? _changeAdminPassword : null, icon: const Icon(Icons.edit)),
              ),
              ListTile(
                leading: Icon(_authorized ? Icons.verified_user : Icons.block),
                title: const Text('授权状态'),
                subtitle: Text(_authorized ? '当前有效' : '当前关闭'),
                trailing: Switch(value: _authorized, onChanged: _adminEnabled ? (_) => _toggleAuthorization() : null),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ESP32保存内容（模拟镜像）', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _statusRow('设备名称', _deviceNameValue),
              _statusRow('管理员/蓝牙密码', '已保存（不在界面明文显示）'),
              _statusRow('授权状态', _authorized ? '有效' : '关闭'),
              _statusRow('时间', _espTime?.toString() ?? '未同步'),
              _statusRow('临时密码', _borrowValid ? '已保存' : '无有效密码'),
              _statusRow('临时密码有效时间', _borrowValid ? _borrowExpires.toString() : '无'),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _adminPage() {
    final isAdmin = _adminEnabled;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _background(
          'assets/popup_admin_auth.png',
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('管理员操作', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(isAdmin ? '管理员权限已开启：可修改ESP32保存信息。' : '未进入管理员模式：所有管理按键保持灰色。'),
          ]),
        ),
        const SizedBox(height: 12),
        _adminAction('修改管理员/蓝牙密码', Icons.password, isAdmin ? _changeAdminPassword : null),
        _adminAction('修改设备名称', Icons.edit, isAdmin ? _changeDeviceName : null),
        _adminAction('生成临时借车密码', Icons.key, isAdmin ? _generateBorrowCode : null),
        _adminAction('授权状态切换', Icons.verified_user, isAdmin ? _toggleAuthorization : null),
        _adminAction('重新同步时间（诊断）', Icons.sync, isAdmin && _connected ? _syncTimeAutomatically : null),
        const SizedBox(height: 10),
        const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('不保存长期操作记录/错误记录，避免无止境累积。时间、密码、设备名称、授权状态和临时密码属于需要保存的设备状态。'))),
      ],
    );
  }

  Widget _adminAction(String title, IconData icon, VoidCallback? action) {
    final enabled = action != null;
    return Card(
      child: ListTile(
        leading: Icon(icon, color: enabled ? const Color(0xFF19D36B) : Colors.grey),
        title: Text(title, style: TextStyle(color: enabled ? Colors.white : Colors.grey)),
        trailing: const Icon(Icons.chevron_right),
        onTap: action,
      ),
    );
  }

  Widget _connectionPage() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text('蓝牙连接流程模拟', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _flowStep('1', 'APP打开', true),
        _flowStep('2', '点击蓝牙开始扫描', _scanning || _found || _connected),
        _flowStep('3', '发现：$_deviceNameValue', _found || _connected),
        _flowStep('4', '点击连接 → 请选择登录模式', _mode != null || _connected),
        _flowStep('5', '输入管理员密码 / 临时借车密码', _mode != null || _connected),
        _flowStep('6', 'BLE连接建立，与ESP32连接成功', _connected),
        _flowStep('7', '连接后自动同步时间', _timeSynced),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Text(
          _connected
              ? '当前：${_mode == AccessMode.admin ? '管理员模式，全部权限' : '临时借车模式，仅车辆控制'}'
              : '当前未建立连接。',
        ))),
        if (_connected) FilledButton.icon(onPressed: _disconnect, icon: const Icon(Icons.bluetooth_disabled), label: const Text('断开蓝牙')),
      ],
    );
  }

  Widget _flowStep(String number, String text, bool done) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: done ? const Color(0xFF19D36B) : Colors.grey,
          child: Text(number, style: const TextStyle(color: Colors.black)),
        ),
        title: Text(text),
        trailing: done ? const Icon(Icons.check, color: Color(0xFF19D36B)) : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = <Widget>[
      _homePage(),
      _connectionPage(),
      _borrowPage(),
      _adminPage(),
      _settingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tian Key V11'),
        actions: [
          Icon(_connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: _connected ? const Color(0xFF19D36B) : Colors.grey),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(child: pages[_page]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _page,
        onDestinationSelected: (index) => setState(() => _page = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.directions_car), label: '车辆'),
          NavigationDestination(icon: Icon(Icons.bluetooth), label: '蓝牙'),
          NavigationDestination(icon: Icon(Icons.vpn_key), label: '借车'),
          NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: '管理'),
          NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
