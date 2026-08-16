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

class TianKeyHome extends StatefulWidget {
  const TianKeyHome({super.key});

  @override
  State<TianKeyHome> createState() => _TianKeyHomeState();
}

class _TianKeyHomeState extends State<TianKeyHome> {
  static const deviceName = '陕A0P92Y';
  // Latest value explicitly supplied by the project owner.
  static const adminPassword = '13092991954';

  bool _scanning = false;
  bool _found = false;
  bool _connected = false;
  bool _timeSynced = false;
  bool _adminMode = false;
  bool _busy = false;
  String? _borrowCode;
  DateTime? _borrowExpires;
  String _status = 'APP已打开：车辆功能锁定，先点击蓝牙扫描';

  final _loginPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBorrowCode();
  }

  @override
  void dispose() {
    _loginPassword.dispose();
    super.dispose();
  }

  Future<void> _loadBorrowCode() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString('borrow_code');
    final expiresMs = p.getInt('borrow_expires');
    if (!mounted || code == null || expiresMs == null) return;
    final expires = DateTime.fromMillisecondsSinceEpoch(expiresMs);
    if (DateTime.now().isBefore(expires)) {
      setState(() {
        _borrowCode = code;
        _borrowExpires = expires;
      });
    } else {
      await p.remove('borrow_code');
      await p.remove('borrow_expires');
    }
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _found = false;
      _status = '正在扫描 BLE 设备...';
    });
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _found = true;
      _status = '发现设备：$deviceName';
    });
  }

  Future<void> _connect() async {
    if (!_found || _busy) return;
    final mode = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('请选择登录模式'),
        content: const Text('管理员模式：全部权限\n\n临时借车模式：只有车辆控制权限'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('临时借车模式'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('管理员模式'),
          ),
        ],
      ),
    );
    if (mode == null) return;

    _loginPassword.clear();
    final ok = await _passwordDialog(mode);
    if (!ok || !mounted) return;

    setState(() {
      _busy = true;
      _status = '密码验证通过，正在建立 BLE 连接...';
    });
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    setState(() {
      _connected = true;
      _adminMode = mode;
      _status = 'BLE连接成功，正在自动同步时间...';
    });

    // Every successful BLE connection performs time synchronization automatically.
    await _syncTime();
    if (!mounted) return;
    setState(() => _busy = false);
  }

  Future<bool> _passwordDialog(bool admin) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(admin ? '管理员密码' : '临时借车密码'),
        content: TextField(
          controller: _loginPassword,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '请输入密码',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final value = _loginPassword.text.trim();
              final validAdmin = admin && value == adminPassword;
              final validBorrow = !admin &&
                  _borrowCode != null &&
                  value == _borrowCode &&
                  _borrowExpires != null &&
                  DateTime.now().isBefore(_borrowExpires!);
              if (validAdmin || validBorrow) {
                Navigator.pop(context, true);
              } else {
                _show('密码错误或临时借车密码已失效');
              }
            },
            child: const Text('验证'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _syncTime() async {
    if (!_connected) return;
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _timeSynced = true;
      _status = '已连接 · APP与ESP32时间已自动同步';
    });
  }

  Future<void> _generateBorrowCode() async {
    if (!_adminMode || !_connected) return;
    final code = (100000 + Random().nextInt(900000)).toString();
    final expires = DateTime.now().add(const Duration(hours: 2));
    final p = await SharedPreferences.getInstance();
    await p.setString('borrow_code', code);
    await p.setInt('borrow_expires', expires.millisecondsSinceEpoch);
    setState(() {
      _borrowCode = code;
      _borrowExpires = expires;
      _status = '临时借车密码已生成，后续 BLE 阶段将同步保存到 ESP32';
    });
    _show('临时密码：$code\n有效期：2小时');
  }

  void _vehicleCommand(String command, int gpio, {int seconds = 1, int pulses = 1}) {
    if (!_connected) {
      _show('未连接 ESP32，车辆控制保持灰色');
      return;
    }
    final pulseText = pulses > 1 ? '$pulses次脉冲' : '1次脉冲';
    setState(() => _status = '发送 $command → GPIO $gpio，$pulseText，${seconds}秒');
    _show('已发送：$command\nGPIO：$gpio\n$pulseText\n脉冲时间：${seconds}秒');
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _control(
    String title,
    String command,
    int gpio, {
    int seconds = 1,
    int pulses = 1,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: FilledButton(
          onPressed: _connected
              ? () => _vehicleCommand(
                    command,
                    gpio,
                    seconds: seconds,
                    pulses: pulses,
                  )
              : null,
          style: FilledButton.styleFrom(minimumSize: const Size(0, 62)),
          child: Text(title),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tian Key V11'),
        actions: [
          Icon(
            _connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: _connected ? const Color(0xFF19D36B) : Colors.grey,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Container(
              height: 210,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: AssetImage('assets/home_car_bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _row('设备', _connected ? deviceName : '未连接'),
                    _row(
                      '授权',
                      _connected
                          ? (_adminMode ? '管理员模式' : '临时借车模式')
                          : '未授权',
                    ),
                    _row('时间', _timeSynced ? '已同步' : '未同步'),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
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
                    onPressed: _found && !_connected ? _connect : null,
                    icon: const Icon(Icons.link),
                    label: const Text('连接'),
                  ),
                ),
              ],
            ),
            if (_found)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: const Text(deviceName),
                    subtitle: const Text('BLE设备已发现'),
                    trailing: _connected
                        ? const Icon(Icons.check_circle, color: Color(0xFF19D36B))
                        : const Text('点击连接'),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            const Text(
              '车辆控制',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _control('锁车', 'suoche', 12),
                _control('解锁', 'jiesuo', 13),
                // Real-world find-car action: two lock pulses on GPIO12.
                _control('寻车', 'xunche', 12, pulses: 2),
              ],
            ),
            Row(
              children: [
                _control('升窗', 'chuangsheng', 12, seconds: 7),
                _control('降窗', 'chuangjiang', 13, seconds: 7),
                _control('后备箱', 'houbeixiang', 14, seconds: 7),
              ],
            ),
            const SizedBox(height: 18),
            if (_adminMode && _connected)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '管理员操作',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: _generateBorrowCode,
                        icon: const Icon(Icons.key),
                        label: const Text('生成临时借车密码'),
                      ),
                      if (_borrowCode != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            '当前临时密码：$_borrowCode\n有效至：$_borrowExpires',
                          ),
                        ),
                      const SizedBox(height: 8),
                      const Text('管理员模式可进入后续的密码修改、设备名称、授权状态、时间设置等功能。'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Tian Key V11 · Mazda Axela',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String a, String b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(a, style: const TextStyle(color: Colors.grey))),
          Text(b),
        ],
      ),
    );
  }
}
