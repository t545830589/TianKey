import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';

void main() {
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
        scaffoldBackgroundColor: const Color(0xFF070A10),
        primaryColor: Colors.cyanAccent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B132B),
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const MainTabFrame(),
    );
  }
}

// 三大页面底部导航框架
class MainTabFrame extends StatefulWidget {
  const MainTabFrame({Key? key}) : super(key: key);

  @override
  State<MainTabFrame> createState() => _MainTabFrameState();
}

class _MainTabFrameState extends State<MainTabFrame> {
  int _currentIndex = 0;

  // 蓝牙通信服务单例
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF0B132B),
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "首页"),
          BottomNavigationBarItem(icon: Icon(Icons.key), label: "临时借车"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "设置"),
        ],
      ),
    );
  }
}

// ==========================================
// 1. 首页 (Home Page)
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
      const SnackBar(content: Text("正在搜索 Tian_92Y 设备...")),
    );
    bool success = await widget.bleService.connectToDevice();
    setState(() {
      _isConnected = success;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? "设备连接成功！" : "未能连接到设备")),
      );
    }
  }

  void _showAuthDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101E36),
        title: const Text("管理员授权", style: TextStyle(color: Colors.cyanAccent)),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "请输入管理员密码",
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("取消", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            onPressed: () {
              // 验证管理员密码
              if (controller.text == "13092991951") {
                setState(() => _isAdminAuthorized = true);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("管理员授权成功")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("密码错误")),
                );
              }
            },
            child: const Text("确认授权"),
          ),
        ],
      ),
    );
  }

  void _sendCmd(String payload, String name) async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("请先连接设备")),
      );
      return;
    }
    await widget.bleService.sendPayload(payload);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("指令发送: $name")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tian Key")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 汽车车牌与展示区
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyanAccent),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text("陕A0P92Y", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
            ),
            const SizedBox(height: 12),
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF101E36),
              ),
              child: const Center(
                child: Icon(Icons.directions_car, size: 90, color: Colors.redAccent),
              ),
            ),
            const SizedBox(height: 16),

            // 5大初始化冷状态 (未连接、未授权、未知、未同步、无有效密码)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statusTile("设备状态", _isConnected ? "已连接" : "未连接", _isConnected),
                _statusTile("管理员状态", _isAdminAuthorized ? "已授权" : "未授权", _isAdminAuthorized),
                _statusTile("供电状态", "未知", false),
                _statusTile("时间同步", "未同步", false),
                _statusTile("临时借车", "无有效密码", false),
              ],
            ),
            const SizedBox(height: 20),

            // 顶部连接与授权按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isConnected ? Colors.cyan.withOpacity(0.3) : const Color(0xFF1C2541),
                      side: const BorderSide(color: Colors.cyanAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _connectDevice,
                    icon: const Icon(Icons.bluetooth, color: Colors.cyanAccent),
                    label: Text(_isConnected ? "设备已连接" : "连接设备", style: const TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAdminAuthorized ? Colors.amber.withOpacity(0.3) : const Color(0xFF1C2541),
                      side: const BorderSide(color: Colors.amber),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _showAuthDialog,
                    icon: const Icon(Icons.security, color: Colors.amber),
                    label: Text(_isAdminAuthorized ? "管理员已授权" : "管理员授权", style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 6个车辆控制发光按键
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _btn("锁车", Icons.lock, () => _sendCmd("suoche", "锁车")),
                _btn("解锁", Icons.lock_open, () => _sendCmd("jiesuo", "解锁")),
                _btn("车窗升", Icons.arrow_upward, () => _sendCmd("chuangsheng", "车窗升")),
                _btn("车窗降", Icons.arrow_downward, () => _sendCmd("chuangjiang", "车窗降")),
                _btn("寻车", Icons.volume_up, () => _sendCmd("xunche", "寻车")),
                _btn("后备箱", Icons.time_to_leave, () => _sendCmd("houbeixiang", "后备箱")),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusTile(String title, String val, bool active) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: active ? Colors.cyanAccent : Colors.grey)),
      ],
    );
  }

  Widget _btn(String name, IconData icon, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          border: Border.all(color: Colors.cyan.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.1), blurRadius: 6)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.cyanAccent, size: 20),
            const SizedBox(width: 8),
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. 临时借车页面 (Temp Borrow Page)
// ==========================================
class TempBorrowPage extends StatefulWidget {
  const TempBorrowPage({Key? key}) : super(key: key);

  @override
  State<TempBorrowPage> createState() => _TempBorrowPageState();
}

class _TempBorrowPageState extends State<TempBorrowPage> {
  String _selectedDuration = "5分钟";
  final List<String> _durations = ["5分钟", "1天", "2天", "3天", "4天", "5天", "6天", "7天"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("临时借车")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("当前状态：无有效临时密码", style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 20),
            const Text("选择有效时间", style: TextStyle(color: Colors.cyanAccent, fontSize: 14)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _durations.map((d) {
                bool isSelected = d == _selectedDuration;
                return ChoiceChip(
                  label: Text(d, style: TextStyle(color: isSelected ? Colors.black : Colors.white)),
                  selected: isSelected,
                  selectedColor: Colors.cyanAccent,
                  backgroundColor: const Color(0xFF1C2541),
                  onSelected: (val) {
                    if (val) setState(() => _selectedDuration = d);
                  },
                );
              }).toList(),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("已生成有效时间为 $_selectedDuration 的借车权限")),
                );
              },
              child: const Text("生成临时密码", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("临时借车已取消")),
                );
              },
              child: const Text("取消借车", style: TextStyle(color: Colors.redAccent)),
            ),
            const SizedBox(height: 20),
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
        children: [
          ListTile(
            leading: const Icon(Icons.lock_reset, color: Colors.cyanAccent),
            title: const Text("修改蓝牙密码"),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.restore, color: Colors.orangeAccent),
            title: const Text("恢复默认蓝牙密码"),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF101E36),
                  title: const Text("恢复默认蓝牙密码", style: TextStyle(color: Colors.orangeAccent)),
                  content: const Text("恢复后蓝牙密码将重置为出厂默认值", style: TextStyle(color: Colors.white)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("确定")),
                  ],
                ),
              );
            },
          ),
          const ListTile(
            leading: Icon(Icons.directions_car, color: Colors.cyanAccent),
            title: Text("设备名称"),
            trailing: Text("陕A0P92Y", style: TextStyle(color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.sync, color: Colors.cyanAccent),
            title: const Text("时间同步设置"),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {},
          ),
          const SwitchListTile(
            secondary: Icon(Icons.bluetooth_searching, color: Colors.cyanAccent),
            title: Text("自动连接设置"),
            value: false,
            onChanged: null,
          ),
          const SwitchListTile(
            secondary: Icon(Icons.volume_up, color: Colors.cyanAccent),
            title: Text("提示音设置"),
            value: false,
            onChanged: null,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.cyanAccent),
            title: const Text("关于系统"),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
            },
          ),
        ],
      ),
    );
  }
}

// 关于页面
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
            children: const [
              Icon(Icons.shield_outlined, size: 80, color: Colors.cyanAccent),
              SizedBox(height: 16),
              Text("Tian Key", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 24),
              Text("车型：马自达昂克赛拉", style: TextStyle(color: Colors.grey, fontSize: 16)),
              SizedBox(height: 8),
              Text("车牌：陕A0P92Y", style: TextStyle(color: Colors.grey, fontSize: 16)),
              SizedBox(height: 8),
              Text("设备：ESP32", style: TextStyle(color: Colors.grey, fontSize: 16)),
              SizedBox(height: 8),
              Text("状态：未连接设备", style: TextStyle(color: Colors.grey, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

// 蓝牙底层服务封装
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
