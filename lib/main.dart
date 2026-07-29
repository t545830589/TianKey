import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 强制锁定竖屏，彻底解决横屏拉伸变形问题
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const TianKeyV11App());
}

class TianKeyV11App extends StatelessWidget {
  const TianKeyV11App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tian Key',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050B14), // 深蓝黑赛博底色
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

// 底部 Tab 导航框架
class MainTabFrame extends StatefulWidget {
  const MainTabFrame({Key? key}) : super(key: key);

  @override
  State<MainTabFrame> createState() => _MainTabFrameState();
}

class _MainTabFrameState extends State<MainTabFrame> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    TempBorrowPage(),
    SettingsPage(),
  ];

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
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "首页",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.key_outlined),
              activeIcon: Icon(Icons.key),
              label: "临时借车",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: "设置",
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 1. 首页 (Home Page - 严格冻结版)
// ==========================================
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  void _sendCmd(BuildContext context, String actionName, String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("请先连接蓝牙设备以发送指令: $actionName ($code)"),
        duration: const Duration(seconds: 1),
      ),
    );
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
            // 红色昂克赛拉 HUD 雷达卡片
            Container(
              width: double.infinity,
              height: 185,
              decoration: BoxDecoration(
                color: const Color(0xFF091326),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.35), width: 1.5),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00F0FF).withOpacity(0.12), blurRadius: 16)
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 科技发光雷达背景
                  Container(
                    width: 145,
                    height: 145,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.2), width: 1.5),
                      gradient: RadialGradient(
                        colors: [const Color(0xFF00F0FF).withOpacity(0.15), Colors.transparent],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_filled_sharp, size: 90, color: Colors.redAccent.shade400),
                      const SizedBox(height: 6),
                      // 标准蓝色车牌 陕A·0P92Y
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0044B2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Text(
                          "陕A·0P92Y",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5 大待初始化状态栏 (纯灰色未连接)
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
                  _statusItem(Icons.bluetooth_disabled, "设备状态", "未连接"),
                  _statusItem(Icons.shield_outlined, "管理员状态", "未授权"),
                  _statusItem(Icons.electric_bolt, "供电状态", "未知"),
                  _statusItem(Icons.access_time, "时间同步", "未同步"),
                  _statusItem(Icons.key_off_outlined, "临时借车", "无有效密码"),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 两个核心动作按键
            Row(
              children: [
                Expanded(
                  child: _cyberActionButton(
                    label: "连接设备",
                    icon: Icons.bluetooth,
                    color: const Color(0xFF00F0FF),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("正在搜索设备: 陕A0P92Y...")),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _cyberActionButton(
                    label: "管理员授权",
                    icon: Icons.security,
                    color: const Color(0xFFFFB800),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAuthPage()));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 6 个车辆动作控车按键
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _ctrlBtn("锁车", Icons.lock_outline, () => _sendCmd(context, "锁车", "suoche")),
                _ctrlBtn("解锁", Icons.lock_open_outlined, () => _sendCmd(context, "解锁", "jiesuo")),
                _ctrlBtn("车窗升", Icons.keyboard_double_arrow_up, () => _sendCmd(context, "车窗升", "chuangsheng")),
                _ctrlBtn("车窗降", Icons.keyboard_double_arrow_down, () => _sendCmd(context, "车窗降", "chuangjiang")),
                _ctrlBtn("寻车", Icons.cell_tower, () => _sendCmd(context, "寻车", "xunche")),
                _ctrlBtn("后备箱", Icons.time_to_leave_outlined, () => _sendCmd(context, "后备箱", "houbeixiang")),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusItem(IconData icon, String title, String val) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 10, color: Colors.white54)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
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
          border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.4), width: 1),
          boxShadow: [BoxShadow(color: const Color(0xFF00F0FF).withOpacity(0.05), blurRadius: 6)],
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
            const Row(
              children: [
                Icon(Icons.key_off, color: Colors.grey, size: 20),
                SizedBox(width: 8),
                Text("无有效临时密码", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

            // 未生成密码卡片 (绝对不预填任何临时密码)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF081224),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1B3254), width: 1.0),
              ),
              child: Column(
                children: [
                  const Icon(Icons.lock_clock, color: Colors.white38, size: 38),
                  const SizedBox(height: 12),
                  const Text("尚未生成", style: TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                    onPressed: null, // 未生成时禁用
                    icon: const Icon(Icons.copy, size: 16, color: Colors.white24),
                    label: const Text("复制密码", style: TextStyle(color: Colors.white24)),
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("已选择有效期 $_selectedDuration，请连接设备后生成密码")),
                );
              },
              child: const Text("生成临时密码", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {},
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
// 3. 设置主页 (Settings Page)
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
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RestoreDefaultPasswordPage()));
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
}

// ==========================================
// 4. 管理员授权页面 (Admin Auth)
// ==========================================
class AdminAuthPage extends StatefulWidget {
  const AdminAuthPage({Key? key}) : super(key: key);

  @override
  State<AdminAuthPage> createState() => _AdminAuthPageState();
}

class _AdminAuthPageState extends State<AdminAuthPage> {
  final _adminPassCtrl = TextEditingController(); // 绝对留空，无任何预填文本

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("管理员授权")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFB800).withOpacity(0.1),
                border: Border.all(color: const Color(0xFFFFB800), width: 1.5),
              ),
              child: const Icon(Icons.shield, size: 70, color: Color(0xFFFFB800)),
            ),
            const SizedBox(height: 20),
            const Text("请输入管理员密码进行授权", style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 24),
            TextField(
              controller: _adminPassCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "管理员密码",
                hintText: "请输入管理员密码",
                labelStyle: TextStyle(color: Color(0xFFFFB800)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF13233F))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFB800), width: 1.5)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB800),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (_adminPassCtrl.text.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("授权提交中...")));
                }
              },
              child: const Text("确认授权", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            const Text("授权后可使用全部管理员功能", style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. 修改蓝牙密码页面 (Modify BLE Password)
// ==========================================
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("保存新密码", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
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

// ==========================================
// 6. 恢复默认蓝牙密码页面 (Restore Default Password)
// ==========================================
class RestoreDefaultPasswordPage extends StatelessWidget {
  const RestoreDefaultPasswordPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("恢复默认蓝牙密码")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withOpacity(0.1),
                border: Border.all(color: Colors.redAccent, width: 1.5),
              ),
              child: const Icon(Icons.refresh_rounded, size: 70, color: Colors.redAccent),
            ),
            const SizedBox(height: 24),
            // 严格隐藏默认数字密码
            const Text(
              "恢复后蓝牙密码将重置为出厂默认值",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("已重置为出厂默认状态")));
              },
              child: const Text("恢复默认蓝牙密码", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7. 设备名称页面 (Device Name)
// ==========================================
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
            const SizedBox(height: 20),
            const Icon(Icons.phone_android, size: 70, color: Color(0xFF00F0FF)),
            const SizedBox(height: 24),
            TextFormField(
              initialValue: "陕A0P92Y",
              decoration: const InputDecoration(
                labelText: "设备名称",
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00F0FF))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00F0FF), width: 1.5)),
              ),
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("设备名称将用于蓝牙连接和设备识别", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("保存", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 8. 时间同步设置页面 (Time Sync)
// ==========================================
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
              const Text("当前状态", style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 4),
              const Text("未同步", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F0FF),
                  minimumSize: const Size(200, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("请先连接蓝牙设备以校准时间")));
                },
                child: const Text("立即同步", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
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

// ==========================================
// 自动连接设置页面 (Auto Connect)
// ==========================================
class AutoConnectPage extends StatelessWidget {
  const AutoConnectPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("自动连接设置")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SwitchListTile(
          secondary: const Icon(Icons.link, color: Color(0xFF00F0FF)),
          title: const Text("自动连接"),
          subtitle: const Text("开启后，APP启动时将自动连接已配对设备"),
          value: false,
          onChanged: (val) {},
        ),
      ),
    );
  }
}

// ==========================================
// 提示音设置页面 (Sound Settings)
// ==========================================
class SoundSettingsPage extends StatelessWidget {
  const SoundSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("提示音设置")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SwitchListTile(
          secondary: const Icon(Icons.volume_up, color: Color(0xFF00F0FF)),
          title: const Text("提示音"),
          subtitle: const Text("开启后，操作时将播放提示音"),
          value: false,
          onChanged: (val) {},
        ),
      ),
    );
  }
}

// ==========================================
// 9. 关于系统页面 (About System - 图二全同)
// ==========================================
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
              const Text("Tian Key", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00F0FF), letterSpacing: 1.5)),
              const SizedBox(height: 12),
              const Icon(Icons.shield_outlined, size: 65, color: Colors.cyanAccent),
              const SizedBox(height: 36),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}
