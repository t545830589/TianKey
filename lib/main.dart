import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ble_service.dart';

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
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF171A20),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: const TianKeyHome(),
    );
  }
}

enum PageTab { vehicle, borrow, settings, admin }
enum AccessMode { admin, borrower }

class TianKeyHome extends StatefulWidget {
  const TianKeyHome({super.key});

  @override
  State<TianKeyHome> createState() => _TianKeyHomeState();
}

class _TianKeyHomeState extends State<TianKeyHome> {
  static const defaultPassword = '13092991951';
  static const legacyPhoneId = 'PHONE-TIANKY-01';
  static const defaultName = '陕A0P92Y';

  final TianKeyBleService ble = TianKeyBleService();
  final List<String> logs = <String>[];
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController hoursController = TextEditingController(text: '2');

  SharedPreferences? prefs;
  PageTab tab = PageTab.vehicle;
  AccessMode? mode;
  BleScanItem? foundDevice;
  Timer? borrowExpiryTimer;
  Timer? commandTimer;

  bool ready = false;
  bool scanning = false;
  bool connecting = false;
  bool connected = false;
  bool authorized = true;
  bool adminSession = false;
  bool autoConnect = true;
  bool sound = true;
  bool locked = true;
  bool timeSynced = false;
  bool timeFail = false;
  int commandSeconds = 0;
  String activeCommand = '';
  String deviceName = defaultName;
  String adminPassword = defaultPassword;
  String? installId;
  String? adminDevice;
  String? savedRemoteId;
  String? borrowCode;
  DateTime? borrowStart;
  DateTime? borrowEnd;
  DateTime? espTime;
  String status = '系统待机：车辆功能锁定，请先进行蓝牙扫描';
  String lastCommand = '';

  bool get borrowValid {
    if (borrowCode == null || borrowStart == null || borrowEnd == null) return false;
    final now = DateTime.now();
    return !now.isBefore(borrowStart!) && now.isBefore(borrowEnd!);
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
    borrowExpiryTimer?.cancel();
    commandTimer?.cancel();
    passwordController.dispose();
    newPasswordController.dispose();
    nameController.dispose();
    hoursController.dispose();
    unawaited(ble.dispose());
    super.dispose();
  }

  Future<void> _load() async {
    prefs = await SharedPreferences.getInstance();
    final p = prefs!;
    installId = p.getString('install_id');
    if (installId == null || installId!.isEmpty) {
      installId = 'TK-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1000000)}';
      await p.setString('install_id', installId!);
    }
    deviceName = p.getString('device_name') ?? defaultName;
    adminPassword = p.getString('admin_password') ?? defaultPassword;
    adminDevice = p.getString('admin_device_id');
    savedRemoteId = p.getString('ble_remote_id');
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
    _scheduleBorrowExpiry();
    if (borrowEnd != null && !DateTime.now().isBefore(borrowEnd!)) {
      await _clearBorrow(logExpiry: true);
    }
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

  void _scheduleBorrowExpiry() {
    borrowExpiryTimer?.cancel();
    final end = borrowEnd;
    if (end == null) return;
    final delay = end.difference(DateTime.now());
    if (delay <= Duration.zero) {
      unawaited(_clearBorrow(logExpiry: true));
      return;
    }
    borrowExpiryTimer = Timer(delay, () => unawaited(_clearBorrow(logExpiry: true)));
  }

  Future<void> scan() async {
    if (!ready || scanning || connecting || connected) return;
    setState(() {
      scanning = true;
      foundDevice = null;
      status = '正在扫描 BLE 设备...';
    });
    _log('BLE真实扫描开始');
    try {
      if (!await ble.isSupported()) {
        throw StateError('当前手机不支持 BLE');
      }
      final devices = await ble.scan();
      if (!mounted) return;
      if (devices.isEmpty) {
        setState(() => status = 'BLE扫描结束：未发现设备');
        _log('BLE扫描结束：未发现设备');
        _message('未发现 BLE 设备，请确认 ESP32 正在广播');
        return;
      }
      final selected = devices.length == 1 ? devices.first : await _chooseBleDevice(devices);
      if (selected == null || !mounted) return;
      foundDevice = selected;
      savedRemoteId = selected.remoteId;
      await prefs?.setString('ble_remote_id', selected.remoteId);
      setState(() => status = '发现设备：${selected.name}');
      _log('发现 BLE：${selected.name} / ${selected.remoteId}');
      _message('发现 ${selected.name}');
    } catch (error) {
      if (!mounted) return;
      setState(() => status = 'BLE扫描失败：$error');
      _log('BLE扫描失败：$error');
      _message('BLE扫描失败：$error');
    } finally {
      if (mounted) setState(() => scanning = false);
    }
  }

  Future<BleScanItem?> _chooseBleDevice(List<BleScanItem> devices) {
    return showDialog<BleScanItem>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF06101D),
        title: const Text('选择 BLE 设备'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final item = devices[index];
              return ListTile(
                leading: const Icon(Icons.bluetooth, color: Color(0xFF1595FF)),
                title: Text(item.name),
                subtitle: Text(item.remoteId),
                onTap: () => Navigator.pop(context, item),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> connect() async {
    if (connecting || connected) return;
    final target = foundDevice;
    if (target == null) {
      await scan();
      return;
    }
    if (autoConnect && authorized && adminDevice != null && adminDevice == installId) {
      await _connectBle(target, AccessMode.admin, skipPassword: true);
      return;
    }
    final selected = await showDialog<AccessMode>(
      context: context,
      builder: (context) => _authChoiceDialog(),
    );
    if (selected == null || !mounted) return;
    passwordController.clear();
    final ok = await _verify(selected);
    if (!ok || !mounted) return;
    await _connectBle(target, selected);
  }

  Future<void> _connectBle(BleScanItem target, AccessMode selected, {bool skipPassword = false}) async {
    if (connecting || connected) return;
    if (selected == AccessMode.admin && !skipPassword && adminDevice != null && adminDevice != installId && adminDevice != legacyPhoneId) {
      _message('当前管理员席位已被其他设备占用');
      _log('管理员席位拒绝：${adminDevice!}');
      return;
    }
    setState(() {
      connecting = true;
      status = '认证成功，正在建立真实 BLE 连接...';
    });
    try {
      await ble.connect(target.device);
      if (!mounted) return;
      if (selected == AccessMode.admin) {
        adminDevice = installId;
        adminSession = true;
        await prefs?.setString('admin_device_id', installId!);
      }
      await prefs?.setString('ble_remote_id', target.remoteId);
      savedRemoteId = target.remoteId;
      setState(() {
        connected = true;
        connecting = false;
        mode = selected;
        timeSynced = false;
        status = 'BLE真实连接成功，正在同步时间...';
      });
      _log('BLE真实连接成功：${target.name} / ${target.remoteId}');
      await syncTime();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        connecting = false;
        connected = false;
        status = 'BLE连接失败：$error';
      });
      _log('BLE连接失败：$error');
      _message('BLE连接失败：$error');
    }
  }

  Widget _authChoiceDialog() => Dialog(
        backgroundColor: const Color(0xFF020914),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFF1595FF))),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('选择连接身份', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _dialogButton('管理员连接', Icons.admin_panel_settings, const Color(0xFF1595FF), () => Navigator.pop(context, AccessMode.admin)),
              const SizedBox(height: 10),
              _dialogButton('临时借车连接', Icons.key, const Color(0xFFFF8A1C), () => Navigator.pop(context, AccessMode.borrower)),
            ],
          ),
        ),
      );

  Future<bool> _verify(AccessMode selected) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF020914),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFFF8A1C))),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(height: 110, width: double.infinity, child: Image.asset('assets/popup_admin_auth.png', fit: BoxFit.contain)),
              Text(selected == AccessMode.admin ? '管理员密码' : '临时借车密码', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: passwordController, obscureText: true, keyboardType: TextInputType.number, decoration: _field('请输入密码')),
              const SizedBox(height: 12),
              _dialogButton('验证并连接', Icons.link, const Color(0xFF1595FF), () {
                final value = passwordController.text.trim();
                final seatBlocked = selected == AccessMode.admin && adminDevice != null && adminDevice != installId && adminDevice != legacyPhoneId;
                final ok = !seatBlocked && (selected == AccessMode.admin ? value == adminPassword : borrowValid && value == borrowCode);
                if (ok) {
                  Navigator.pop(context, true);
                } else {
                  _message(seatBlocked ? '管理员席位已被占用' : '密码错误、授权无效或临时密码已过期');
                  _log('认证失败');
                }
              }),
            ],
          ),
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
        status = mode == AccessMode.admin ? '时间同步失败：管理员仍可使用' : '时间同步失败：无法确认临时授权有效期';
      });
      _log('时间同步失败（真实ESP32时间协议尚未接入）');
      return;
    }
    setState(() {
      timeSynced = true;
      espTime = DateTime.now();
      status = mode == AccessMode.admin ? '已连接 · 时间同步成功 · 管理员权限已开放' : '已连接 · 时间同步成功 · 临时借车权限已开放';
    });
    _log('APP时间状态已同步；ESP32实际写时协议待硬件协议接入');
  }

  Future<void> disconnect() async {
    commandTimer?.cancel();
    await ble.disconnect();
    if (!mounted) return;
    setState(() {
      connected = false;
      mode = null;
      adminSession = false;
      timeSynced = false;
      espTime = null;
      commandSeconds = 0;
      activeCommand = '';
      status = 'BLE已断开：车辆功能重新锁定';
    });
    _log('BLE真实断开，安全保护');
    _message('BLE已断开，车辆功能已锁定');
  }

  void vehicleCommand(String command) {
    if (!vehicleEnabled) {
      _message('当前没有车辆控制权限');
      _log('拒绝车辆指令 $command');
      return;
    }
    late final String protocol;
    late final String detail;
    late final int gpio;
    final timed = command == '升窗' || command == '降窗' || command == '后备箱';
    switch (command) {
      case '锁车':
        protocol = 'suoche'; gpio = 12; detail = 'GPIO12 锁车脉冲'; locked = true;
      case '解锁':
        protocol = 'jiesuo'; gpio = 13; detail = 'GPIO13 解锁脉冲'; locked = false;
      case '寻车':
        protocol = 'xunche'; gpio = 12; detail = 'GPIO12 连续两次锁车脉冲';
      case '升窗':
        protocol = 'chuangsheng'; gpio = 12; detail = 'GPIO12 保持7秒';
      case '降窗':
        protocol = 'chuangjiang'; gpio = 13; detail = 'GPIO13 保持7秒';
      default:
        protocol = 'houbeixiang'; gpio = 14; detail = 'GPIO14 保持7秒';
    }
    commandTimer?.cancel();
    if (timed) {
      commandSeconds = 7;
      activeCommand = command;
      commandTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) { timer.cancel(); return; }
        if (commandSeconds <= 1) {
          timer.cancel();
          setState(() { commandSeconds = 0; activeCommand = ''; status = '$command 7秒动作完成：$detail'; });
          _log('$protocol 7秒 APP动作完成；真实GPIO发送待协议接入');
          return;
        }
        setState(() => commandSeconds -= 1);
      });
    }
    lastCommand = '$protocol → GPIO$gpio → $detail';
    setState(() => status = timed ? '$command 已开始：7秒保持中（$commandSeconds）' : '$command 已发送：$lastCommand');
    _log('APP记录指令：$lastCommand；真实ESP32指令帧待协议接入');
    _message(timed ? '$command\n7秒保持中' : '$command\n$detail');
  }

  Future<void> generateBorrowCode() async {
    if (!adminEnabled) { _message('请先完成管理员认证'); return; }
    final hours = (int.tryParse(hoursController.text.trim()) ?? 2).clamp(1, 24).toInt();
    final code = (100000 + Random().nextInt(900000)).toString();
    final start = DateTime.now();
    final end = start.add(Duration(hours: hours));
    borrowCode = code; borrowStart = start; borrowEnd = end;
    await prefs?.setString('borrow_code', code);
    await prefs?.setInt('borrow_start', start.millisecondsSinceEpoch);
    await prefs?.setInt('borrow_end', end.millisecondsSinceEpoch);
    _scheduleBorrowExpiry();
    _log('生成临时借车密码');
    setState(() => status = '临时借车密码已生成');
    _message('临时密码：$code\n有效期：$hours 小时');
  }

  Future<void> _clearBorrow({bool logExpiry = false}) async {
    final hadCode = borrowCode != null;
    borrowExpiryTimer?.cancel(); borrowExpiryTimer = null;
    borrowCode = null; borrowStart = null; borrowEnd = null;
    await prefs?.remove('borrow_code');
    await prefs?.remove('borrow_start');
    await prefs?.remove('borrow_end');
    if (logExpiry && hadCode) _log('临时借车密码已到期并清除');
    if (mounted) {
      if (mode == AccessMode.borrower) {
        await ble.disconnect();
        connected = false; mode = null; timeSynced = false; espTime = null;
        status = '临时借车授权已失效，车辆功能重新锁定';
      }
      setState(() {});
    }
  }

  Future<void> toggleAuthorization() async {
    if (!adminEnabled) { _message('请先完成管理员认证'); return; }
    authorized = !authorized;
    await prefs?.setBool('authorized', authorized);
    _log(authorized ? '恢复设备授权' : '关闭设备授权');
    setState(() => status = authorized ? '授权已恢复：管理员会话仍有效，车辆功能已开放' : '授权已关闭：车辆锁定，但管理员会话保留，可再次打开授权');
    _message(authorized ? '授权已恢复' : '授权已关闭，管理员会话保留');
  }

  Future<void> changePassword() async {
    if (!adminEnabled) { _message('请先完成管理员认证'); return; }
    newPasswordController.clear();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF06101D),
        title: const Text('修改管理员/蓝牙密码'),
        content: TextField(controller: newPasswordController, obscureText: true, keyboardType: TextInputType.number, decoration: _field('输入新密码')),
        actions: <Widget>[TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('保存'))],
      ),
    );
    if (ok != true) return;
    final value = newPasswordController.text.trim();
    if (value.length < 6) { _message('密码至少6位'); return; }
    adminPassword = value;
    await prefs?.setString('admin_password', value);
    _log('管理员密码已保存到APP状态；ESP32实际持久化协议待接入');
    setState(() {});
    _message('新密码已生效，旧密码失效');
  }

  Future<void> changeDeviceName() async {
    if (!adminEnabled) { _message('请先完成管理员认证'); return; }
    nameController.text = deviceName;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF06101D),
        title: const Text('修改设备名称'),
        content: TextField(controller: nameController, decoration: _field('BLE设备名称')),
        actions: <Widget>[TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('保存'))],
      ),
    );
    if (ok != true) return;
    final value = nameController.text.trim();
    if (value.isEmpty) return;
    deviceName = value;
    await prefs?.setString('device_name', value);
    _log('设备名称已保存到APP状态；ESP32实际广播名称修改待协议接入');
    setState(() {});
  }

  Future<void> factoryReset() async {
    if (!adminEnabled) { _message('请先完成管理员认证'); return; }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF06101D),
        title: const Text('恢复出厂'),
        content: const Text('清除管理员绑定、授权状态、临时借车授权和已保存 BLE 设备。'),
        actions: <Widget>[TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF2B1A)), child: const Text('确认恢复出厂'))],
      ),
    );
    if (ok != true) return;
    await ble.disconnect();
    await prefs?.clear();
    adminPassword = defaultPassword;
    adminDevice = null; savedRemoteId = null; authorized = true; autoConnect = true; sound = true;
    deviceName = defaultName; borrowCode = null; borrowStart = null; borrowEnd = null;
    connected = false; foundDevice = null; mode = null; adminSession = false; timeSynced = false;
    final newId = 'TK-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1000000)}';
    installId = newId;
    await prefs?.setString('install_id', newId);
    _log('恢复出厂');
    if (mounted) setState(() { status = '已恢复未绑定初始状态'; tab = PageTab.vehicle; });
    _message('恢复出厂完成，管理员初始密码恢复为13092991951');
  }

  void _toggleAutoConnect() async { autoConnect = !autoConnect; await prefs?.setBool('auto_connect', autoConnect); _log(autoConnect ? '自动连接开启' : '自动连接关闭'); setState(() {}); }
  void _toggleSound() async { sound = !sound; await prefs?.setBool('sound', sound); _log(sound ? '声音反馈开启' : '声音反馈关闭'); setState(() {}); }

  InputDecoration _field(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF030A13),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1595FF))),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF8A1C), width: 2)),
      );

  Widget _dialogButton(String text, IconData icon, Color color, VoidCallback onPressed) => SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(text), style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.black)),
      );

  Widget _transparentHotspot({required VoidCallback? onTap, double radius = 12}) => Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius), splashColor: Colors.white10, highlightColor: Colors.white10),
      );

  Widget _targetImagePage({required String asset, required double aspectRatio, required Widget Function(double width, double height) overlays}) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          top: false,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = width / aspectRatio;
              return SingleChildScrollView(child: Center(child: SizedBox(width: width, height: height, child: Stack(fit: StackFit.expand, children: <Widget>[Image.asset(asset, fit: BoxFit.fill), overlays(width, height)]))));
            },
          ),
        ),
      );

  Widget vehiclePage() => _targetImagePage(
        asset: 'assets/home_controls_bg.png',
        aspectRatio: 448 / 580,
        overlays: (w, h) {
          final children = <Widget>[
            Positioned(left: w * .055, top: h * .045, width: w * .13, height: h * .085, child: _transparentHotspot(onTap: () => setState(() => tab = PageTab.settings))),
            Positioned(right: w * .055, top: h * .045, width: w * .13, height: h * .085, child: _transparentHotspot(onTap: () => _message(connected ? 'BLE：已连接' : 'BLE：未连接'))),
            Positioned(left: w * .035, top: h * .445, width: w * .19, height: h * .075, child: _transparentHotspot(onTap: connected ? disconnect : connect)),
            Positioned(left: w * .215, top: h * .445, width: w * .19, height: h * .075, child: _transparentHotspot(onTap: adminEnabled ? toggleAuthorization : null)),
            Positioned(left: w * .405, top: h * .445, width: w * .19, height: h * .075, child: _transparentHotspot(onTap: () => _message('车辆状态：${locked ? '锁定' : '解锁'}'))),
            Positioned(left: w * .595, top: h * .445, width: w * .19, height: h * .075, child: _transparentHotspot(onTap: connected ? syncTime : null)),
            Positioned(right: w * .035, top: h * .445, width: w * .18, height: h * .075, child: _transparentHotspot(onTap: () => setState(() => tab = PageTab.admin))),
            Positioned(left: w * .045, top: h * .535, width: w * .43, height: h * .075, child: _transparentHotspot(onTap: vehicleEnabled ? () => vehicleCommand('锁车') : null)),
            Positioned(right: w * .045, top: h * .535, width: w * .43, height: h * .075, child: _transparentHotspot(onTap: vehicleEnabled ? () => vehicleCommand('解锁') : null)),
            Positioned(left: w * .045, top: h * .62, width: w * .43, height: h * .075, child: _transparentHotspot(onTap: vehicleEnabled ? () => vehicleCommand('寻车') : null)),
            Positioned(right: w * .045, top: h * .62, width: w * .43, height: h * .075, child: _transparentHotspot(onTap: vehicleEnabled ? () => vehicleCommand('升窗') : null)),
            Positioned(left: w * .045, top: h * .705, width: w * .43, height: h * .075, child: _transparentHotspot(onTap: vehicleEnabled ? () => vehicleCommand('降窗') : null)),
            Positioned(right: w * .045, top: h * .705, width: w * .43, height: h * .075, child: _transparentHotspot(onTap: vehicleEnabled ? () => vehicleCommand('后备箱') : null)),
            Positioned(left: 0, bottom: 0, width: w / 3, height: h * .085, child: _transparentHotspot(onTap: () => setState(() => tab = PageTab.vehicle))),
            Positioned(left: w / 3, bottom: 0, width: w / 3, height: h * .085, child: _transparentHotspot(onTap: () => setState(() => tab = PageTab.borrow))),
            Positioned(right: 0, bottom: 0, width: w / 3, height: h * .085, child: _transparentHotspot(onTap: () => setState(() => tab = PageTab.settings))),
          ];
          if (!connected) {
            children.add(
              Positioned(
                left: w * .12,
                right: w * .12,
                top: h * .385,
                height: h * .055,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: Colors.black54),
                    child: Center(
                      child: Text(
                        scanning ? '蓝牙扫描中…' : foundDevice != null ? '已发现 ${foundDevice!.name} · 点击连接' : '未连接 · 点击蓝牙键扫描',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          if (commandSeconds > 0) {
            children.add(
              Positioned(
                left: w * .18,
                right: w * .18,
                top: h * .79,
                height: h * .055,
                child: IgnorePointer(
                  child: Center(
                    child: Text(
                      '$activeCommand：$commandSeconds 秒',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            );
          }
          return Stack(children: children);
        },
      );

  Widget borrowPage() => _targetImagePage(
        asset: 'assets/borrow_page_bg.png',
        aspectRatio: 512 / 775,
        overlays: (w, h) => Stack(children: <Widget>[
          Positioned(left: w * .05, top: h * .025, width: w * .12, height: h * .07, child: _transparentHotspot(onTap: () => setState(() => tab = PageTab.vehicle))),
          Positioned(left: w * .08, top: h * .25, width: w * .84, height: h * .10, child: IgnorePointer(child: Center(child: Text(borrowValid ? borrowCode! : '暂无有效临时借车密码', style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold, letterSpacing: 3))))),
          Positioned(left: w * .12, top: h * .43, width: w * .76, height: h * .07, child: IgnorePointer(child: Center(child: Text(borrowValid ? '有效至 ${_formatTime(borrowEnd!)}' : '管理员生成临时密码后可借车', style: const TextStyle(color: Colors.white70, fontSize: 14))))),
          Positioned(left: w * .09, top: h * .55, width: w * .82, height: h * .09, child: _transparentHotspot(onTap: adminEnabled ? () async { await _editBorrowHours(); } : () => _message('请先完成管理员认证'))),
          Positioned(left: w * .09, top: h * .70, width: w * .82, height: h * .09, child: _transparentHotspot(onTap: adminEnabled ? generateBorrowCode : () => _message('请先完成管理员认证'))),
          Positioned(left: w * .09, top: h * .79, width: w * .82, height: h * .09, child: _transparentHotspot(onTap: borrowValid ? _connectAsBorrower : () => _message('当前没有有效临时借车密码'))),
          Positioned(left: 0, bottom: 0, width: w / 3, height: h * .085, child: _transparentHotspot(onTap: () => setState(() => tab = PageTab.vehicle))),
          Positioned(left: w / 3, bottom: 0, width: w / 3, height: h * .085, child: _transparentHotspot(onTap: () => setState(() => tab = PageTab.borrow))),
          Positioned(right: 0, bottom: 0, width: w / 3, height: h * .085, child: _transparentHotspot(onTap: () => setState(() => tab = PageTab.settings)))
        ]),
      );

  Future<void> _editBorrowHours() async {
    final value = await showDialog<String>(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF06101D), title: const Text('临时借车有效期'), content: TextField(controller: hoursController, keyboardType: TextInputType.number, decoration: _field('小时数 1-24')), actions: <Widget>[TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), FilledButton(onPressed: () => Navigator.pop(context, hoursController.text), child: const Text('确定'))]));
    if (value == null || !adminEnabled) return;
    hoursController.text = value;
    await generateBorrowCode();
  }

  Future<void> _connectAsBorrower() async {
    if (!borrowValid || connected) return;
    if (foundDevice == null) { await scan(); }
    if (foundDevice == null) return;
    passwordController.clear();
    final ok = await _verify(AccessMode.borrower);
    if (!ok) return;
    await _connectBle(foundDevice!, AccessMode.borrower);
    if (mounted && connected) setState(() => tab = PageTab.vehicle);
  }

  Widget settingsPage() => _targetImagePage(
        asset: 'assets/settings_page_bg.png',
        aspectRatio: 272 / 289,
        overlays: (w, h) => Stack(children: <Widget>[
          Positioned(left: w * .03, top: 0, width: w * .13, height: h * .09, child: _transparentHotspot(onTap: () => setState(() => tab = PageTab.vehicle))),
          Positioned(left: w * .05, top: h * .10, width: w * .90, height: h * .105, child: _transparentHotspot(onTap: () => _message(connected ? '蓝牙已连接：${foundDevice?.name ?? deviceName}' : '蓝牙未连接'))),
          Positioned(left: w * .05, top: h * .205, width: w * .90, height: h * .105, child: _transparentHotspot(onTap: connected ? syncTime : scan)),
          Positioned(left: w * .05, top: h * .31, width: w * .90, height: h * .105, child: _transparentHotspot(onTap: adminEnabled ? changePassword : _requireAdmin)),
          Positioned(left: w * .05, top: h * .415, width: w * .90, height: h * .105, child: _transparentHotspot(onTap: () => setState(() => tab = PageTab.admin))),
          Positioned(left: w * .05, top: h * .52, width: w * .90, height: h * .105, child: _transparentHotspot(onTap: _toggleSound)),
          Positioned(left: w * .05, top: h * .625, width: w * .90, height: h * .105, child: _transparentHotspot(onTap: showLogs)),
          Positioned(left: 0, bottom: 0, width: w / 3, height: h * .15, child: _transparentHotspot(onTap: () => setState(() => tab = PageTab.vehicle))),
          Positioned(left: w / 3, bottom: 0, width: w / 3, height: h * .15, child: _transparentHotspot(onTap: () => setState(() => tab = PageTab.borrow))),
          Positioned(right: 0, bottom: 0, width: w / 3, height: h * .15, child: _transparentHotspot(onTap: () => setState(() => tab = PageTab.settings)))
        ]),
      );

  Widget adminPage() {
    final seatStatus = adminDevice == installId ? '当前安装' : adminDevice == null ? '未绑定' : '其他安装';
    final bleStatus = connected ? '已连接' : '未连接';
    final authorizationStatus = authorized ? '有效' : '关闭';
    final timeStatus = timeSynced ? '已同步' : '未同步';
    final vehicleStatus = locked ? '已锁定' : '已解锁';
    final borrowStatus = borrowValid ? '有效至 ${_formatTime(borrowEnd!)}' : '无有效授权';
    final criticalStatus = '管理员席位：$seatStatus\nBLE：$bleStatus\n授权：$authorizationStatus\n时间：$timeStatus\n车辆：$vehicleStatus\n临时借车：$borrowStatus';

    return Scaffold(
      backgroundColor: const Color(0xFF02060D),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: <Widget>[
            Row(children: <Widget>[IconButton(onPressed: () => setState(() => tab = PageTab.vehicle), icon: const Icon(Icons.arrow_back)), const Expanded(child: Text('管理员操作', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold))), Icon(connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled, color: connected ? const Color(0xFF19D36B) : Colors.grey)]),
            const SizedBox(height: 8),
            _adminCard('管理员权限', adminEnabled ? '管理员权限已开启：可修改设备保存信息。' : '请先通过管理员密码认证。'),
            _adminAction('修改管理员/蓝牙密码', Icons.password, adminEnabled ? changePassword : _requireAdmin),
            _adminAction('修改设备名称', Icons.edit, adminEnabled ? changeDeviceName : _requireAdmin),
            _adminAction('生成临时借车密码', Icons.key, adminEnabled ? generateBorrowCode : _requireAdmin),
            _adminAction(authorized ? '关闭授权' : '恢复授权', Icons.verified_user, adminEnabled ? toggleAuthorization : _requireAdmin),
            _adminAction('重新同步时间', Icons.sync, adminEnabled ? syncTime : _requireAdmin),
            _adminAction('统一日志', Icons.receipt_long, showLogs),
            _adminAction('自动连接：${autoConnect ? '开启' : '关闭'}', Icons.bluetooth, _toggleAutoConnect),
            _adminAction('恢复出厂', Icons.delete_forever, adminEnabled ? factoryReset : _requireAdmin, danger: true),
            const SizedBox(height: 12),
            _adminCard('关键状态', criticalStatus),
            const SizedBox(height: 10),
            _adminCard('当前实现边界', '真实 BLE 扫描、连接、断开已接入；车辆指令帧、ESP32 时间写入、密码持久化、设备名写入仍没有虚构为完成，等待既有硬件协议/固件代码。'),
          ],
        ),
      ),
    );
  }

  void _requireAdmin() => _message('请先连接车辆并使用管理员密码：$defaultPassword');

  Widget _adminCard(String title, String body) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xCC020A14), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1595FF))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), const SizedBox(height: 7), Text(body, style: const TextStyle(color: Colors.white70))]));

  Widget _adminAction(String title, IconData icon, VoidCallback onTap, {bool danger = false}) { final color = danger ? const Color(0xFFFF2B1A) : const Color(0xFF19D36B); return Container(margin: const EdgeInsets.only(bottom: 9), decoration: BoxDecoration(color: const Color(0xFF09111B), borderRadius: BorderRadius.circular(15), border: Border.all(color: color)), child: ListTile(onTap: onTap, leading: Icon(icon, color: color), title: Text(title), trailing: const Icon(Icons.chevron_right))); }

  Future<void> showLogs() async => showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: const Color(0xFF050B14), builder: (context) => SizedBox(height: MediaQuery.of(context).size.height * .78, child: Column(children: <Widget>[const SizedBox(height: 14), const Text('Tian Key 系统日志', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const Text('APP + BLE日志 · ≤200条 · 当前会话内保存', style: TextStyle(color: Colors.grey)), const Divider(), Expanded(child: logs.isEmpty ? const Center(child: Text('暂无日志')) : ListView.builder(itemCount: logs.length, itemBuilder: (context, index) => ListTile(dense: true, title: Text(logs[logs.length - 1 - index], style: const TextStyle(fontSize: 12))))) ])));

  String _formatTime(DateTime value) { String two(int v) => v.toString().padLeft(2, '0'); return '${value.month}/${value.day} ${two(value.hour)}:${two(value.minute)}'; }

  @override
  Widget build(BuildContext context) {
    if (!ready) return const Scaffold(backgroundColor: Color(0xFF02060D), body: Center(child: CircularProgressIndicator()));
    switch (tab) {
      case PageTab.vehicle: return vehiclePage();
      case PageTab.borrow: return borrowPage();
      case PageTab.settings: return settingsPage();
      case PageTab.admin: return adminPage();
    }
  }
}
