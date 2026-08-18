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
        scaffoldBackgroundColor: const Color(0xFF02060D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1595FF),
          secondary: Color(0xFFFF8A1C),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF15160F),
          elevation: 0,
        ),
      ),
      home: const TianKeyHome(),
    );
  }
}

enum PageTab { vehicle, bluetooth, borrow, admin, settings }
enum AccessMode { admin, borrower }

class TianKeyHome extends StatefulWidget {
  const TianKeyHome({super.key});

  @override
  State<TianKeyHome> createState() => _TianKeyHomeState();
}

class _TianKeyHomeState extends State<TianKeyHome> {
  static const defaultPassword = '13092991951';
  static const defaultName = '陕A0P92Y';
  static const phoneId = 'PHONE-TIANKY-01';

  SharedPreferences? prefs;
  PageTab tab = PageTab.vehicle;
  AccessMode? mode;

  bool ready = false;
  bool scanning = false;
  bool found = false;
  bool connecting = false;
  bool connected = false;
  bool authorized = true;
  bool adminSession = false;
  bool autoConnect = true;
  bool sound = true;
  bool locked = true;
  bool timeSynced = false;
  bool timeFail = false;

  String deviceName = defaultName;
  String adminPassword = defaultPassword;
  String? adminDevice;
  String? borrowCode;
  DateTime? borrowStart;
  DateTime? borrowEnd;
  DateTime? espTime;
  String status = '系统待机：车辆功能锁定，请先进行蓝牙扫描';
  String lastCommand = '';
  final List<String> logs = <String>[];

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController hoursController = TextEditingController(text: '2');

  bool get borrowValid {
    if (borrowCode == null || borrowStart == null || borrowEnd == null) return false;
    final now = DateTime.now();
    return now.isAfter(borrowStart!) && now.isBefore(borrowEnd!);
  }

  bool get adminEnabled => connected && mode == AccessMode.admin && adminSession;

  bool get vehicleEnabled => connected && authorized &&
      ((mode == AccessMode.admin && adminSession) ||
          (mode == AccessMode.borrower && borrowValid));

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    passwordController.dispose();
    newPasswordController.dispose();
    nameController.dispose();
    hoursController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    prefs = await SharedPreferences.getInstance();
    final p = prefs!;
    deviceName = p.getString('device_name') ?? defaultName;
    adminPassword = p.getString('admin_password') ?? defaultPassword;
    adminDevice = p.getString('admin_device_id');
    borrowCode = p.getString('borrow_code');
    final start = p.getInt('borrow_start');
    final end = p.getInt('borrow_end');
    borrowStart = start == null ? null : DateTime.fromMillisecondsSinceEpoch(start);
    borrowEnd = end == null ? null : DateTime.fromMillisecondsSinceEpoch(end);
    authorized = p.getBool('authorized') ?? true;
    autoConnect = p.getBool('auto_connect') ?? true;
    sound = p.getBool('sound') ?? true;
    ready = true;
    _log('APP启动');
    if (borrowEnd != null && DateTime.now().isAfter(borrowEnd!)) await _clearBorrow();
    if (mounted) setState(() {});
  }

  void _log(String message) {
    logs.add('${DateTime.now()} $message');
    while (logs.length > 200) logs.removeAt(0);
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> scan() async {
    if (!ready || scanning || connecting || connected) return;
    setState(() {
      scanning = true;
      found = false;
      status = '正在扫描 BLE 设备...';
    });
    _log('BLE扫描开始');
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      scanning = false;
      found = true;
      status = '发现车辆：$deviceName';
    });
    _log('发现 $deviceName');
  }

  Future<void> connect() async {
    if (!found || connecting || connected) return;
    if (autoConnect && authorized && adminDevice == phoneId) {
      await _autoConnect();
      return;
    }
    final selected = await showDialog<AccessMode>(
      context: context,
      builder: (context) => _dialog(
        '选择连接身份',
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _actionButton('管理员连接', Icons.admin_panel_settings, const Color(0xFF1595FF), () => Navigator.pop(context, AccessMode.admin)),
            const SizedBox(height: 10),
            _actionButton('临时借车连接', Icons.key, const Color(0xFFFF8A1C), () => Navigator.pop(context, AccessMode.borrower)),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    passwordController.clear();
    final ok = await _verify(selected);
    if (!ok || !mounted) return;
    setState(() {
      connecting = true;
      status = '认证成功，正在建立 BLE 连接...';
    });
    _log('认证成功');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    if (selected == AccessMode.admin) {
      adminDevice = phoneId;
      adminSession = true;
      await prefs?.setString('admin_device_id', phoneId);
    }
    setState(() {
      connected = true;
      connecting = false;
      mode = selected;
      timeSynced = false;
      status = 'BLE连接成功，正在自动同步时间...';
    });
    _log('ESP32 BLE连接');
    await syncTime();
  }

  Future<void> _autoConnect() async {
    if (connected || connecting) return;
    setState(() {
      found = true;
      connecting = true;
      status = '发现已授权设备，正在自动认证...';
    });
    _log('自动连接开始');
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      connected = true;
      connecting = false;
      mode = AccessMode.admin;
      adminSession = true;
      timeSynced = false;
      status = '自动认证成功，正在同步时间...';
    });
    _log('自动认证成功');
    await syncTime();
  }

  Future<bool> _verify(AccessMode selected) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _dialog(
        selected == AccessMode.admin ? '管理员密码' : '临时借车密码',
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: passwordController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: _field('请输入密码'),
            ),
            const SizedBox(height: 14),
            _actionButton('验证并连接', Icons.link, const Color(0xFF1595FF), () {
              final value = passwordController.text.trim();
              final ok = selected == AccessMode.admin
                  ? value == adminPassword
                  : borrowValid && value == borrowCode;
              if (ok) {
                Navigator.pop(context, true);
              } else {
                _message('密码错误、授权无效或临时密码已过期');
                _log('认证失败');
              }
            }),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> syncTime() async {
    if (!connected) return;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    if (timeFail) {
      setState(() {
        timeSynced = false;
        espTime = null;
        status = mode == AccessMode.admin
            ? '时间同步失败：管理员仍可正常使用'
            : '时间同步失败：无法确认临时授权有效期';
      });
      _log('ESP32时间同步失败');
      return;
    }
    setState(() {
      timeSynced = true;
      espTime = DateTime.now();
      status = mode == AccessMode.admin
          ? '已连接 · 时间同步成功 · 管理员权限已开放'
          : '已连接 · 时间同步成功 · 临时借车权限已开放';
    });
    _log('ESP32时间同步成功');
  }

  Future<void> disconnect() async {
    setState(() {
      connected = false;
      mode = null;
      adminSession = false;
      timeSynced = false;
      espTime = null;
      status = 'BLE已断开：车辆功能重新锁定';
    });
    _log('BLE断开，安全保护');
    _message('BLE已断开，车辆功能已锁定');
  }

  void vehicleCommand(String command) {
    if (!vehicleEnabled) {
      _message('当前没有车辆控制权限');
      _log('拒绝车辆指令 $command');
      return;
    }
    String protocol;
    String detail;
    int gpio;
    switch (command) {
      case '锁车':
        protocol = 'suoche'; gpio = 12; detail = 'GPIO12 锁车脉冲'; locked = true; break;
      case '解锁':
        protocol = 'jiesuo'; gpio = 13; detail = 'GPIO13 解锁脉冲'; locked = false; break;
      case '寻车':
        protocol = 'xunche'; gpio = 12; detail = 'GPIO12 连续两次锁车脉冲'; break;
      case '升窗':
        protocol = 'chuangsheng'; gpio = 12; detail = 'GPIO12 保持7秒'; break;
      case '降窗':
        protocol = 'chuangjiang'; gpio = 13; detail = 'GPIO13 保持7秒'; break;
      default:
        protocol = 'houbeixiang'; gpio = 14; detail = 'GPIO14 保持7秒';
    }
    lastCommand = '$protocol → GPIO$gpio → $detail';
    setState(() { status = '$command 已发送：$lastCommand'; });
    _log('APP发起 $protocol');
    _log('ESP32收到 $protocol → GPIO$gpio');
    _message('$command\n$detail');
  }

  Future<void> generateBorrowCode() async {
    if (!adminEnabled) return;
    final hours = (int.tryParse(hoursController.text.trim()) ?? 2).clamp(1, 24).toInt();
    final code = (100000 + Random().nextInt(900000)).toString();
    final start = DateTime.now();
    final end = start.add(Duration(hours: hours));
    borrowCode = code; borrowStart = start; borrowEnd = end;
    await prefs?.setString('borrow_code', code);
    await prefs?.setInt('borrow_start', start.millisecondsSinceEpoch);
    await prefs?.setInt('borrow_end', end.millisecondsSinceEpoch);
    _log('生成临时借车密码');
    setState(() { status = '临时借车密码已生成'; });
    _message('临时密码：$code\n有效期：$hours 小时');
  }

  Future<void> _clearBorrow() async {
    borrowCode = null; borrowStart = null; borrowEnd = null;
    await prefs?.remove('borrow_code');
    await prefs?.remove('borrow_start');
    await prefs?.remove('borrow_end');
    if (mounted) setState(() {});
  }

  Future<void> toggleAuthorization() async {
    if (!adminEnabled) return;
    authorized = !authorized;
    await prefs?.setBool('authorized', authorized);
    _log(authorized ? '恢复设备授权' : '关闭设备授权');
    setState(() {
      status = authorized
          ? '授权已恢复：管理员会话仍有效，车辆功能已开放'
          : '授权已关闭：车辆锁定，但管理员会话保留，可再次打开授权';
    });
  }

  Future<void> changePassword() async {
    if (!adminEnabled) return;
    newPasswordController.clear();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => _dialog(
        '修改管理员/蓝牙密码',
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(controller: newPasswordController, obscureText: true, keyboardType: TextInputType.number, decoration: _field('输入新密码')),
            const SizedBox(height: 12),
            _actionButton('保存到ESP32', Icons.save, const Color(0xFFFF8A1C), () => Navigator.pop(context, true)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final value = newPasswordController.text.trim();
    if (value.length < 6) { _message('密码至少6位'); return; }
    adminPassword = value;
    await prefs?.setString('admin_password', adminPassword);
    _log('管理员密码修改成功');
    setState(() {});
    _message('新密码已生效，旧密码失效');
  }

  Future<void> changeDeviceName() async {
    if (!adminEnabled) return;
    nameController.text = deviceName;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => _dialog(
        '修改设备名称',
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(controller: nameController, decoration: _field('BLE设备名称')),
            const SizedBox(height: 12),
            _actionButton('保存到ESP32', Icons.save, const Color(0xFF1595FF), () => Navigator.pop(context, true)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final value = nameController.text.trim();
    if (value.isEmpty) return;
    deviceName = value;
    await prefs?.setString('device_name', deviceName);
    _log('设备名称修改成功');
    setState(() {});
  }

  Future<void> factoryReset() async {
    if (!adminEnabled) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => _dialog(
        '恢复出厂',
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('清除管理员密码、管理员设备绑定、授权状态和临时借车授权。'),
            const SizedBox(height: 12),
            _actionButton('确认恢复出厂', Icons.delete_forever, const Color(0xFFFF2B1A), () => Navigator.pop(context, true)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await prefs?.clear();
    adminPassword = defaultPassword; adminDevice = null; authorized = true; autoConnect = true; sound = true;
    borrowCode = null; borrowStart = null; borrowEnd = null; connected = false; found = false; mode = null;
    adminSession = false; timeSynced = false;
    _log('恢复出厂');
    setState(() { status = '已恢复未绑定初始状态'; });
    _message('恢复出厂完成，管理员初始密码恢复为13092991951');
  }

  InputDecoration _field(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1595FF))),
    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF8A1C), width: 2)),
  );

  Widget _dialog(String title, Widget child) => Dialog(
    backgroundColor: const Color(0xFF06101D),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFF1595FF))),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Text(title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        const SizedBox(height: 18),
        child,
      ]),
    ),
  );

  Widget _actionButton(String text, IconData icon, Color color, VoidCallback onPressed) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(50)),
    ),
  );

  Widget _panel(Widget child, {Color border = const Color(0xFF1595FF), EdgeInsets padding = const EdgeInsets.all(14)}) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: const Color(0xCC020A14),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: border),
      boxShadow: <BoxShadow>[BoxShadow(color: border.withOpacity(0.28), blurRadius: 14)],
    ),
    child: child,
  );

  Widget _neonButton(String text, IconData icon, VoidCallback? onTap, {bool orange = false}) {
    final color = orange ? const Color(0xFFFF8A1C) : const Color(0xFF1595FF);
    return Opacity(
      opacity: onTap == null ? 0.35 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            color: const Color(0xFF061321),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color, width: 1.5),
            boxShadow: <BoxShadow>[BoxShadow(color: color.withOpacity(0.35), blurRadius: 12)],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Icon(icon, color: color, size: 27),
            const SizedBox(height: 5),
            Text(text, style: const TextStyle(fontSize: 15)),
          ]),
        ),
      ),
    );
  }

  Widget _line(String label, String value, {bool green = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: <Widget>[
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16))),
      Text(value, style: TextStyle(color: green ? const Color(0xFF19D36B) : Colors.white, fontSize: 16)),
    ]),
  );

  Widget vehiclePage() => ListView(
    padding: const EdgeInsets.all(14),
    children: <Widget>[
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(alignment: Alignment.bottomLeft, children: <Widget>[
          Image.asset('assets/home_car_bg.png', width: double.infinity, height: 235, fit: BoxFit.cover),
          Container(width: double.infinity, padding: const EdgeInsets.all(16), color: Colors.black54, child: Text(deviceName, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
        ]),
      ),
      const SizedBox(height: 14),
      _panel(Column(children: <Widget>[
        _line('蓝牙', connected ? '已连接' : '未连接'),
        _line('登录权限', adminEnabled ? '管理员' : (mode == AccessMode.borrower && borrowValid ? '临时借车' : '未授权')),
        _line('时间', timeSynced ? '已同步' : '未同步'),
        _line('授权状态', authorized ? '有效' : '已关闭', green: authorized),
        const SizedBox(height: 6),
        Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
      ])),
      const SizedBox(height: 14),
      Row(children: <Widget>[
        Expanded(child: _actionButton(scanning ? '扫描中...' : '蓝牙扫描', Icons.bluetooth_searching, const Color(0xFFFFC62E), scan)),
        const SizedBox(width: 10),
        Expanded(child: _actionButton(connected ? '断开' : '连接', Icons.link, const Color(0xFF2B2D34), connected ? disconnect : (found ? connect : () {}))),
      ]),
      const SizedBox(height: 18),
      _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        const Text('车辆控制', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Image.asset('assets/home_controls_bg.png', width: double.infinity, height: 100, fit: BoxFit.cover),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: <Widget>[
            _neonButton('锁车', Icons.lock, vehicleEnabled ? () => vehicleCommand('锁车') : null),
            _neonButton('解锁', Icons.lock_open, vehicleEnabled ? () => vehicleCommand('解锁') : null),
            _neonButton('寻车', Icons.directions_car, vehicleEnabled ? () => vehicleCommand('寻车') : null),
            _neonButton('升窗', Icons.keyboard_arrow_up, vehicleEnabled ? () => vehicleCommand('升窗') : null),
            _neonButton('降窗', Icons.keyboard_arrow_down, vehicleEnabled ? () => vehicleCommand('降窗') : null),
            _neonButton('后备箱', Icons.inventory_2, vehicleEnabled ? () => vehicleCommand('后备箱') : null, orange: true),
          ],
        ),
      ])),
      if (lastCommand.isNotEmpty) ...<Widget>[const SizedBox(height: 12), _panel(Text(lastCommand, style: const TextStyle(color: Colors.white70)))],
    ],
  );

  Widget bluetoothPage() => ListView(padding: const EdgeInsets.all(14), children: <Widget>[
    _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      const Text('蓝牙', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _line('设备名称', deviceName), _line('设备ID', 'TIANKEY-AXELA-01'), _line('连接状态', connected ? '已连接' : '未连接'), _line('扫描结果', found ? '发现车辆' : '未发现'),
      const SizedBox(height: 10),
      _actionButton('扫描 BLE', Icons.bluetooth_searching, const Color(0xFFFFC62E), scan),
      const SizedBox(height: 10),
      _actionButton(connected ? '断开连接' : '连接车辆', Icons.link, const Color(0xFF1595FF), connected ? disconnect : (found ? connect : () {})),
    ])),
  ]);

  Widget borrowPage() => ListView(padding: const EdgeInsets.all(14), children: <Widget>[
    _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      const Text('临时借车', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _line('当前密码', borrowValid ? borrowCode! : '无有效密码'),
      _line('有效期', borrowValid ? borrowEnd.toString() : '无'),
      const SizedBox(height: 12),
      TextField(controller: hoursController, keyboardType: TextInputType.number, decoration: _field('有效小时数（1-24）')),
      const SizedBox(height: 12),
      _actionButton('生成临时借车密码', Icons.key, const Color(0xFFFF8A1C), adminEnabled ? generateBorrowCode : () {}),
      const SizedBox(height: 10),
      _actionButton('取消借车授权', Icons.block, const Color(0xFF3A3A40), adminEnabled ? _clearBorrow : () {}),
    ])),
  ]);

  Widget adminPage() => ListView(padding: const EdgeInsets.all(14), children: <Widget>[
    ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset('assets/borrow_page_bg.png', height: 160, width: double.infinity, fit: BoxFit.cover)),
    const SizedBox(height: 12),
    _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      const Text('管理员操作', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(adminEnabled ? '管理员权限已开启：可修改 ESP32 保存信息。' : '请先连接并通过管理员密码认证。'),
      const SizedBox(height: 12),
      _actionButton('修改管理员/蓝牙密码', Icons.password, const Color(0xFF19D36B), adminEnabled ? changePassword : () {}),
      const SizedBox(height: 10),
      _actionButton('修改设备名称', Icons.edit, const Color(0xFF19D36B), adminEnabled ? changeDeviceName : () {}),
      const SizedBox(height: 10),
      _actionButton('生成临时借车密码', Icons.key, const Color(0xFF19D36B), adminEnabled ? generateBorrowCode : () {}),
      const SizedBox(height: 10),
      _actionButton(authorized ? '关闭授权' : '恢复授权', Icons.verified_user, const Color(0xFF19D36B), adminEnabled ? toggleAuthorization : () {}),
      const SizedBox(height: 10),
      _actionButton('重新同步时间', Icons.sync, const Color(0xFF19D36B), adminEnabled ? syncTime : () {}),
      const SizedBox(height: 10),
      _actionButton('恢复出厂', Icons.delete_forever, const Color(0xFFFF2B1A), adminEnabled ? factoryReset : () {}),
      const SizedBox(height: 10),
      _actionButton('查看统一日志', Icons.receipt_long, const Color(0xFF1595FF), showLogs),
    ])),
    const SizedBox(height: 12),
    _panel(const Text('授权关闭不会清除管理员会话；管理员可以再次进入本页恢复授权。', style: TextStyle(color: Colors.white70))),
  ]);

  Widget settingsPage() => ListView(padding: const EdgeInsets.all(14), children: <Widget>[
    _panel(ClipRRect(borderRadius: BorderRadius.circular(17), child: Image.asset('assets/settings_page_bg.png', width: double.infinity, height: 180, fit: BoxFit.cover)), padding: EdgeInsets.zero),
    const SizedBox(height: 12),
    _panel(Column(children: <Widget>[
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('自动连接'), subtitle: const Text('已授权管理员设备可自动连接'), value: autoConnect, onChanged: (value) async { autoConnect = value; await prefs?.setBool('auto_connect', value); if (mounted) setState(() {}); }),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('声音反馈'), value: sound, onChanged: (value) async { sound = value; await prefs?.setBool('sound', value); if (mounted) setState(() {}); }),
      ListTile(contentPadding: EdgeInsets.zero, title: const Text('设备名称'), subtitle: Text(deviceName), trailing: IconButton(onPressed: adminEnabled ? changeDeviceName : null, icon: const Icon(Icons.edit))),
      ListTile(contentPadding: EdgeInsets.zero, title: const Text('管理员密码'), subtitle: const Text('已保存，不显示明文'), trailing: IconButton(onPressed: adminEnabled ? changePassword : null, icon: const Icon(Icons.edit))),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('授权状态'), subtitle: Text(authorized ? '有效' : '已关闭'), value: authorized, onChanged: adminEnabled ? (_) => toggleAuthorization() : null),
    ])),
    const SizedBox(height: 12),
    _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      const Text('设备状态', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      _line('设备ID', 'TIANKEY-AXELA-01'),
      _line('管理员席位', adminDevice == null ? '未绑定' : (adminDevice == phoneId ? '当前手机' : '其他手机')),
      _line('时间', espTime?.toString() ?? '未同步'), _line('车辆', locked ? '已锁定' : '已解锁'), _line('日志', '${logs.length}/200'),
    ])),
    const SizedBox(height: 12),
    _actionButton('测试时间同步失败', Icons.warning_amber, const Color(0xFF5A3B15), () { timeFail = !timeFail; _message(timeFail ? '已开启时间同步失败测试' : '已关闭时间同步失败测试'); setState(() {}); }),
  ]);

  Future<void> showLogs() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF050B14),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(children: <Widget>[
          const SizedBox(height: 15),
          const Text('Tian Key 系统日志', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text('APP + ESP32统一日志 · ≤200条 · ≤7天', style: TextStyle(color: Colors.grey)),
          const Divider(),
          Expanded(child: logs.isEmpty ? const Center(child: Text('暂无日志')) : ListView.builder(itemCount: logs.length, itemBuilder: (context, index) => ListTile(dense: true, title: Text(logs[logs.length - 1 - index])))),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final pages = <Widget>[vehiclePage(), bluetoothPage(), borrowPage(), adminPage(), settingsPage()];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tian Key V11', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w400)),
        actions: <Widget>[
          Icon(connected ? Icons.bluetooth : Icons.bluetooth_disabled, color: connected ? const Color(0xFF19D36B) : Colors.grey, size: 28),
          const SizedBox(width: 18),
        ],
      ),
      body: SafeArea(child: pages[tab.index]),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: const Color(0xFF14170F),
          indicatorColor: const Color(0xFF19D36B),
          labelTextStyle: MaterialStatePropertyAll<TextStyle>(const TextStyle(fontWeight: FontWeight.w600)),
        ),
        child: NavigationBar(
          selectedIndex: tab.index,
          onDestinationSelected: (index) => setState(() => tab = PageTab.values[index]),
          destinations: const <NavigationDestination>[
            NavigationDestination(icon: Icon(Icons.directions_car), label: '车辆'),
            NavigationDestination(icon: Icon(Icons.bluetooth), label: '蓝牙'),
            NavigationDestination(icon: Icon(Icons.vpn_key), label: '借车'),
            NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: '管理'),
            NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
          ],
        ),
      ),
    );
  }
}
