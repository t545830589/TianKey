import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tian Key',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        primaryColor: const Color(0xFF4A9EFF),
        cardColor: const Color(0xFF1A1A2E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      home: const MainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==================== 主页面（底部导航） ====================
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const TempBorrowPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFF0D0D1A),
          selectedItemColor: const Color(0xFF4A9EFF),
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
            BottomNavigationBarItem(icon: Icon(Icons.car_rental), label: '临时借车'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
          ],
        ),
      ),
    );
  }
}

// ==================== 首页 ====================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text('Tian Key', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: const Text(
              '皖A·0P92Y',
              style: TextStyle(fontSize: 16, color: Color(0xFF4A9EFF), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状态卡片
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                children: [
                  _buildStatusRow('设备状态', '未连接', const Color(0xFFFF4444)),
                  _buildDivider(),
                  _buildStatusRow('管理员状态', '未授权', const Color(0xFFFF8C00)),
                  _buildDivider(),
                  _buildStatusRow('供电状态', '未知', const Color(0xFF888888)),
                  _buildDivider(),
                  _buildStatusRow('时间同步', '未同步', const Color(0xFFFF4444)),
                  _buildDivider(),
                  _buildStatusRow('临时借车', '无有效密码', const Color(0xFFFF4444)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 操作按钮网格
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
              children: [
                _buildActionButton(Icons.bluetooth, '连接设备', const Color(0xFF4A9EFF)),
                _buildActionButton(Icons.admin_panel_settings, '管理员授权', const Color(0xFFFF8C00)),
                _buildActionButton(Icons.lock_outline, '锁车', const Color(0xFF4A9EFF)),
                _buildActionButton(Icons.lock_open_outlined, '解锁', const Color(0xFF4A9EFF)),
                _buildActionButton(Icons.arrow_upward, '车窗升', const Color(0xFF4A9EFF)),
                _buildActionButton(Icons.arrow_downward, '车窗降', const Color(0xFF4A9EFF)),
                _buildActionButton(Icons.my_location, '寻车', const Color(0xFF4A9EFF)),
                _buildActionButton(Icons.car_repair, '后备箱', const Color(0xFF4A9EFF)),
              ],
            ),
            const SizedBox(height: 30),
            // 底部页码
            Center(
              child: Text(
                '页码：1/11  左右滑动切换界面',
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.white.withOpacity(0.05), height: 1);
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ==================== 临时借车页面 ====================
class TempBorrowPage extends StatefulWidget {
  const TempBorrowPage({super.key});

  @override
  State<TempBorrowPage> createState() => _TempBorrowPageState();
}

class _TempBorrowPageState extends State<TempBorrowPage> {
  String selectedDuration = '5分钟';
  final List<String> durations = ['5分钟', '1天', '2天', '3天', '4天', '5天', '6天', '7天'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text('Tian Key', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: const Text(
              '临时借车',
              style: TextStyle(fontSize: 16, color: Color(0xFF4A9EFF), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前状态
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Color(0xFFFF4444), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  const Text('当前状态', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const Spacer(),
                  const Text('无有效临时密码', style: TextStyle(color: Color(0xFFFF4444), fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 选择有效时间
            const Text('选择有效时间', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: durations.length,
                itemBuilder: (ctx, idx) {
                  final d = durations[idx];
                  final isSelected = d == selectedDuration;
                  return GestureDetector(
                    onTap: () => setState(() => selectedDuration = d),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF4A9EFF) : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? const Color(0xFF4A9EFF) : Colors.white.withOpacity(0.1)),
                      ),
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // 临时密码
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  const Text('临时密码', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const Spacer(),
                  const Text('尚未生成', style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A9EFF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF4A9EFF).withOpacity(0.3)),
                    ),
                    child: const Text(
                      '复制密码',
                      style: TextStyle(color: Color(0xFF4A9EFF), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 状态卡片（复用首页样式）
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                children: [
                  _buildStatusRow('设备状态', '未连接', const Color(0xFFFF4444)),
                  _buildDivider(),
                  _buildStatusRow('管理员状态', '未授权', const Color(0xFFFF8C00)),
                  _buildDivider(),
                  _buildStatusRow('供电状态', '未知', const Color(0xFF888888)),
                  _buildDivider(),
                  _buildStatusRow('时间同步', '未同步', const Color(0xFFFF4444)),
                  _buildDivider(),
                  _buildStatusRow('临时借车', '无有效密码', const Color(0xFFFF4444)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 操作按钮
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSmallButton('生成临时密码', const Color(0xFF4A9EFF), () {}),
                _buildSmallButton('连接设备', const Color(0xFF4A9EFF), () {}),
                _buildSmallButton('管理员授权', const Color(0xFFFF8C00), () {}),
                _buildSmallButton('取消借车', const Color(0xFFFF4444), () {}),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDivider() => Divider(color: Colors.white.withOpacity(0.05), height: 1);

  Widget _buildSmallButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}

// ==================== 设置页面 ====================
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text('设置', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            _buildSettingItem(
              icon: Icons.lock_outline,
              title: '修改蓝牙密码',
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              onTap: () => _showChangePasswordDialog(context),
            ),
            _buildSettingItem(
              icon: Icons.restore,
              title: '恢复默认蓝牙密码',
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              onTap: () => _showResetPasswordDialog(context),
            ),
            _buildSettingItem(
              icon: Icons.devices,
              title: '设备名称',
              subtitle: '皖A·0P92Y',
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.access_time,
              title: '时间同步设置',
              subtitle: '未同步',
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.admin_panel_settings,
              title: '管理员授权',
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              onTap: () => _showAdminAuthDialog(context),
            ),
            _buildSettingItem(
              icon: Icons.sync,
              title: '自动连接设置',
              trailing: Switch(
                value: false,
                onChanged: (_) {},
                activeColor: const Color(0xFF4A9EFF),
                activeTrackColor: const Color(0xFF4A9EFF).withOpacity(0.3),
              ),
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.volume_up,
              title: '提示音设置',
              trailing: Switch(
                value: false,
                onChanged: (_) {},
                activeColor: const Color(0xFF4A9EFF),
                activeTrackColor: const Color(0xFF4A9EFF).withOpacity(0.3),
              ),
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.info_outline,
              title: '关于系统',
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              onTap: () {},
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4A9EFF), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
                  if (subtitle != null)
                    Text(subtitle, style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('修改蓝牙密码', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '当前蓝牙密码',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4A9EFF))),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '新蓝牙密码',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4A9EFF))),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '确认新密码',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4A9EFF))),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('保存新密码', style: TextStyle(color: Color(0xFF4A9EFF))),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('恢复默认蓝牙密码', style: TextStyle(color: Colors.white)),
        content: const Text(
          '恢复后蓝牙密码将重置为出厂默认值',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('恢复默认', style: TextStyle(color: Color(0xFFFF4444))),
          ),
        ],
      ),
    );
  }

  void _showAdminAuthDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('管理员授权', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '授权后可使用全部管理功能',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '请输入管理员密码',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4A9EFF))),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确认授权', style: TextStyle(color: Color(0xFF4A9EFF))),
          ),
        ],
      ),
    );
  }
}
