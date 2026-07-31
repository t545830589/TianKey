import 'package:flutter/material.dart';

void main() {
  runApp(const TianKeyApp());
}

class TianKeyApp extends StatelessWidget {
  const TianKeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tian Key V11',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF030712),
        primaryColor: const Color(0xFF007ACC),
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF0B132B),
          primary: Color(0xFF007ACC),
          secondary: Color(0xFFFF6600),
        ),
        fontFamily: 'sans-serif',
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeTabPage(),
          TempKeyTabPage(),
          SettingsTabPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF050B14),
          border: Border(top: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '首页',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: '临时借车',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: '设置',
            ),
          ],
        ),
      ),
    );
  }
}

// 1. 首页 (Home Tab)
class HomeTabPage extends StatelessWidget {
  const HomeTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white70),
                  onPressed: () {},
                ),
                const Text(
                  'Tian Key',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Colors.cyanAccent,
                    shadows: [Shadow(color: Colors.cyan, blurRadius: 10)],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.white70),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.5), width: 1.5),
                color: const Color(0xFF081225),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.directions_car, size: 80, color: Colors.blueAccent),
                  Positioned(
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[900],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.cyanAccent),
                      ),
                      child: const Text(
                        '陕A·0P92Y',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                StatusBox(icon: Icons.bluetooth_disabled, label: '设备状态', value: '未连接'),
                StatusBox(icon: Icons.security, label: '管理员状态', value: '未授权'),
                StatusBox(icon: Icons.bolt, label: '供电状态', value: '未知'),
                StatusBox(icon: Icons.access_time, label: '时间同步', value: '未同步'),
                StatusBox(icon: Icons.vpn_key, label: '临时借车', value: '无有效密码'),
              ],
            ),
            const SizedBox(height: 16),
            _buildNeonButton(context, '连接设备', Icons.bluetooth, Colors.blue, () {}),
            const SizedBox(height: 10),
            _buildNeonButton(context, '管理员授权', Icons.admin_panel_settings, Colors.orange, () {
              _showAdminAuthDialog(context);
            }),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildNeonButton(context, '锁车', Icons.lock, Colors.blue, () {})),
                const SizedBox(width: 10),
                Expanded(child: _buildNeonButton(context, '解锁', Icons.lock_open, Colors.blue, () {})),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildNeonButton(context, '车窗升', Icons.keyboard_arrow_up, Colors.orange, () {})),
                const SizedBox(width: 10),
                Expanded(child: _buildNeonButton(context, '车窗降', Icons.keyboard_arrow_down, Colors.orange, () {})),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildNeonButton(context, '寻车', Icons.notifications_active, Colors.blue, () {})),
                const SizedBox(width: 10),
                Expanded(child: _buildNeonButton(context, '后备箱', Icons.car_rental, Colors.blue, () {})),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeonButton(BuildContext context, String title, IconData icon, Color borderColor, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
        gradient: LinearGradient(
          colors: [Colors.blue.withOpacity(0.1), Colors.black54],
        ),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: borderColor, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showAdminAuthDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B132B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.orange, width: 1.5),
        ),
        title: const Text('管理员授权', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.security, color: Colors.orange, size: 48),
            const SizedBox(height: 12),
            const Text('请输入管理员密码进行授权', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: '请输入管理员密码',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: const Icon(Icons.visibility_off, color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            height: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange, width: 1.5),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
              onPressed: () => Navigator.pop(context),
              child: const Text('确认授权', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }
}

class StatusBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const StatusBox({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Icon(icon, size: 18, color: Colors.blueAccent),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 9, color: Colors.white54), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// 2. 临时借车 (Temporary Key Tab)
class TempKeyTabPage extends StatefulWidget {
  const TempKeyTabPage({super.key});

  @override
  State<TempKeyTabPage> createState() => _TempKeyTabPageState();
}

class _TempKeyTabPageState extends State<TempKeyTabPage> {
  int selectedDurationIndex = 0;
  final List<String> durations = ['5分钟', '1天', '2天', '3天', '4天', '5天', '6天', '7天'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('临时借车', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {}),
        actions: [IconButton(icon: const Icon(Icons.receipt_long), onPressed: () {})],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('当前状态', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.vpn_key, color: Colors.white54, size: 20),
                SizedBox(width: 8),
                Text('无有效临时密码', style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('选择有效时间', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(durations.length, (index) {
                bool isSelected = selectedDurationIndex == index;
                return ChoiceChip(
                  label: Text(durations[index]),
                  selected: isSelected,
                  onSelected: (selected) => setState(() => selectedDurationIndex = index),
                  selectedColor: Colors.blue[800],
                  backgroundColor: const Color(0xFF0B132B),
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(color: isSelected ? Colors.cyanAccent : Colors.blue.withOpacity(0.3)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                children: const [
                  Icon(Icons.lock_outline, color: Colors.white30, size: 36),
                  SizedBox(height: 8),
                  Text('尚未生成', style: TextStyle(color: Colors.white30, fontSize: 14)),
                ],
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent, width: 1.5),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                onPressed: () {},
                child: const Text('生成临时密码', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent, width: 1.5),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                onPressed: () {},
                child: const Text('取消借车', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. 设置 (Settings Tab)
class SettingsTabPage extends StatelessWidget {
  const SettingsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('设置', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {}),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingItem(context, Icons.bluetooth, '修改蓝牙密码', '', () => _showEditPwdDialog(context)),
          _buildSettingItem(context, Icons.refresh, '恢复默认蓝牙密码', '', () => _showResetPwdDialog(context)),
          _buildSettingItem(context, Icons.devices, '设备名称', '陕A·0P92Y', () => _showDeviceNameDialog(context)),
          _buildSettingItem(context, Icons.access_time, '时间同步设置', '', () => _showTimeSyncDialog(context)),
          _buildSettingItem(context, Icons.link, '自动连接设置', '关闭', () {}),
          _buildSettingItem(context, Icons.volume_up, '提示音设置', '关闭', () => _showSoundDialog(context)),
          _buildSettingItem(context, Icons.info_outline, '关于系统', '', () {}),
        ],
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, IconData icon, String title, String trailingText, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText.isNotEmpty)
              Text(trailingText, style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _showEditPwdDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B132B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.blue)),
        title: const Text('修改蓝牙密码', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            TextField(obscureText: true, decoration: InputDecoration(hintText: '请输入当前蓝牙密码', filled: true, fillColor: Colors.black26)),
            SizedBox(height: 10),
            TextField(obscureText: true, decoration: InputDecoration(hintText: '请输入新蓝牙密码', filled: true, fillColor: Colors.black26)),
            SizedBox(height: 10),
            TextField(obscureText: true, decoration: InputDecoration(hintText: '请再次输入新密码', filled: true, fillColor: Colors.black26)),
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            height: 45,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blueAccent)),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
              onPressed: () => Navigator.pop(context),
              child: const Text('保存新密码', style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  void _showResetPwdDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B132B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.red)),
        title: const Text('恢复默认蓝牙密码', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.refresh, color: Colors.blueAccent, size: 48),
            SizedBox(height: 12),
            Text('恢复后蓝牙密码将重置为出厂默认值', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            height: 45,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.redAccent)),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
              onPressed: () => Navigator.pop(context),
              child: const Text('恢复默认蓝牙密码', style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  void _showDeviceNameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B132B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.blue)),
        title: const Text('设备名称', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.phone_android, color: Colors.blueAccent, size: 48),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(hintText: '陕A·0P92Y', filled: true, fillColor: Colors.black26),
            ),
            SizedBox(height: 8),
            Text('设备名称将用于蓝牙连接和设备识别', style: TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            height: 45,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blueAccent)),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
              onPressed: () => Navigator.pop(context),
              child: const Text('保存', style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  void _showTimeSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B132B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.blue)),
        title: const Text('时间同步设置', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.access_time, color: Colors.blueAccent, size: 48),
            SizedBox(height: 8),
            Text('当前状态: 未同步', style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            height: 45,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blueAccent)),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
              onPressed: () => Navigator.pop(context),
              child: const Text('立即同步', style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  void _showSoundDialog(BuildContext context) {
    withContext: context
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B132B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.blue)),
        title: const Text('提示音设置', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.volume_up, color: Colors.blueAccent, size: 48),
            SizedBox(height: 12),
            Text('开启后, 操作时播放提示音', style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            height: 45,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blueAccent)),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
              onPressed: () => Navigator.pop(context),
              child: const Text('确定', style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}
