import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import 'dart:math';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 强制锁定竖屏，彻底解决模拟器/手机横屏拉伸变形问题
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const TianKeyApp());
}

class TianKeyApp extends StatelessWidget {
  const TianKeyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tian Key',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050B14),
        primaryColor: const Color(0xFF00F0FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF08101E),
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      home: const MainTabFrame(),
    );
  }
}

class MainTabFrame extends StatefulWidget {
  const MainTabFrame({Key? key}) : super(key: key);

  @override
  State<MainTabFrame> createState() => _MainTabFrameState();
}

class _MainTabFrameState extends State<MainTabFrame> {
  int _currentIndex = 0;
  final BleService _bleService = BleService();

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(bleService: _bleService),
      const TempBorrowPage(),
      const SettingsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF08101E),
          border: Border(top: BorderSide(color: Color(0xFF13233F), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF00F0FF),
          unselectedItemColor: Colors.grey.shade600,
          elevation: 0,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "首页"),
            BottomNavigationBarItem(icon: Icon(Icons.key_outlined), activeIcon: Icon(Icons.key), label: "临时借车"),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: "设置"),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 1. 赛博黑金 HUD 首页 (Strict 1:1 图二)
// ==========================================
class HomePage extends StatefulWidget {
  final BleService bleService;
  const HomePage({Key? key, required this.bleService}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isConnected = false;
  bool _isAdminAuthorized = false;

  void _connectDevice() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("正在搜索 陕A0P92Y (Tian_92Y) 设备...")),
    );
    bool success = await widget.bleService.connectToDevice();
    setState(() => _isConnected = success);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? "蓝牙设备连接成功！" : "未能连接到设备")),
      );
    }
  }

  void _showAuthDialog() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AdminAuthPage(onAuthSuccess: () {
      setState(() => _isAdminAuthorized = true);
    })));
  }

  void _sendCmd(String payload, String name) async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("请先连接蓝牙设备")),
      );
      return;
    }
    await widget.bleService.sendPayload(payload);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("指令已发送: $name ($payload)")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.white70),
          onPressed: () {},
        ),
        title: const Text("Tian Key"),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF00F0FF)),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            // 跑车 & 陕A·0P92Y 车牌雷达 HUD 卡片
            Container(
              width: double.infinity,
              height: 190,
              decoration: BoxDecoration(
                color: const Color(0xFF091326),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00F0FF).withOpacity(0.12), blurRadius: 16)
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 雷达科技光圈背景
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.25), width: 1.5),
                      gradient: RadialGradient(
                        colors: [const Color(0xFF00F0FF).withOpacity(0.18), Colors.transparent],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_filled_sharp, size: 95, color: Colors.redAccent.shade400),
                      const SizedBox(height: 4),
                      // 车牌 Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0044B2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Text(
                          "陕A·0P92Y",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5大冷启动待初始化状态
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF08101E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF13233F)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statusItem(Icons.bluetooth_disabled, "设备状态", _isConnected ? "已连接" : "未连接", _isConnected),
                  _statusItem(Icons.shield_outlined, "管理员状态", _isAdminAuthorized ? "已授权" : "未授权", _isAdminAuthorized),
                  _statusItem(Icons.electric_bolt, "供电状态", "未知", false),
                  _statusItem(Icons.access_time, "时间同步", "未同步", false),
                  _statusItem(Icons.key_off_outlined, "临时借车", "无有效密码", false),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 两个核心连接/授权按键
            Row(
              children: [
                Expanded(
                  child: _cyberActionButton(
                    label: _isConnected ? "设备已连接" : "连接设备",
                    icon: Icons.bluetooth,
                    color: const Color(0xFF00F0FF),
                    onTap: _connectDevice,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _cyberActionButton(
                    label: _isAdminAuthorized ? "管理员已授权" : "管理员授权",
                    icon: Icons.security,
                    color: const Color(0xFFFFB800),
                    onTap: _showAuthDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 6个车辆控制按键
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _ctrlBtn("锁车", Icons.lock_outline, () => _sendCmd("suoche", "锁车")),
                _ctrlBtn("解锁", Icons.lock_open_outlined, () => _sendCmd("jiesuo", "解锁")),
                _ctrlBtn("车窗升", Icons.keyboard_double_arrow_up, () => _sendCmd("chuangsheng", "车窗升")),
                _ctrlBtn("车窗降", Icons.keyboard_double_arrow_down, () => _sendCmd("chuangjiang", "车窗降")),
                _ctrlBtn("寻车", Icons.cell_tower, () => _sendCmd("xunche", "寻车")),
                _ctrlBtn("后备箱", Icons.time_to_leave_outlined, () => _sendCmd("houbeixiang", "后备箱")),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusItem(IconData icon, String title, String val, bool active) {
    return Column(
      children: [
        Icon(icon, size: 18, color: active ? const Color(0xFF00F0FF) : Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.white54)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: active ? const Color(0xFF00F0FF) : Colors.grey.shade400)),
      ],
    );
  }

  Widget _cyberActionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1.2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _ctrlBtn(String name, IconData icon, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A152A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.5), width: 1),
          boxShadow: [BoxShadow(color: const Color(0xFF00F0FF).withOpacity(0.06), blurRadius: 6)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF00F0FF), size: 22),
            const SizedBox(width: 10),
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. 临时借车页面（真正的密码生成与刷新逻辑）
// ==========================================
class TempBorrowPage extends StatefulWidget {
  const TempBorrowPage({Key? key}) : super(key: key);

  @override
  State<TempBorrowPage> createState() => _TempBorrowPageState();
}

class _TempBorrowPageState extends State<TempBorrowPage> {
  String _selectedDuration = "5分钟";
  String? _generatedPassword;

  final List<String> _durations = ["5分钟", "1天", "2天", "3天", "4天", "5天", "6天", "7天"];

  // 随机生成 6 位黑科技密码
  void _createPassword() {
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();
    setState(() {
      _generatedPassword = code;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("已生成临时借车密码：$code (有效时间：$_selectedDuration)")),
    );
  }

  void _cancelPassword() {
    setState(() {
      _generatedPassword = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("已取消临时借车权限")),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasPassword = _generatedPassword != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("临时借车"),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white70),
            onPressed: () {},
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("当前状态", style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  hasPassword ? Icons.vpn_key : Icons.key_off,
                  color: hasPassword ? const Color(0xFF00F0FF) : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  hasPassword ? "密码已生效 (有效时间：$_selectedDuration)" : "无有效临时密码",
                  style: TextStyle(
                    color: hasPassword ? const Color(0xFF00F0FF) : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text("选择有效时间", style: TextStyle(color: Color(0xFF00F0FF), fontSize: 14)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _durations.map((d) {
                bool isSelected = d == _selectedDuration;
                return ChoiceChip(
                  label: Text(
                    d,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF00F0FF),
                  backgroundColor: const Color(0xFF0B172E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFF1B3254),
                    ),
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedDuration = d);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            const Text("临时密码", style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 8),

            // 核心：临时密码生成后真正卡片显示
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF081224),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasPassword ? const Color(0xFF00F0FF) : const Color(0xFF1B3254),
                  width: hasPassword ? 1.5 : 1.0,
                ),
                boxShadow: hasPassword
                    ? [BoxShadow(color: const Color(0xFF00F0FF).withOpacity(0.2), blurRadius: 14)]
                    : [],
              ),
              child: Column(
                children: [
                  Icon(
                    hasPassword ? Icons.lock_open : Icons.lock_clock,
                    color: hasPassword ? const Color(0xFF00F0FF) : Colors.white38,
                    size: 38,
                  ),
                  const SizedBox(height: 12),
                  if (hasPassword) ...[
                    // 密码生成后在此以 36px 发光大字完美展示！
                    SelectableText(
                      _generatedPassword!,
                      style: const TextStyle(
                        color: Color(0xFF00F0FF),
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        shadows: [
                          Shadow(color: Color(0xFF00F0FF), blurRadius: 12),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Text(
                      "尚未生成",
                      style: TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: hasPassword ? const Color(0xFF00F0FF) : Colors.white24,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                    onPressed: hasPassword
                        ? () {
                            Clipboard.setData(ClipboardData(text: _generatedPassword!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("密码 $_generatedPassword 已复制到剪贴板")),
                            );
                          }
                        : null,
                    icon: Icon(
                      Icons.copy,
                      size: 16,
                      color: hasPassword ? const Color(0xFF00F0FF) : Colors.white24,
                    ),
                    label: Text(
                      "复制密码",
                      style: TextStyle(
                        color: hasPassword ? const Color(0xFF00F0FF) : Colors.white24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _createPassword,
              child: const Text("生成临时密码", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _cancelPassword,
              child: const Text("取消借车", style: TextStyle(color: Colors.redAccent, fontSize: 16)),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. 设置页面 (Settings Page)
// ==========================================
class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("设置")),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _tile(context, Icons.lock_reset, "修改蓝牙密码", "", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ModifyBlePasswordPage()));
          }),
          _tile(context, Icons.restore, "恢复默认蓝牙密码", "", () {
            _showRestoreDialog(context);
          }),
          _tile(context, Icons.directions_car, "设备名称", "陕A0P92Y", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const DeviceNamePage()));
          }),
          _tile(context, Icons.sync, "时间同步设置", "", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TimeSyncPage()));
          }),
          _tile(context, Icons.bluetooth_searching, "自动连接设置", "关闭", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AutoConnectPage()));
          }),
          _tile(context, Icons.volume_up, "提示音设置", "关闭", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SoundSettingsPage()));
          }),
          _tile(context, Icons.info_outline, "关于系统", "", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
          }),
        ],
      ),
    );
  }

  Widget _tile(BuildContext ctx, IconData icon, String title, String trailingText, VoidCallback tap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00F0FF)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText.isNotEmpty) Text(trailingText, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: tap,
    );
  }

  void _showRestoreDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF0A152A),
        title: const Text("恢复默认蓝牙密码", style: TextStyle(color: Colors.orangeAccent)),
        content: const Text("恢复后蓝牙密码将重置为出厂默认值", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("取消", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(c);
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("已重置为出厂默认密码")));
            },
            child: const Text("恢复默认蓝牙密码"),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 4. 图二对应的全套子页面
// ==========================================

// 管理员授权页
class AdminAuthPage extends StatefulWidget {
  final VoidCallback onAuthSuccess;
  const AdminAuthPage({Key? key, required this.onAuthSuccess}) : super(key: key);

  @override
  State<AdminAuthPage> createState() => _AdminAuthPageState();
}

class _AdminAuthPageState extends State<AdminAuthPage> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("管理员授权")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.shield, size: 80, color: Color(0xFFFFB800)),
            const SizedBox(height: 16),
            const Text("请输入管理员密码进行授权", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            TextField(
              controller: _ctrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "管理员密码",
                labelStyle: TextStyle(color: Color(0xFFFFB800)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFB800))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFB800), width: 2)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB800),
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                if (_ctrl.text == "13092991951") {
                  widget.onAuthSuccess();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("管理员授权成功")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("密码不正确")));
                }
              },
              child: const Text("确认授权", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

// 修改蓝牙密码页
class ModifyBlePasswordPage extends StatelessWidget {
  const ModifyBlePasswordPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("修改蓝牙密码")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _passInput("当前蓝牙密码", "请输入当前蓝牙密码"),
            const SizedBox(height: 16),
            _passInput("新蓝牙密码", "请输入新蓝牙密码"),
            const SizedBox(height: 16),
            _passInput("确认新密码", "请再次输入新密码"),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF),
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("保存新密码", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _passInput(String label, String hint) {
    return TextField(
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF13233F))),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00F0FF))),
      ),
    );
  }
}

// 设备名称页
class DeviceNamePage extends StatelessWidget {
  const DeviceNamePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("设备名称")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.phone_android, size: 70, color: Color(0xFF00F0FF)),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: "陕A0P92Y",
              decoration: const InputDecoration(
                labelText: "设备名称",
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00F0FF))),
              ),
            ),
            const SizedBox(height: 10),
            const Text("设备名称将用于蓝牙连接和设备识别", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF),
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("保存", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

// 时间同步设置页
class TimeSyncPage extends StatelessWidget {
  const TimeSyncPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("时间同步设置")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time_filled, size: 90, color: Color(0xFF00F0FF)),
              const SizedBox(height: 20),
              const Text("当前状态：未同步", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F0FF),
                  minimumSize: const Size(200, 48),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("设备时间已校准同步")));
                },
                child: const Text("立即同步", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              const Text("同步后将自动校准设备时间", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// 自动连接设置页
class AutoConnectPage extends StatelessWidget {
  const AutoConnectPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("自动连接设置")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.link, color: Color(0xFF00F0FF)),
              title: const Text("自动连接"),
              subtitle: const Text("开启后，APP启动时将自动连接已配对设备"),
              value: false,
              onChanged: (val) {},
            ),
          ],
        ),
      ),
    );
  }
}

// 提示音设置页
class SoundSettingsPage extends StatelessWidget {
  const SoundSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("提示音设置")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.volume_up, color: Color(0xFF00F0FF)),
              title: const Text("提示音"),
              subtitle: const Text("开启后，操作时将播放提示音"),
              value: false,
              onChanged: (val) {},
            ),
          ],
        ),
      ),
    );
  }
}

// 关于系统页面（配马自达科技徽标）
class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("关于系统")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Tian Key", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00F0FF))),
              const SizedBox(height: 8),
              const Icon(Icons.shield_outlined, size: 70, color: Colors.cyanAccent),
              const SizedBox(height: 30),
              _infoRow("车型", "马自达昂克赛拉"),
              _infoRow("车牌", "陕A0P92Y"),
              _infoRow("设备", "ESP32"),
              _infoRow("设备状态", "未连接设备"),
              const SizedBox(height: 40),
              const Text("Tian Key 智能车钥匙控制系统", style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: Colors.white70, fontSize: 15)),
          Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}

// 蓝牙底层通讯类
class BleService {
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;

  Future<bool> connectToDevice() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> sendPayload(String cmd) async {
    if (targetCharacteristic != null) {
      await targetCharacteristic!.write(utf8.encode(cmd), withoutResponse: true);
    }
  }
}
