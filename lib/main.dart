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
        scaffoldBackgroundColor: const Color(0xFF030710),
        primaryColor: const Color(0xFF00D2FF),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // 全局状态变量
  bool isConnected = false;
  String connectedDeviceName = "未连接";
  bool isAdmin = false;

  // 临时密码状态
  String selectedDuration = "5分钟";
  String? generatedPassword;

  // 提示信息方法
  void _showToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0A2540),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF00D2FF), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 指令发送方法
  void _sendCommand(String name, String pin) {
    if (!isConnected) {
      _showToast("❌ 请先连接蓝牙设备！");
      return;
    }
    _showToast("⚡ 发送【$name】指令 -> GPIO $pin");
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomePage(),
      _buildTempKeyPage(),
      _buildSettingsPage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ==========================================
  // 1. 首页 (精细还原原图布局)
  // ==========================================
  Widget _buildHomePage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          children: [
            // 顶部车头展示框
            _buildCarHeaderSection(),
            const SizedBox(height: 12),

            // 5个顶部微型状态图标栏 (完全对齐原图 Row)
            _buildMicroStatusRow(),
            const SizedBox(height: 14),

            // 8个精细控制按键 (2列 x 4行)
            _buildControlGrid(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // 车头与背景框
  Widget _buildCarHeaderSection() {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF08101C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3A5F), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x3300D2FF), blurRadius: 10, spreadRadius: 1)
        ],
      ),
      child: Stack(
        children: [
          // 汽车背景图片
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://images.unsplash.com/photo-1542282088-72c9c27ed0cd?auto=format&fit=crop&w=1000&q=80',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // 暗色渐变罩层
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                  Colors.black.withOpacity(0.85)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // 顶部设置图标
          Positioned(
            top: 8,
            left: 10,
            child: GestureDetector(
              onTap: () => setState(() => _currentIndex = 2),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.settings, color: Colors.white, size: 20),
              ),
            ),
          ),
          // 顶部 Help 图标
          Positioned(
            top: 8,
            right: 10,
            child: GestureDetector(
              onTap: _showAboutDialog,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help_outline, color: Colors.white, size: 20),
              ),
            ),
          ),
          // 顶部标题
          const Positioned(
            top: 12,
            left: 0,
            right: 0,
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
          // 车牌号
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5个顶部正方形小图标状态栏 (完全按照原图 Row 1 设计)
  Widget _buildMicroStatusRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMicroStatusTile(Icons.bluetooth, isConnected ? const Color(0xFF00D2FF) : Colors.white38),
        _buildMicroStatusTile(Icons.shield_outlined, isAdmin ? Colors.orangeAccent : Colors.white38),
        _buildMicroStatusTile(Icons.bolt, const Color(0xFF00D2FF)),
        _buildMicroStatusTile(Icons.access_time, Colors.white70),
        _buildMicroStatusTile(Icons.vpn_key_outlined, generatedPassword != null ? Colors.orangeAccent : Colors.white38),
      ],
    );
  }

  Widget _buildMicroStatusTile(IconData icon, Color color) {
    return Container(
      width: 62,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF071220),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF162A45), width: 1.2),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  // 8大科技感控制器按键网格 (2列 x 4行)
  Widget _buildControlGrid() {
    return Column(
      children: [
        // Row 1: 蓝牙连接 / 管理员授权
        Row(
          children: [
            Expanded(
              child: _buildCyberButton(
                icon: Icons.bluetooth,
                glowColor: const Color(0xFF00D2FF),
                onTap: _showBluetoothSearchDialog,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCyberButton(
                icon: Icons.shield,
                glowColor: const Color(0xFFFF8800),
                onTap: _showAdminAuthDialog,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row 2: 锁车 / 解锁
        Row(
          children: [
            Expanded(
              child: _buildCyberButton(
                icon: Icons.lock,
                glowColor: const Color(0xFF00D2FF),
                onTap: () => _sendCommand("锁车", "4"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCyberButton(
                icon: Icons.lock_open,
                glowColor: const Color(0xFF00D2FF),
                onTap: () => _sendCommand("解锁", "16"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row 3: 车窗升 / 车窗降
        Row(
          children: [
            Expanded(
              child: _buildCyberButton(
                icon: Icons.keyboard_double_arrow_up,
                glowColor: const Color(0xFFFF8800),
                onTap: () => _sendCommand("车窗升", "18"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCyberButton(
                icon: Icons.keyboard_double_arrow_down,
                glowColor: const Color(0xFFFF8800),
                onTap: () => _sendCommand("车窗降", "19"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row 4: 寻车 / 后备箱
        Row(
          children: [
            Expanded(
              child: _buildCyberButton(
                icon: Icons.cell_tower,
                glowColor: const Color(0xFF00D2FF),
                onTap: () => _sendCommand("寻车", "17"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCyberButton(
                icon: Icons.directions_car,
                glowColor: const Color(0xFF00D2FF),
                onTap: () => _sendCommand("后备箱", "21"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 极客风造型按钮
  Widget _buildCyberButton({
    required IconData icon,
    required Color glowColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF081424),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: glowColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.25),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              color: glowColor,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 蓝牙搜索与连接弹窗
  // ==========================================
  void _showBluetoothSearchDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0A1628),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFF00D2FF), width: 1.2),
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: const [
                  Icon(Icons.bluetooth_searching, color: Color(0xFF00D2FF)),
                  SizedBox(width: 8),
                  Text("搜索蓝牙设备...", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LinearProgressIndicator(color: Color(0xFF00D2FF), backgroundColor: Colors.white12),
                    const SizedBox(height: 14),
                    _buildDeviceTile("TianKey_ESP32_Control", "-54 dBm", () {
                      setState(() {
                        isConnected = true;
                        connectedDeviceName = "TianKey_ESP32";
                      });
                      Navigator.pop(ctx);
                      _showToast("✅ 已成功连接到: TianKey_ESP32");
                    }),
                    _buildDeviceTile("TianKey_BLE_v2", "-78 dBm", () {
                      setState(() {
                        isConnected = true;
                        connectedDeviceName = "TianKey_v2";
                      });
                      Navigator.pop(ctx);
                      _showToast("✅ 已成功连接到: TianKey_BLE_v2");
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("取消", style: TextStyle(color: Colors.white54)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDeviceTile(String name, String signal, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F213A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E3A60)),
      ),
      child: ListTile(
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text("信号强度: $signal", style: const TextStyle(color: Colors.white54, fontSize: 11)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D2FF),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          onPressed: onTap,
          child: const Text("连接", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }

  // 管理员认证弹窗
  void _showAdminAuthDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A1628),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.orangeAccent, width: 1.2),
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text("管理员授权认证", style: TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "请输入管理员密码",
            hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.orangeAccent)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () {
              setState(() => isAdmin = true);
              Navigator.pop(ctx);
              _showToast("🔑 管理员授权成功！");
            },
            child: const Text("确认授权", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. 临时借车页面 (包含生成临时密码功能)
  // ==========================================
  Widget _buildTempKeyPage() {
    final times = ["5分钟", "1天", "2天", "3天", "4天", "5天", "6天", "7天"];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text("临时借车密码生成", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),

          // 密码展示卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF081424),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: generatedPassword != null ? Colors.orangeAccent : const Color(0xFF1E3A60),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  generatedPassword == null ? "尚未生成密码" : "有效临时密码",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  generatedPassword ?? "------",
                  style: TextStyle(
                    color: generatedPassword != null ? Colors.orangeAccent : Colors.white24,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                if (generatedPassword != null) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: generatedPassword!));
                      _showToast("📋 密码已复制到剪贴板！");
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.copy, color: Color(0xFF00D2FF), size: 14),
                        SizedBox(width: 4),
                        Text("复制密码", style: TextStyle(color: Color(0xFF00D2FF), fontSize: 12)),
                      ],
                    ),
                  )
                ]
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text("选择有效时间:", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),

          // 时间选择块
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: times.map((t) {
              final isSelected = selectedDuration == t;
              return GestureDetector(
                onTap: () => setState(() => selectedDuration = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF00D2FF) : const Color(0xFF0B192C),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF00D2FF), width: 1),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const Spacer(),

          // 生成按键
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D2FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final randomPwd = (100000 + Random().nextInt(899999)).toString();
                setState(() => generatedPassword = randomPwd);
                _showToast("🔑 已成功生成【$selectedDuration】有效期的临时密码！");
              },
              icon: const Icon(Icons.key, color: Colors.black),
              label: const Text("生成临时密码", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 10),

          // 取消借车
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                setState(() => generatedPassword = null);
                _showToast("已清除当前临时借车密码");
              },
              child: const Text("取消借车密码", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. 设置页面 (对应 3_2.png 设计图)
  // ==========================================
  Widget _buildSettingsPage() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text("系统设置", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 10),
        _buildSettingTile(Icons.bluetooth, "修改蓝牙密码", () => _showModifyPasswordDialog()),
        _buildSettingTile(Icons.refresh, "恢复默认蓝牙密码", () => _showToast("已重置蓝牙密码为默认")),
        _buildSettingTile(Icons.phone_android, "设备名称 (皖A·0P92Y)", () => _showToast("设置设备名称")),
        _buildSettingTile(Icons.access_time, "时间同步设置", () => _showToast("时间校准完成")),
        _buildSettingTile(Icons.autorenew, "自动连接设置", () => _showToast("自动连接已开启")),
        _buildSettingTile(Icons.volume_up, "提示音设置", () => _showToast("提示音已开启")),
        _buildSettingTile(Icons.info_outline, "关于系统", _showAboutDialog),
      ],
    );
  }

  Widget _buildSettingTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF071220),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF162A45)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00D2FF), size: 22),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
        onTap: onTap,
      ),
    );
  }

  // 修改密码弹窗
  void _showModifyPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A1628),
        title: const Text("修改蓝牙密码", style: TextStyle(color: Color(0xFF00D2FF), fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInputField("当前蓝牙密码"),
            const SizedBox(height: 8),
            _buildInputField("新蓝牙密码"),
            const SizedBox(height: 8),
            _buildInputField("确认新密码"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D2FF)),
            onPressed: () {
              Navigator.pop(ctx);
              _showToast("蓝牙密码修改成功！");
            },
            child: const Text("保存", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String hint) {
    return TextField(
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00D2FF))),
      ),
    );
  }

  // 关于弹窗
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A1628),
        title: const Text("Tian Key 系统信息", style: TextStyle(color: Color(0xFF00D2FF), fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("针脚控制逻辑绑定:", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)),
            SizedBox(height: 6),
            Text("• 锁车: GPIO 4", style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text("• 解锁: GPIO 16", style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text("• 寻车: GPIO 17", style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text("• 车窗升: GPIO 18", style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text("• 车窗降: GPIO 19", style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text("• 后备箱: GPIO 21", style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("确定", style: TextStyle(color: Color(0xFF00D2FF)))),
        ],
      ),
    );
  }

  // 底部导航栏
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      backgroundColor: const Color(0xFF030710),
      selectedItemColor: const Color(0xFF00D2FF),
      unselectedItemColor: Colors.white38,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "首页"),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: "临时借车"),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "设置"),
      ],
    );
  }
}
