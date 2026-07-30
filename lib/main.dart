import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      home: const ElevenPagesSliderScreen(),
    );
  }
}

class ElevenPagesSliderScreen extends StatefulWidget {
  const ElevenPagesSliderScreen({super.key});

  @override
  State<ElevenPagesSliderScreen> createState() => _ElevenPagesSliderScreenState();
}

class _ElevenPagesSliderScreenState extends State<ElevenPagesSliderScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 全局交互状态
  bool isConnected = false;
  bool isAdmin = false;
  bool timeSynced = false;
  String selectedDuration = "5分钟";
  String? generatedPassword;
  bool autoConnect = false;
  bool promptTone = false;

  void _showToast(String message) {
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

  void _sendCommand(String name, String pin) {
    if (!isConnected) {
      _showToast("❌ 请先连接蓝牙设备！");
      return;
    }
    _showToast("⚡ 发送【$name】指令 -> GPIO $pin");
  }

  @override
  Widget build(BuildContext context) {
    // 图中完全对应的 11 个独立页面
    final List<Widget> pages = [
      _buildPage1Home(),
      _buildPage2TempKey(),
      _buildPage3Settings(),
      _buildPage4AdminAuth(),
      _buildPage5ModifyBtPassword(),
      _buildPage6ResetBtPassword(),
      _buildPage7DeviceName(),
      _buildPage8TimeSync(),
      _buildPage9PromptTone(),
      _buildPage10AutoConnect(),
      _buildPage11AboutSystem(),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部滑动指示器标题栏
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: const Color(0xFF050B14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "页码: ${_currentPage + 1} / 11",
                    style: const TextStyle(color: Color(0xFF00D2FF), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Text(
                    "👈 左右滑动切换界面 👉",
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            // 可滑动的 11 页核心视图
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: pages,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 第 1 页：首页 (完整原图 1:1)
  // ==========================================
  Widget _buildPage1Home() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          children: [
            _buildCarHeader(),
            const SizedBox(height: 10),
            _buildStatusHeaderRow(),
            const SizedBox(height: 12),
            _buildControlGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildCarHeader() {
    return Container(
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
          const Positioned(
            top: 8, left: 10,
            child: Icon(Icons.settings, color: Colors.white, size: 20),
          ),
          const Positioned(
            top: 8, right: 10,
            child: Icon(Icons.help_outline, color: Colors.white, size: 20),
          ),
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
                child: const Text(
                  "皖A·0P92Y",
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatusTile("设备状态", Icons.bluetooth, isConnected ? "已连接" : "未连接", isConnected ? const Color(0xFF00D2FF) : Colors.white38),
        _buildStatusTile("管理员状态", Icons.shield_outlined, isAdmin ? "已授权" : "未授权", isAdmin ? Colors.orangeAccent : Colors.white38),
        _buildStatusTile("供电状态", Icons.bolt, "未知", Colors.white70),
        _buildStatusTile("时间同步", Icons.access_time, timeSynced ? "已同步" : "未同步", timeSynced ? const Color(0xFF00D2FF) : Colors.white70),
        _buildStatusTile("临时借车", Icons.key_outlined, generatedPassword != null ? "有效" : "无有效密码", generatedPassword != null ? Colors.orangeAccent : Colors.white38),
      ],
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

  Widget _buildControlGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildCyberButton("连接设备", Icons.bluetooth, const Color(0xFF00D2FF), () => setState(() => isConnected = !isConnected))),
            const SizedBox(width: 10),
            Expanded(child: _buildCyberButton("管理员授权", Icons.shield, const Color(0xFFFF8800), () => _pageController.animateToPage(3, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildCyberButton("锁车", Icons.lock, const Color(0xFF00D2FF), () => _sendCommand("锁车", "4"))),
            const SizedBox(width: 10),
            Expanded(child: _buildCyberButton("解锁", Icons.lock_open, const Color(0xFF00D2FF), () => _sendCommand("解锁", "16"))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildCyberButton("车窗升", Icons.keyboard_double_arrow_up, const Color(0xFFFF8800), () => _sendCommand("车窗升", "18"))),
            const SizedBox(width: 10),
            Expanded(child: _buildCyberButton("车窗降", Icons.keyboard_double_arrow_down, const Color(0xFFFF8800), () => _sendCommand("车窗降", "19"))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildCyberButton("寻车", Icons.cell_tower, const Color(0xFF00D2FF), () => _sendCommand("寻车", "17"))),
            const SizedBox(width: 10),
            Expanded(child: _buildCyberButton("后备箱", Icons.directions_car, const Color(0xFF00D2FF), () => _sendCommand("后备箱", "21"))),
          ],
        ),
      ],
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

  // ==========================================
  // 第 2 页：临时借车
  // ==========================================
  Widget _buildPage2TempKey() {
    final times = ["5分钟", "1天", "2天", "3天", "4天", "5天", "6天", "7天"];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.chevron_left, color: Colors.white, size: 28),
              Text("临时借车", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(Icons.article_outlined, color: Colors.white, size: 22),
            ],
          ),
          const SizedBox(height: 20),
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
                Text(generatedPassword == null ? "无有效临时密码" : "有效密码: $generatedPassword", style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("选择有效时间", style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: times.map((t) {
              final isSelected = selectedDuration == t;
              return GestureDetector(
                onTap: () => setState(() => selectedDuration = t),
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
          const SizedBox(height: 20),
          const Text("临时密码", style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF050E1A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF162A45), width: 1),
            ),
            child: Column(
              children: [
                const Icon(Icons.lock_outline, color: Colors.white38, size: 22),
                const SizedBox(height: 6),
                Text(
                  generatedPassword ?? "尚未生成",
                  style: TextStyle(color: generatedPassword != null ? Colors.orangeAccent : Colors.white38, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity, height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B4FB2)),
              onPressed: () {
                final randomPwd = (100000 + Random().nextInt(899999)).toString();
                setState(() => generatedPassword = randomPwd);
                _showToast("🔑 已成功生成临时密码");
              },
              child: const Text("生成临时密码", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity, height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A0B12)),
              onPressed: () {
                setState(() => generatedPassword = null);
                _showToast("已取消临时密码");
              },
              child: const Text("取消借车", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 第 3 页：设置
  // ==========================================
  Widget _buildPage3Settings() {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.chevron_left, color: Colors.white, size: 28),
              SizedBox(width: 100),
              Text("设置", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildSettingGroup([
                  _buildSettingItem(Icons.bluetooth, "修改蓝牙密码", "", () => _pageController.jumpToPage(4)),
                  _buildSettingItem(Icons.refresh, "恢复默认蓝牙密码", "", () => _pageController.jumpToPage(5)),
                ]),
                const SizedBox(height: 12),
                _buildSettingGroup([
                  _buildSettingItem(Icons.phone_android, "设备名称", "皖A·0P92Y", () => _pageController.jumpToPage(6)),
                  _buildSettingItem(Icons.access_time, "时间同步设置", "", () => _pageController.jumpToPage(7)),
                  _buildSettingItem(Icons.link, "自动连接设置", autoConnect ? "开启" : "关闭", () => _pageController.jumpToPage(9)),
                  _buildSettingItem(Icons.volume_up_outlined, "提示音设置", promptTone ? "开启" : "关闭", () => _pageController.jumpToPage(8)),
                  _buildSettingItem(Icons.info_outline, "关于系统", "", () => _pageController.jumpToPage(10)),
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

  Widget _buildSettingItem(IconData icon, String title, String trailingText, VoidCallback onTap) {
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

  // ==========================================
  // 第 4 页：管理员授权
  // ==========================================
  Widget _buildPage4AdminAuth() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Align(alignment: Alignment.centerLeft, child: Icon(Icons.chevron_left, color: Colors.white, size: 28)),
          const SizedBox(height: 10),
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
                setState(() => isAdmin = true);
                _showToast("✅ 已成功获得管理员授权");
              },
              child: const Text("确认授权", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const Spacer(),
          const Text("授权后可使用全部管理功能", style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  // ==========================================
  // 第 5 页：修改蓝牙密码
  // ==========================================
  Widget _buildPage5ModifyBtPassword() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Align(alignment: Alignment.centerLeft, child: Icon(Icons.chevron_left, color: Colors.white, size: 28)),
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
              onPressed: () => _showToast("保存成功"),
              child: const Text("保存新密码", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 第 6 页：恢复默认蓝牙密码
  // ==========================================
  Widget _buildPage6ResetBtPassword() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Align(alignment: Alignment.centerLeft, child: Icon(Icons.chevron_left, color: Colors.white, size: 28)),
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
              onPressed: () => _showToast("已恢复出厂蓝牙密码"),
              child: const Text("恢复默认蓝牙密码", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ==========================================
  // 第 7 页：设备名称 (改用内部独立组件避开 State 问题)
  // ==========================================
  Widget _buildPage7DeviceName() {
    return const _DeviceNamePageContent();
  }

  // ==========================================
  // 第 8 页：时间同步设置
  // ==========================================
  Widget _buildPage8TimeSync() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Align(alignment: Alignment.centerLeft, child: Icon(Icons.chevron_left, color: Colors.white, size: 28)),
          const Text("时间同步设置", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          const Icon(Icons.access_time, color: Colors.white70, size: 70),
          const SizedBox(height: 16),
          Text(timeSynced ? "当前状态\n已同步" : "当前状态\n未同步", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity, height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B4FB2)),
              onPressed: () {
                setState(() => timeSynced = true);
                _showToast("⏰ 时间已校准同步");
              },
              child: const Text("立即同步", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          const Text("同步后将自动校准设备时间", style: TextStyle(color: Colors.white38, fontSize: 11)),
          const Spacer(),
        ],
      ),
    );
  }

  // ==========================================
  // 第 9 页：提示音设置
  // ==========================================
  Widget _buildPage9PromptTone() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Align(alignment: Alignment.centerLeft, child: Icon(Icons.chevron_left, color: Colors.white, size: 28)),
          const Text("提示音设置", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          const Icon(Icons.volume_up, color: Color(0xFF00D2FF), size: 70),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("提示音", style: TextStyle(color: Colors.white, fontSize: 15)),
              Switch(value: promptTone, onChanged: (v) => setState(() => promptTone = v), activeColor: const Color(0xFF00D2FF)),
            ],
          ),
          const Align(alignment: Alignment.centerLeft, child: Text("开启后，操作时播放提示音", style: TextStyle(color: Colors.white38, fontSize: 11))),
        ],
      ),
    );
  }

  // ==========================================
  // 第 10 页：自动连接设置
  // ==========================================
  Widget _buildPage10AutoConnect() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Align(alignment: Alignment.centerLeft, child: Icon(Icons.chevron_left, color: Colors.white, size: 28)),
          const Text("自动连接设置", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("自动连接", style: TextStyle(color: Colors.white, fontSize: 15)),
              Switch(value: autoConnect, onChanged: (v) => setState(() => autoConnect = v), activeColor: const Color(0xFF00D2FF)),
            ],
          ),
          const Align(alignment: Alignment.centerLeft, child: Text("开启后，APP启动时将自动连接已配对设备", style: TextStyle(color: Colors.white38, fontSize: 11))),
        ],
      ),
    );
  }

  // ==========================================
  // 第 11 页：关于系统
  // ==========================================
  Widget _buildPage11AboutSystem() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shield, color: Color(0xFF00D2FF), size: 60),
          const SizedBox(height: 10),
          const Text("Tian Key", style: TextStyle(color: Color(0xFF00D2FF), fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
          const SizedBox(height: 20),
          const Text("车型：马自达 阿特兹", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const Text("车牌：皖A·0P92Y", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const Text("Tian Key 智能车匙控制系统", style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: isConnected ? Colors.greenAccent : Colors.grey, size: 10),
              const SizedBox(width: 6),
              Text(isConnected ? "已连接设备" : "未连接设备", style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }
}

// 设备名称专用的独立 Stateful 组件（防止编译错误）
class _DeviceNamePageContent extends StatefulWidget {
  const _DeviceNamePageContent();

  @override
  State<_DeviceNamePageContent> createState() => _DeviceNamePageContentState();
}

class _DeviceNamePageContentState extends State<_DeviceNamePageContent> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: "皖A·0P92Y");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Align(alignment: Alignment.centerLeft, child: Icon(Icons.chevron_left, color: Colors.white, size: 28)),
          const Text("设备名称", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Icon(Icons.phone_android, color: Colors.white54, size: 60),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "设备名称",
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("保存成功")));
              },
              child: const Text("保存", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
