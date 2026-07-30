import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const TianKeyApp());
}

class TianKeyApp extends StatelessWidget {
  const TianKeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tian Key',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF030712),
        primaryColor: const Color(0xFF00D2FF),
      ),
      home: const MainContainerScreen(),
    );
  }
}

// 主容器：包含底部导航栏（首页、临时借车、设置）
class MainContainerScreen extends StatefulWidget {
  const MainContainerScreen({super.key});

  @override
  State<MainContainerScreen> createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<MainContainerScreen> {
  int _currentIndex = 0;

  // 全局共享状态
  bool isConnected = false;
  bool isAdmin = false;
  bool timeSynced = false;
  String selectedDuration = "5分钟";
  String? generatedPassword;
  bool autoConnect = false;
  bool promptTone = false;
  String deviceName = "皖A·0P92Y";

  void showToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0A223D),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF00D2FF), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(parentState: this),
      TempKeyScreen(parentState: this),
      SettingsScreen(parentState: this),
    ];

    return Scaffold(
      body: SafeArea(child: screens[_currentIndex]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF050B14),
          border: Border(top: BorderSide(color: Color(0xFF162A45), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF00D2FF),
          unselectedItemColor: Colors.white54,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '首页',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: '临时借车',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: '设置',
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 1. 首页 (Page 1)
// ==========================================
class HomeScreen extends StatelessWidget {
  final _MainContainerScreenState parentState;
  const HomeScreen({super.key, required this.parentState});

  void _sendCommand(BuildContext context, String name, String pin) {
    if (!parentState.isConnected) {
      parentState.showToast("❌ 请先连接蓝牙设备！");
      return;
    }
    parentState.showToast("⚡ 发送【$name】指令 -> GPIO $pin");
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            // 顶部车辆大图卡片
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF071220),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF18385C), width: 1.5),
                boxShadow: const [BoxShadow(color: Color(0x3300D2FF), blurRadius: 10, spreadRadius: 1)],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd?auto=format&fit=crop&w=1000&q=80',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.65), Colors.transparent, Colors.black.withOpacity(0.85)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  const Positioned(top: 8, left: 10, child: Icon(Icons.settings, color: Colors.white, size: 20)),
                  const Positioned(top: 8, right: 10, child: Icon(Icons.help_outline, color: Colors.white, size: 20)),
                  const Positioned(
                    top: 10, left: 0, right: 0,
                    child: Center(
                      child: Text(
                        "Tian Key",
                        style: TextStyle(
                          color: Color(0xFF00D2FF),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          shadows: [Shadow(color: Color(0xFF00D2FF), blurRadius: 12)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12, left: 0, right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B4FB2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Text(
                          parentState.deviceName,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // 状态指示栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusTile("设备状态", Icons.bluetooth, parentState.isConnected ? "已连接" : "未连接", parentState.isConnected ? const Color(0xFF00D2FF) : Colors.white38),
                _buildStatusTile("管理员状态", Icons.shield_outlined, parentState.isAdmin ? "已授权" : "未授权", parentState.isAdmin ? Colors.orangeAccent : Colors.white38),
                _buildStatusTile("供电状态", Icons.bolt, "未知", Colors.white70),
                _buildStatusTile("时间同步", Icons.access_time, parentState.timeSynced ? "已同步" : "未同步", parentState.timeSynced ? const Color(0xFF00D2FF) : Colors.white70),
                _buildStatusTile("临时借车", Icons.key_outlined, parentState.generatedPassword != null ? "有效" : "无有效密码", parentState.generatedPassword != null ? Colors.orangeAccent : Colors.white38),
              ],
            ),
            const SizedBox(height: 12),
            // 功能控制网格
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildCyberButton("连接设备", Icons.bluetooth, const Color(0xFF00D2FF), () => parentState.setState(() => parentState.isConnected = !parentState.isConnected))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildCyberButton("管理员授权", Icons.shield, const Color(0xFFFF8800), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AdminAuthScreen(parentState: parentState)));
                    })),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildCyberButton("锁车", Icons.lock, const Color(0xFF00D2FF), () => _sendCommand(context, "锁车", "4"))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildCyberButton("解锁", Icons.lock_open, const Color(0xFF00D2FF), () => _sendCommand(context, "解锁", "16"))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildCyberButton("车窗升", Icons.keyboard_double_arrow_up, const Color(0xFFFF8800), () => _sendCommand(context, "车窗升", "18"))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildCyberButton("车窗降", Icons.keyboard_double_arrow_down, const Color(0xFFFF8800), () => _sendCommand(context, "车窗降", "19"))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildCyberButton("寻车", Icons.cell_tower, const Color(0xFF00D2FF), () => _sendCommand(context, "寻车", "17"))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildCyberButton("后备箱", Icons.directions_car, const Color(0xFF00D2FF), () => _sendCommand(context, "后备箱", "21"))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTile(String title, IconData icon, String status, Color color) {
    return Container(
      width: 65,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF071220),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF162A45), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 3),
          Text(status, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCyberButton(String title, IconData icon, Color themeColor, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF071526),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: themeColor, width: 1.5),
            boxShadow: [BoxShadow(color: themeColor.withOpacity(0.2), blurRadius: 6, spreadRadius: 0)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: themeColor, size: 22),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. 临时借车界面 (Page 2)
// ==========================================
class TempKeyScreen extends StatelessWidget {
  final _MainContainerScreenState parentState;
  const TempKeyScreen({super.key, required this.parentState});

  @override
  Widget build(BuildContext context) {
    final times = ["5分钟", "1天", "2天", "3天", "4天", "5天", "6天", "7天"];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 24),
              const Text("临时借车", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Icon(Icons.list_alt, color: Colors.white70, size: 22),
            ],
          ),
          const SizedBox(height: 16),
          const Text("当前状态", style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF071220),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF162A45)),
            ),
            child: Row(
              children: [
                const Icon(Icons.key, color: Colors.white54, size: 20),
                const SizedBox(width: 10),
                Text(parentState.generatedPassword == null ? "无有效临时密码" : "有效密码: ${parentState.generatedPassword}", style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text("选择有效时间", style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: times.map((t) {
              final isSelected = parentState.selectedDuration == t;
              return GestureDetector(
                onTap: () => parentState.setState(() => parentState.selectedDuration = t),
                child: Container(
                  width: 78, height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0B3356) : const Color(0xFF071220),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00D2FF), width: isSelected ? 1.5 : 1),
                  ),
                  child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text("临时密码", style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF050E1A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF162A45), width: 1),
            ),
            child: Column(
              children: [
                const Icon(Icons.lock_outline, color: Colors.white38, size: 20),
                const SizedBox(height: 4),
                Text(
                  parentState.generatedPassword ?? "尚未生成",
                  style: TextStyle(color: parentState.generatedPassword != null ? Colors.orangeAccent : Colors.white38, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.copy, color: Colors.white70, size: 14),
                    SizedBox(width: 4),
                    Text("复制密码", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity, height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B4FB2)),
              onPressed: () {
                final randomPwd = (100000 + Random().nextInt(899999)).toString();
                parentState.setState(() => parentState.generatedPassword = randomPwd);
                parentState.showToast("🔑 已成功生成临时密码");
              },
              child: const Text("生成临时密码", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity, height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A0B12)),
              onPressed: () {
                parentState.setState(() => parentState.generatedPassword = null);
                parentState.showToast("已取消临时密码");
              },
              child: const Text("取消借车", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. 设置界面 (Page 3)
// ==========================================
class SettingsScreen extends StatelessWidget {
  final _MainContainerScreenState parentState;
  const SettingsScreen({super.key, required this.parentState});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Text("设置", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildSettingGroup([
                  _buildSettingItem(context, Icons.bluetooth, "修改蓝牙密码", "", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ModifyBtPasswordScreen(parentState: parentState)));
                  }),
                  _buildSettingItem(context, Icons.refresh, "恢复默认蓝牙密码", "", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ResetBtPasswordScreen(parentState: parentState)));
                  }),
                ]),
                const SizedBox(height: 12),
                _buildSettingGroup([
                  _buildSettingItem(context, Icons.phone_android, "设备名称", parentState.deviceName, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => DeviceNameScreen(parentState: parentState)));
                  }),
                  _buildSettingItem(context, Icons.access_time, "时间同步设置", "", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TimeSyncScreen(parentState: parentState)));
                  }),
                  _buildSettingItem(context, Icons.link, "自动连接设置", parentState.autoConnect ? "开启" : "关闭", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AutoConnectScreen(parentState: parentState)));
                  }),
                  _buildSettingItem(context, Icons.volume_up_outlined, "提示音设置", parentState.promptTone ? "开启" : "关闭", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PromptToneScreen(parentState: parentState)));
                  }),
                  _buildSettingItem(context, Icons.info_outline, "关于系统", "", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AboutSystemScreen(parentState: parentState)));
                  }),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF071220), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF162A45))),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem(BuildContext context, IconData icon, String title, String trailingText, VoidCallback onTap) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: const Color(0xFF00D2FF), size: 20),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText.isNotEmpty) Text(trailingText, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
        ],
      ),
      onTap: onTap,
    );
  }
}

// ==========================================
// 4. 管理员授权界面 (Page 4)
// ==========================================
class AdminAuthScreen extends StatelessWidget {
  final _MainContainerScreenState parentState;
  const AdminAuthScreen({super.key, required this.parentState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Text("管理员授权", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.orangeAccent, width: 2), color: const Color(0xFF140D05)),
                child: const Icon(Icons.shield, color: Colors.orangeAccent, size: 60),
              ),
              const SizedBox(height: 20),
              const Text("请输入管理员密码进行授权", style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 20),
              const TextField(
                obscureText: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "管理员密码", labelStyle: TextStyle(color: Colors.orangeAccent),
                  suffixIcon: Icon(Icons.visibility_off, color: Colors.white38),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.orangeAccent)),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B4500)),
                  onPressed: () {
                    parentState.setState(() => parentState.isAdmin = true);
                    parentState.showToast("✅ 已成功获得管理员授权");
                    Navigator.pop(context);
                  },
                  child: const Text("确认授权", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const Spacer(),
              const Text("授权后可使用全部管理功能", style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. 修改蓝牙密码界面 (Page 5)
// ==========================================
class ModifyBtPasswordScreen extends StatelessWidget {
  final _MainContainerScreenState parentState;
  const ModifyBtPasswordScreen({super.key, required this.parentState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Text("修改蓝牙密码", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const TextField(
                obscureText: true, style: TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: "当前蓝牙密码", suffixIcon: Icon(Icons.visibility_off, color: Colors.white38), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00D2FF)))),
              ),
              const SizedBox(height: 12),
              const TextField(
                obscureText: true, style: TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: "新蓝牙密码", suffixIcon: Icon(Icons.visibility_off, color: Colors.white38), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00D2FF)))),
              ),
              const SizedBox(height: 12),
              const TextField(
                obscureText: true, style: TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: "确认新密码", suffixIcon: Icon(Icons.visibility_off, color: Colors.white38), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00D2FF)))),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B4FB2)),
                  onPressed: () {
                    parentState.showToast("保存成功");
                    Navigator.pop(context);
                  },
                  child: const Text("保存新密码", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 6. 恢复默认蓝牙密码界面 (Page 6)
// ==========================================
class ResetBtPasswordScreen extends StatelessWidget {
  final _MainContainerScreenState parentState;
  const ResetBtPasswordScreen({super.key, required this.parentState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Text("恢复默认蓝牙密码", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              const Icon(Icons.autorenew, color: Color(0xFF00D2FF), size: 70),
              const SizedBox(height: 20),
              const Text("恢复后蓝牙密码将重置为\n出厂默认值", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7A0B12)),
                  onPressed: () {
                    parentState.showToast("已恢复出厂蓝牙密码");
                    Navigator.pop(context);
                  },
                  child: const Text("恢复默认蓝牙密码", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 7. 设备名称界面 (Page 7)
// ==========================================
class DeviceNameScreen extends StatefulWidget {
  final _MainContainerScreenState parentState;
  const DeviceNameScreen({super.key, required this.parentState});

  @override
  State<DeviceNameScreen> createState() => _DeviceNameScreenState();
}

class _DeviceNameScreenState extends State<DeviceNameScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.parentState.deviceName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Text("设备名称", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Icon(Icons.phone_android, color: Colors.white54, size: 60),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "设备名称",
                  suffixIcon: Icon(Icons.visibility_off, color: Colors.white38),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00D2FF))),
                ),
              ),
              const SizedBox(height: 10),
              const Align(alignment: Alignment.centerLeft, child: Text("设备名称将用于蓝牙连接和设备识别", style: TextStyle(color: Colors.white38, fontSize: 11))),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B4FB2)),
                  onPressed: () {
                    widget.parentState.setState(() {
                      widget.parentState.deviceName = _controller.text;
                    });
                    widget.parentState.showToast("保存成功");
                    Navigator.pop(context);
                  },
                  child: const Text("保存", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 8. 时间同步设置界面 (Page 8)
// ==========================================
class TimeSyncScreen extends StatelessWidget {
  final _MainContainerScreenState parentState;
  const TimeSyncScreen({super.key, required this.parentState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Text("时间同步设置", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              const Icon(Icons.access_time, color: Colors.white70, size: 70),
              const SizedBox(height: 16),
              Text(parentState.timeSynced ? "当前状态\n已同步" : "当前状态\n未同步", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B4FB2)),
                  onPressed: () {
                    parentState.setState(() => parentState.timeSynced = true);
                    parentState.showToast("⏰ 时间已校准同步");
                    Navigator.pop(context);
                  },
                  child: const Text("立即同步", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              const Text("同步后将自动校准设备时间", style: TextStyle(color: Colors.white38, fontSize: 11)),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 9. 提示音设置界面 (Page 9)
// ==========================================
class PromptToneScreen extends StatefulWidget {
  final _MainContainerScreenState parentState;
  const PromptToneScreen({super.key, required this.parentState});

  @override
  State<PromptToneScreen> createState() => _PromptToneScreenState();
}

class _PromptToneScreenState extends State<PromptToneScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Text("提示音设置", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              const Icon(Icons.volume_up, color: Color(0xFF00D2FF), size: 70),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("提示音", style: TextStyle(color: Colors.white, fontSize: 15)),
                  Switch(
                    value: widget.parentState.promptTone,
                    onChanged: (v) {
                      widget.parentState.setState(() => widget.parentState.promptTone = v);
                      setState(() {});
                    },
                    activeColor: const Color(0xFF00D2FF),
                  ),
                ],
              ),
              const Align(alignment: Alignment.centerLeft, child: Text("开启后，操作时播放提示音", style: TextStyle(color: Colors.white38, fontSize: 11))),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 10. 自动连接设置界面 (Page 10)
// ==========================================
class AutoConnectScreen extends StatefulWidget {
  final _MainContainerScreenState parentState;
  const AutoConnectScreen({super.key, required this.parentState});

  @override
  State<AutoConnectScreen> createState() => _AutoConnectScreenState();
}

class _AutoConnectScreenState extends State<AutoConnectScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Text("自动连接设置", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("自动连接", style: TextStyle(color: Colors.white, fontSize: 15)),
                  Switch(
                    value: widget.parentState.autoConnect,
                    onChanged: (v) {
                      widget.parentState.setState(() => widget.parentState.autoConnect = v);
                      setState(() {});
                    },
                    activeColor: const Color(0xFF00D2FF),
                  ),
                ],
              ),
              const Align(alignment: Alignment.centerLeft, child: Text("开启后，APP启动时将自动连接已配对设备", style: TextStyle(color: Colors.white38, fontSize: 11))),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 11. 关于系统界面 (Page 11)
// ==========================================
class AboutSystemScreen extends StatelessWidget {
  final _MainContainerScreenState parentState;
  const AboutSystemScreen({super.key, required this.parentState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield, color: Color(0xFF00D2FF), size: 60),
                  const SizedBox(height: 10),
                  const Text("Tian Key", style: TextStyle(color: Color(0xFF00D2FF), fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 20),
                  const Text("车型：马自达 阿特兹", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text("车牌：${parentState.deviceName}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const Text("Tian Key 智能车匙控制系统", style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: parentState.isConnected ? Colors.greenAccent : Colors.grey, size: 10),
                      const SizedBox(width: 6),
                      Text(parentState.isConnected ? "已连接设备" : "未连接设备", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
