import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 强制 APP 永远竖屏，避免出现横向宽屏。
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const TianKeyApp());
}

const Color bg = Color(0xFF02080D);
const Color panel = Color(0xFF06121B);
const Color panel2 = Color(0xFF091923);
const Color blue = Color(0xFF159DFF);
const Color cyan = Color(0xFF62D8FF);
const Color orange = Color(0xFFFF7A1A);
const Color red = Color(0xFFFF1515);
const Color line = Color(0xFF234052);
const Color text = Color(0xFFE7F4FF);
const Color muted = Color(0xFF88949D);

class TianKeyApp extends StatelessWidget {
  const TianKeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tian Key',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        fontFamily: 'sans',
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onTab: (value) => setState(() => tab = value)),
      const BorrowPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: BottomNav(
        current: tab,
        onChanged: (value) => setState(() => tab = value),
      ),
    );
  }
}

/// ================================
/// 首页
/// ================================
class HomePage extends StatelessWidget {
  final ValueChanged<int> onTab;

  const HomePage({super.key, required this.onTab});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
      child: Column(
        children: [
          Row(
            children: [
              RoundIcon(
                icon: Icons.settings,
                onTap: () => onTab(2),
              ),
              const Expanded(
                child: Text(
                  'Tian Key',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cyan,
                    fontSize: 28,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: [Shadow(color: blue, blurRadius: 14)],
                  ),
                ),
              ),
              RoundIcon(
                icon: Icons.question_mark_rounded,
                onTap: () => openPage(context, const AboutPage()),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 红色昂克赛拉主视觉区。
          // 当前为纯代码绘制的未来汽车视觉，不会把整张 UI 图塞进页面。
          const CarHero(),
          const SizedBox(height: 10),

          const Row(
            children: [
              Expanded(
                child: StatusBox(
                  title: '设备状态',
                  value: '未连接',
                  icon: Icons.bluetooth_disabled,
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: StatusBox(
                  title: '管理员状态',
                  value: '未授权',
                  icon: Icons.shield_outlined,
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: StatusBox(
                  title: '供电状态',
                  value: '未知',
                  icon: Icons.bolt_outlined,
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: StatusBox(
                  title: '时间同步',
                  value: '未同步',
                  icon: Icons.access_time,
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: StatusBox(
                  title: '临时借车',
                  value: '无有效密码',
                  icon: Icons.key_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),

          Row(
            children: [
              Expanded(
                child: GlowButton(
                  label: '连接设备',
                  icon: Icons.bluetooth,
                  color: blue,
                  onTap: () => toast(context, '设备未连接'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlowButton(
                  label: '管理员授权',
                  icon: Icons.shield_outlined,
                  color: orange,
                  onTap: () => openPage(context, const AdminAuthPage()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                child: GlowButton(
                  label: '锁车',
                  icon: Icons.lock,
                  color: blue,
                  onTap: () => toast(context, '锁车：设备未连接'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlowButton(
                  label: '解锁',
                  icon: Icons.lock_open,
                  color: blue,
                  onTap: () => toast(context, '解锁：设备未连接'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                child: GlowButton(
                  label: '车窗升',
                  icon: Icons.keyboard_double_arrow_up,
                  color: orange,
                  onTap: () => toast(context, '车窗升：设备未连接'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlowButton(
                  label: '车窗降',
                  icon: Icons.keyboard_double_arrow_down,
                  color: orange,
                  onTap: () => toast(context, '车窗降：设备未连接'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                child: GlowButton(
                  label: '寻车',
                  icon: Icons.sensors,
                  color: blue,
                  onTap: () => toast(context, '寻车：设备未连接'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlowButton(
                  label: '后备箱',
                  icon: Icons.directions_car_outlined,
                  color: blue,
                  onTap: () => toast(context, '后备箱：设备未连接'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CarHero extends StatelessWidget {
  const CarHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 278,
      width: double.infinity,
      decoration: cyberBox(blue, radius: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: TechBackgroundPainter()),
          ),
          const Positioned(
            top: 16,
            child: Icon(
              Icons.radio_button_checked,
              size: 70,
              color: Color(0xFF005DB1),
            ),
          ),
          const Positioned(
            top: 33,
            child: Icon(
              Icons.circle,
              size: 35,
              color: Color(0xFF27BFFF),
            ),
          ),

          // 用 Flutter 图标、渐变和光效组成主视觉。
          Positioned(
            bottom: 39,
            child: Container(
              width: 310,
              height: 105,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(65),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF640000),
                    Color(0xFFD0000A),
                    Color(0xFF590000),
                  ],
                ),
                border: Border.all(color: const Color(0xFFFF4A4A), width: 1.4),
                boxShadow: const [
                  BoxShadow(color: Color(0x99FF0000), blurRadius: 22),
                  BoxShadow(color: Color(0x990060FF), blurRadius: 22),
                ],
              ),
              child: Stack(
                children: [
                  const Positioned(
                    left: 21,
                    top: 44,
                    child: Icon(
                      Icons.light_mode,
                      color: Color(0xFF62D8FF),
                      size: 25,
                    ),
                  ),
                  const Positioned(
                    right: 21,
                    top: 44,
                    child: Icon(
                      Icons.light_mode,
                      color: Color(0xFF62D8FF),
                      size: 25,
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.directions_car_filled,
                      color: Colors.red.shade900,
                      size: 135,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF154F9A),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: cyan),
              ),
              child: const Text(
                '陕A·0P92Y',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ================================
/// 临时借车
/// ================================
class BorrowPage extends StatefulWidget {
  const BorrowPage({super.key});

  @override
  State<BorrowPage> createState() => _BorrowPageState();
}

class _BorrowPageState extends State<BorrowPage> {
  String selected = '5分钟';

  final times = const ['5分钟', '1天', '2天', '3天', '4天', '5天', '6天', '7天'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
      child: Column(
        children: [
          const PageHeader(title: '临时借车'),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: cyberBox(cyan),
            child: const Row(
              children: [
                Icon(Icons.key, color: muted, size: 31),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('当前状态', style: TextStyle(color: muted, fontSize: 12)),
                    SizedBox(height: 3),
                    Text(
                      '无有效临时密码',
                      style: TextStyle(color: text, fontSize: 17),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text('选择有效时间', style: TextStyle(color: text)),
          ),
          const SizedBox(height: 8),

          GridView.count(
            crossAxisCount: 4,
            childAspectRatio: 1.55,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            children: times.map((value) {
              final active = selected == value;
              return InkWell(
                onTap: () => setState(() => selected = value),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  alignment: Alignment.center,
                  decoration: cyberBox(active ? blue : line, radius: 8),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: active ? cyan : text,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 11),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: cyberBox(line),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('临时密码', style: TextStyle(color: muted)),
                const SizedBox(height: 8),
                Container(
                  height: 75,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: muted.withOpacity(.38),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, color: muted, size: 27),
                      SizedBox(height: 4),
                      Text('尚未生成', style: TextStyle(color: muted)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: line),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Text(
                    '▣   复制密码',
                    style: TextStyle(color: muted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          GlowButton(
            label: '生成临时密码',
            color: blue,
            onTap: () => toast(context, '设备未连接，无法生成临时密码'),
          ),
          const SizedBox(height: 9),
          GlowButton(
            label: '取消借车',
            color: red,
            onTap: () => toast(context, '当前没有有效临时借车'),
          ),
        ],
      ),
    );
  }
}

/// ================================
/// 设置主页
/// ================================
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
      child: Column(
        children: [
          const PageHeader(title: '设置'),
          const SizedBox(height: 16),
          Container(
            decoration: cyberBox(cyan),
            child: Column(
              children: [
                SettingRow(
                  icon: Icons.bluetooth,
                  title: '修改蓝牙密码',
                  onTap: () => openPage(context, const ChangeBluetoothPage()),
                ),
                SettingRow(
                  icon: Icons.restart_alt,
                  title: '恢复默认蓝牙密码',
                  onTap: () => openPage(context, const RestoreBluetoothPage()),
                ),
                SettingRow(
                  icon: Icons.phone_android_outlined,
                  title: '设备名称',
                  value: '陕A·0P92Y',
                  onTap: () => openPage(context, const DeviceNamePage()),
                ),
                SettingRow(
                  icon: Icons.access_time,
                  title: '时间同步设置',
                  onTap: () => openPage(context, const TimeSyncPage()),
                ),
                SettingRow(
                  icon: Icons.link,
                  title: '自动连接设置',
                  value: '关闭',
                  onTap: () => openPage(context, const AutoConnectPage()),
                ),
                SettingRow(
                  icon: Icons.volume_up_outlined,
                  title: '提示音设置',
                  value: '关闭',
                  onTap: () => openPage(context, const SoundPage()),
                ),
                SettingRow(
                  icon: Icons.info_outline,
                  title: '关于系统',
                  onTap: () => openPage(context, const AboutPage()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ================================
/// 管理员授权
/// ================================
class AdminAuthPage extends StatelessWidget {
  const AdminAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CyberPage(
      title: '管理员授权',
      child: Column(
        children: [
          const SizedBox(height: 22),
          const Icon(
            Icons.shield_outlined,
            color: orange,
            size: 88,
            shadows: [Shadow(color: orange, blurRadius: 18)],
          ),
          const SizedBox(height: 13),
          const Text(
            '请输入管理员密码进行授权',
            style: TextStyle(color: text, fontSize: 15),
          ),
          const SizedBox(height: 26),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('管理员密码', style: TextStyle(color: muted)),
          ),
          const SizedBox(height: 6),
          const CyberInput(hint: '请输入管理员密码', obscure: true),
          const SizedBox(height: 15),
          GlowButton(
            label: '确认授权',
            color: orange,
            onTap: () => toast(context, '授权信息尚未配置'),
          ),
          const SizedBox(height: 9),
          const Text(
            '授权后可使用全部管理功能',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// ================================
/// 修改蓝牙密码
/// ================================
class ChangeBluetoothPage extends StatelessWidget {
  const ChangeBluetoothPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CyberPage(
      title: '修改蓝牙密码',
      child: Column(
        children: [
          const SizedBox(height: 18),
          const FormTitle(label: '当前蓝牙密码'),
          const CyberInput(hint: '请输入当前蓝牙密码', obscure: true),
          const SizedBox(height: 14),
          const FormTitle(label: '新蓝牙密码'),
          const CyberInput(hint: '请输入新蓝牙密码', obscure: true),
          const SizedBox(height: 14),
          const FormTitle(label: '确认新密码'),
          const CyberInput(hint: '请再次输入新密码', obscure: true),
          const SizedBox(height: 20),
          GlowButton(
            label: '保存新密码',
            color: blue,
            onTap: () => toast(context, '设备未连接，无法保存'),
          ),
        ],
      ),
    );
  }
}

/// ================================
/// 恢复默认蓝牙密码
/// ================================
class RestoreBluetoothPage extends StatelessWidget {
  const RestoreBluetoothPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CyberPage(
      title: '恢复默认蓝牙密码',
      child: Column(
        children: [
          const SizedBox(height: 43),
          const Icon(
            Icons.restart_alt,
            size: 85,
            color: cyan,
            shadows: [Shadow(color: blue, blurRadius: 18)],
          ),
          const SizedBox(height: 30),
          const Text(
            '恢复后蓝牙密码将重置为\n出厂默认值',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 16, height: 1.7),
          ),
          const SizedBox(height: 34),
          GlowButton(
            label: '恢复默认蓝牙密码',
            color: red,
            onTap: () => toast(context, '设备未连接，无法恢复'),
          ),
        ],
      ),
    );
  }
}

/// ================================
/// 设备名称
/// ================================
class DeviceNamePage extends StatelessWidget {
  const DeviceNamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CyberPage(
      title: '设备名称',
      child: Column(
        children: [
          const SizedBox(height: 25),
          const Icon(
            Icons.phone_android_outlined,
            size: 76,
            color: text,
          ),
          const SizedBox(height: 25),
          const FormTitle(label: '设备名称'),
          const CyberInput(hint: '陕A·0P92Y', initial: '陕A·0P92Y'),
          const SizedBox(height: 7),
          const Text(
            '设备名称将用于蓝牙连接和设备识别',
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 21),
          GlowButton(
            label: '保存',
            color: blue,
            onTap: () => toast(context, '设备未连接，无法保存'),
          ),
        ],
      ),
    );
  }
}

/// ================================
/// 时间同步
/// ================================
class TimeSyncPage extends StatelessWidget {
  const TimeSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CyberPage(
      title: '时间同步设置',
      child: Column(
        children: [
          const SizedBox(height: 39),
          const Icon(
            Icons.access_time,
            color: text,
            size: 85,
          ),
          const SizedBox(height: 26),
          const Text('当前状态', style: TextStyle(color: muted)),
          const SizedBox(height: 5),
          const Text(
            '未同步',
            style: TextStyle(color: text, fontSize: 20),
          ),
          const SizedBox(height: 24),
          GlowButton(
            label: '立即同步',
            color: blue,
            onTap: () => toast(context, '设备未连接，无法同步时间'),
          ),
          const SizedBox(height: 13),
          const Text(
            '同步后将自动校准设备时间',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// ================================
/// 自动连接
/// ================================
class AutoConnectPage extends StatefulWidget {
  const AutoConnectPage({super.key});

  @override
  State<AutoConnectPage> createState() => _AutoConnectPageState();
}

class _AutoConnectPageState extends State<AutoConnectPage> {
  bool enabled = false;

  @override
  Widget build(BuildContext context) {
    return CyberPage(
      title: '自动连接设置',
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: cyberBox(cyan),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('自动连接', style: TextStyle(color: text, fontSize: 17)),
                      SizedBox(height: 8),
                      Text(
                        '开启后，APP启动时将自动连接已配对设备',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  activeColor: cyan,
                  onChanged: (value) => setState(() => enabled = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ================================
/// 提示音
/// ================================
class SoundPage extends StatefulWidget {
  const SoundPage({super.key});

  @override
  State<SoundPage> createState() => _SoundPageState();
}

class _SoundPageState extends State<SoundPage> {
  bool enabled = false;

  @override
  Widget build(BuildContext context) {
    return CyberPage(
      title: '提示音设置',
      child: Column(
        children: [
          const SizedBox(height: 38),
          const Icon(
            Icons.volume_up_outlined,
            size: 88,
            color: cyan,
            shadows: [Shadow(color: blue, blurRadius: 18)],
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: cyberBox(cyan),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '提示音',
                    style: TextStyle(color: text, fontSize: 17),
                  ),
                ),
                Switch(
                  value: enabled,
                  activeColor: cyan,
                  onChanged: (value) => setState(() => enabled = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '开启后，操作时播放提示音',
            style: TextStyle(color: muted),
          ),
        ],
      ),
    );
  }
}

/// ================================
/// 关于系统
/// ================================
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CyberPage(
      title: '关于系统',
      child: Column(
        children: [
          const SizedBox(height: 45),
          const Icon(
            Icons.directions_car_filled_outlined,
            size: 95,
            color: cyan,
            shadows: [Shadow(color: blue, blurRadius: 18)],
          ),
          const SizedBox(height: 22),
          const Text(
            'Tian Key',
            style: TextStyle(
              color: cyan,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          const InfoLine(label: '车型', value: '马自达昂克赛拉'),
          const InfoLine(label: '车牌', value: '陕A0P92Y'),
          const InfoLine(label: '设备', value: 'ESP32'),
          const InfoLine(label: '设备状态', value: '未连接设备'),
        ],
      ),
    );
  }
}

/// ================================
/// 通用页面组件
/// ================================
class CyberPage extends StatelessWidget {
  final String title;
  final Widget child;

  const CyberPage({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
      child: Column(
        children: [
          PageHeader(
            title: title,
            showBack: true,
            onBack: () => Navigator.pop(context),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: cyberBox(cyan),
            child: child,
          ),
        ],
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;

  const PageHeader({
    super.key,
    required this.title,
    this.showBack = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showBack)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new, color: text),
              ),
            ),
          Text(
            title,
            style: const TextStyle(
              color: text,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatusBox({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 91,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
      decoration: cyberBox(line, radius: 7),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: text, fontSize: 11),
          ),
          Icon(icon, color: muted, size: 27),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class GlowButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;

  const GlowButton({
    super.key,
    required this.label,
    this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 54,
        decoration: cyberBox(color, radius: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color == orange ? orange : cyan, size: 29),
              const SizedBox(width: 13),
            ],
            Text(
              label,
              style: TextStyle(
                color: text,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: color, blurRadius: 10)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const RoundIcon({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
          border: Border.all(color: muted.withOpacity(.65)),
        ),
        child: Icon(icon, color: text, size: 27),
      ),
    );
  }
}

class SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;

  const SettingRow({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 57,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: line)),
        ),
        child: Row(
          children: [
            Icon(icon, color: cyan, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: text, fontSize: 16),
              ),
            ),
            if (value != null)
              Text(value!, style: const TextStyle(color: muted, fontSize: 13)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: muted),
          ],
        ),
      ),
    );
  }
}

class CyberInput extends StatelessWidget {
  final String hint;
  final String? initial;
  final bool obscure;

  const CyberInput({
    super.key,
    required this.hint,
    this.initial,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscure,
      controller: initial == null ? null : TextEditingController(text: initial),
      style: const TextStyle(color: text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: muted, fontSize: 13),
        suffixIcon: obscure
            ? const Icon(Icons.visibility_outlined, color: muted, size: 19)
            : null,
        filled: true,
        fillColor: const Color(0xFF030B11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: line),
          borderRadius: BorderRadius.circular(7),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: blue),
          borderRadius: BorderRadius.circular(7),
        ),
      ),
    );
  }
}

class FormTitle extends StatelessWidget {
  final String label;

  const FormTitle({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(label, style: const TextStyle(color: muted, fontSize: 13)),
      ),
    );
  }
}

class InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const InfoLine({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: muted, fontSize: 15)),
          const Spacer(),
          Text(value, style: const TextStyle(color: text, fontSize: 15)),
        ],
      ),
    );
  }
}

class BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;

  const BottomNav({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['首页', '临时借车', '设置'];
    const icons = [
      Icons.home,
      Icons.people_outline,
      Icons.settings,
    ];

    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: Color(0xFF030B11),
        border: Border(top: BorderSide(color: line)),
      ),
      child: Row(
        children: List.generate(3, (index) {
          final active = current == index;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icons[index],
                    size: 28,
                    color: active ? blue : muted,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    labels[index],
                    style: TextStyle(
                      color: active ? blue : muted,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

BoxDecoration cyberBox(Color color, {double radius = 10}) {
  return BoxDecoration(
    color: panel,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: color.withOpacity(.72), width: 1),
    boxShadow: [
      BoxShadow(
        color: color.withOpacity(.27),
        blurRadius: 12,
        spreadRadius: 0.5,
      ),
    ],
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [panel2, Color(0xFF03090F)],
    ),
  );
}

void openPage(BuildContext context, Widget page) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => page),
  );
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFF0B1B26),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

class TechBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF1A82D1).withOpacity(.25);

    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x - 80, size.height), paint);
    }

    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF007AFF).withOpacity(.42);

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2 - 25),
      90,
      circlePaint,
    );

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2 - 25),
      58,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
