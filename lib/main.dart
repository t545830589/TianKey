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
        scaffoldBackgroundColor: const Color(0xFF03070D),
        primaryColor: const Color(0xFF00F0FF),
      ),
      home: const MainShellScreen(),
    );
  }
}

// 主外壳（包含底部导航与页面切换）
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),       // 第 1 页：首页
    TempKeyPage(),    // 第 2 页：临时借车
    SettingsPage(),   // 第 3 页：设置列表
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
          color: Color(0xFF060B14),
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF00F0FF),
          unselectedItemColor: Colors.white38,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: '临时借车'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 【页面 1】首页
// -----------------------------------------------------------------------------
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 顶部车头大图与标题
          Stack(
            children: [
              Image.asset(
                '1.png',
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: Colors.white10,
                  child: const Center(child: Text('图片 1.png 加载中...')),
                ),
              ),
              Positioned(
                top: 10,
                left: 15,
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white70),
                  onPressed: () {},
                ),
              ),
              Positioned(
                top: 10,
                right: 15,
                child: IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.white70),
                  onPressed: () {},
                ),
              ),
              const Positioned(
                top: 15,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Tian Key',
                    style: TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              // 车牌号
              Positioned(
                bottom: 25,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A3B8C),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Text(
                      '皖A·0P92Y',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 5 个状态卡片
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                _buildStatusBox('设备状态', Icons.bluetooth, '未连接', const Color(0xFF00F0FF)),
                _buildStatusBox('管理员状态', Icons.shield_outlined, '未授权', Colors.grey),
                _buildStatusBox('供电状态', Icons.flash_on, '未知', Colors.grey),
                _buildStatusBox('时间同步', Icons.access_time, '未同步', Colors.grey),
                _buildStatusBox('临时借车', Icons.vpn_key_outlined, '无有效密码', Colors.grey),
              ],
            ),
          ),

          // 8 个霓虹发光按钮
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 2.7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 10,
                children: [
                  _buildGlowBtn('连接设备', Icons.bluetooth, const Color(0xFF00F0FF)),
                  _buildGlowBtn('管理员授权', Icons.shield_outlined, const Color(0xFFFF6600), onTap: () {
                    _openSubPage(context, const AdminAuthPage());
                  }),
                  _buildGlowBtn('锁车', Icons.lock_outline, const Color(0xFF00F0FF)),
                  _buildGlowBtn('解锁', Icons.lock_open, const Color(0xFF00F0FF)),
                  _buildGlowBtn('车窗升', Icons.keyboard_double_arrow_up, const Color(0xFFFF6600)),
                  _buildGlowBtn('车窗降', Icons.keyboard_double_arrow_down, const Color(0xFFFF6600)),
                  _buildGlowBtn('寻车', Icons.radar, const Color(0xFF00F0FF)),
                  _buildGlowBtn('后备箱', Icons.directions_car_outlined, const Color(0xFF00F0FF)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBox(String title, IconData icon, String val, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF09121F),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 9)),
            const SizedBox(height: 4),
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(val, style: const TextStyle(color: Colors.white70, fontSize: 8)),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowBtn(String label, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color == const Color(0xFFFF6600) ? const Color(0xFF180E05) : const Color(0xFF061320),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 7,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 【页面 2】临时借车
// -----------------------------------------------------------------------------
class TempKeyPage extends StatelessWidget {
  const TempKeyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text('临时借车', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 20),
            const Text('当前状态', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.vpn_key_off_outlined, color: Colors.white70, size: 18),
                SizedBox(width: 8),
                Text('无有效临时密码', style: TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('选择有效时间', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['5分钟', '1天', '2天', '3天', '4天', '5天', '6天', '7天'].map((time) {
                final isFirst = time == '5分钟';
                return Container(
                  width: 75,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isFirst ? const Color(0xFF072138) : const Color(0xFF0A111A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isFirst ? const Color(0xFF00F0FF) : Colors.white12),
                  ),
                  child: Center(
                    child: Text(time, style: TextStyle(color: isFirst ? const Color(0xFF00F0FF) : Colors.white70, fontSize: 12)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 25),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF070E17),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: const [
                  Icon(Icons.lock_outline, color: Colors.white38, size: 30),
                  SizedBox(height: 8),
                  Text('尚未生成', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  SizedBox(height: 12),
                  Text('复制密码', style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            const Spacer(),
            _buildBigGlowBtn('生成临时密码', const Color(0xFF00F0FF)),
            const SizedBox(height: 12),
            _buildBigGlowBtn('取消借车', const Color(0xFFFF2A4B)),
          ],
        ),
      ),
    );
  }

  Widget _buildBigGlowBtn(String text, Color color) {
    return Container(
      width: double.infinity,
      height: 45,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.2),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 6),
        ],
      ),
      child: Center(
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 【页面 3】设置页面（聚合剩下 8 个子功能页面）
// -----------------------------------------------------------------------------
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 15),
          const Text('设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 15),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildNavItem(context, Icons.bluetooth, '修改蓝牙密码', const ModifyBtPwdPage()),
                _buildNavItem(context, Icons.sync, '恢复默认蓝牙密码', const RestoreBtPwdPage()),
                _buildNavItem(context, Icons.smartphone, '设备名称', const DeviceNamePage(), trailingText: '皖A·0P92Y'),
                _buildNavItem(context, Icons.access_time, '时间同步设置', const TimeSyncPage()),
                _buildNavItem(context, Icons.link, '自动连接设置', const AutoConnectPage(), trailingText: '关闭'),
                _buildNavItem(context, Icons.volume_up, '提示音设置', const SoundSettingPage(), trailingText: '关闭'),
                _buildNavItem(context, Icons.info_outline, '关于系统', const AboutSystemPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title, Widget page, {String? trailingText}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF08101A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00F0FF), size: 20),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null)
              Text(trailingText, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
          ],
        ),
        onTap: () => _openSubPage(context, page),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 【页面 4 ~ 11】子功能弹窗与设置页面
// -----------------------------------------------------------------------------

class AdminAuthPage extends StatelessWidget {
  const AdminAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildSubShell(
      context,
      '管理员授权',
      Column(
        children: [
          const SizedBox(height: 20),
          Image.asset('2.png', height: 90, errorBuilder: (_, __, ___) => const Icon(Icons.shield, size: 80, color: Colors.amber)),
          const SizedBox(height: 15),
          const Text('请输入管理员密码进行授权', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 20),
          _buildInputField('请输入管理员密码'),
          const SizedBox(height: 25),
          _buildGlowSubmitBtn('确认授权', const Color(0xFFFF6600)),
        ],
      ),
    );
  }
}

class ModifyBtPwdPage extends StatelessWidget {
  const ModifyBtPwdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildSubShell(
      context,
      '修改蓝牙密码',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('当前蓝牙密码', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          _buildInputField('请输入当前蓝牙密码'),
          const SizedBox(height: 15),
          const Text('新蓝牙密码', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          _buildInputField('请输入新蓝牙密码'),
          const SizedBox(height: 15),
          const Text('确认新密码', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          _buildInputField('请再次输入新密码'),
          const SizedBox(height: 25),
          _buildGlowSubmitBtn('保存新密码', const Color(0xFF00F0FF)),
        ],
      ),
    );
  }
}

class RestoreBtPwdPage extends StatelessWidget {
  const RestoreBtPwdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildSubShell(
      context,
      '恢复默认蓝牙密码',
      Column(
        children: [
          const SizedBox(height: 30),
          const Icon(Icons.sync, color: Color(0xFF00F0FF), size: 60),
          const SizedBox(height: 20),
          const Text('恢复后蓝牙密码将重置为\n出厂默认值', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 40),
          _buildGlowSubmitBtn('恢复默认蓝牙密码', const Color(0xFFFF2A4B)),
        ],
      ),
    );
  }
}

class DeviceNamePage extends StatelessWidget {
  const DeviceNamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildSubShell(
      context,
      '设备名称',
      Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.smartphone, color: Colors.white70, size: 50),
          const SizedBox(height: 20),
          _buildInputField('皖A·0P92Y'),
          const SizedBox(height: 8),
          const Text('设备名称将用于蓝牙连接和设备识别', style: TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 30),
          _buildGlowSubmitBtn('保存', const Color(0xFF00F0FF)),
        ],
      ),
    );
  }
}

class TimeSyncPage extends StatelessWidget {
  const TimeSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildSubShell(
      context,
      '时间同步设置',
      Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.access_time, color: Colors.white70, size: 60),
          const SizedBox(height: 15),
          const Text('当前状态\n未同步', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 30),
          _buildGlowSubmitBtn('立即同步', const Color(0xFF00F0FF)),
          const SizedBox(height: 10),
          const Text('同步后将自动校准设备时间', style: TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }
}

class SoundSettingPage extends StatelessWidget {
  const SoundSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildSubShell(
      context,
      '提示音设置',
      Column(
        children: [
          const SizedBox(height: 30),
          const Icon(Icons.volume_up, color: Color(0xFF00F0FF), size: 60),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('提示音', style: TextStyle(color: Colors.white, fontSize: 14)),
              Switch(value: false, onChanged: (v) {}),
            ],
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('开启后，操作时播放提示音', style: TextStyle(color: Colors.white38, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

class AutoConnectPage extends StatelessWidget {
  const AutoConnectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildSubShell(
      context,
      '自动连接设置',
      Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('自动连接', style: TextStyle(color: Colors.white, fontSize: 14)),
              Switch(value: false, onChanged: (v) {}),
            ],
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('开启后，APP启动时将自动连接已配对设备', style: TextStyle(color: Colors.white38, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

class AboutSystemPage extends StatelessWidget {
  const AboutSystemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildSubShell(
      context,
      '关于系统',
      Column(
        children: [
          const SizedBox(height: 40),
          Image.asset('3.png', height: 70, errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, size: 70, color: Colors.blueGrey)),
          const SizedBox(height: 20),
          const Text('Tian Key', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Tian Key 智能车钥匙控制系统  ● 未连接设备', style: TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 通用辅助组件
// -----------------------------------------------------------------------------
void _openSubPage(BuildContext context, Widget page) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

Widget _buildSubShell(BuildContext context, String title, Widget content) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(title, style: const TextStyle(fontSize: 16, color: Colors.white)),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.all(20.0),
      child: content,
    ),
  );
}

Widget _buildInputField(String hint) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF09101A),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.white12),
    ),
    child: TextField(
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        suffixIcon: const Icon(Icons.visibility_off, color: Colors.white38, size: 18),
      ),
    ),
  );
}

Widget _buildGlowSubmitBtn(String text, Color color) {
  return Container(
    width: double.infinity,
    height: 42,
    decoration: BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color, width: 1.2),
      boxShadow: [
        BoxShadow(color: color.withOpacity(0.35), blurRadius: 6),
      ],
    ),
    child: Center(
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
    ),
  );
}
