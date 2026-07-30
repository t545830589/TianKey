import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 永远锁定竖屏，防止模拟器变横屏。
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const TianKeyApp());
}

/* =========================
   全局颜色
========================= */

const Color kBg = Color(0xFF02070B);
const Color kPanel = Color(0xFF06121A);
const Color kPanelLight = Color(0xFF0A1A25);
const Color kBlue = Color(0xFF009DFF);
const Color kCyan = Color(0xFF50D8FF);
const Color kOrange = Color(0xFFFF7A18);
const Color kRed = Color(0xFFFF1616);
const Color kText = Color(0xFFE8F6FF);
const Color kMuted = Color(0xFF8998A4);
const Color kLine = Color(0xFF1B4057);

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
        scaffoldBackgroundColor: kBg,
        fontFamily: 'sans',
      ),
      home: const AppShell(),
    );
  }
}

/* =========================
   主框架：首页 / 借车 / 设置
========================= */

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        goToSettings: () => setState(() => currentTab = 2),
      ),
      const BorrowPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[currentTab]),
      bottomNavigationBar: CyberBottomNav(
        currentIndex: currentTab,
        onChanged: (index) {
          setState(() => currentTab = index);
        },
      ),
    );
  }
}

/* =========================
   首页
========================= */

class HomePage extends StatelessWidget {
  final VoidCallback goToSettings;

  const HomePage({
    super.key,
    required this.goToSettings,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      child: Column(
        children: [
          Row(
            children: [
              HeaderCircleButton(
                icon: Icons.settings_rounded,
                onTap: goToSettings,
              ),
              const Expanded(
                child: Text(
                  'Tian Key',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kCyan,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(color: kBlue, blurRadius: 15),
                    ],
                  ),
                ),
              ),
              HeaderCircleButton(
                icon: Icons.question_mark_rounded,
                onTap: () => openPage(context, const AboutPage()),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 首页主视觉：机械线路 + 红色车辆轮廓。
          const HomeHero(),
          const SizedBox(height: 10),

          const Row(
            children: [
              Expanded(
                child: StatusCard(
                  title: '设备状态',
                  icon: Icons.bluetooth_disabled_rounded,
                  value: '未连接',
                ),
              ),
              SizedBox(width: 5),
              Expanded(
                child: StatusCard(
                  title: '管理员状态',
                  icon: Icons.shield_outlined,
                  value: '未授权',
                ),
              ),
              SizedBox(width: 5),
              Expanded(
                child: StatusCard(
                  title: '供电状态',
                  icon: Icons.bolt_outlined,
                  value: '未知',
                ),
              ),
              SizedBox(width: 5),
              Expanded(
                child: StatusCard(
                  title: '时间同步',
                  icon: Icons.access_time_outlined,
                  value: '未同步',
                ),
              ),
              SizedBox(width: 5),
              Expanded(
                child: StatusCard(
                  title: '临时借车',
                  icon: Icons.key_outlined,
                  value: '无有效密码',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: GlowButton(
                  label: '连接设备',
                  icon: Icons.bluetooth_rounded,
                  color: kBlue,
                  onTap: () => showToast(context, '未发现设备：请先开启蓝牙并靠近 ESP32。'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: GlowButton(
                  label: '管理员授权',
                  icon: Icons.shield_outlined,
                  color: kOrange,
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
                  icon: Icons.lock_rounded,
                  color: kBlue,
                  onTap: () => showToast(context, '锁车失败：设备尚未连接。'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: GlowButton(
                  label: '解锁',
                  icon: Icons.lock_open_rounded,
                  color: kBlue,
                  onTap: () => showToast(context, '解锁失败：设备尚未连接。'),
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
                  icon: Icons.keyboard_double_arrow_up_rounded,
                  color: kOrange,
                  onTap: () => showToast(context, '车窗升失败：设备尚未连接。'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: GlowButton(
                  label: '车窗降',
                  icon: Icons.keyboard_double_arrow_down_rounded,
                  color: kOrange,
                  onTap: () => showToast(context, '车窗降失败：设备尚未连接。'),
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
                  icon: Icons.sensors_rounded,
                  color: kBlue,
                  onTap: () => showToast(context, '寻车失败：设备尚未连接。'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: GlowButton(
                  label: '后备箱',
                  icon: Icons.directions_car_outlined,
                  color: kBlue,
                  onTap: () => showToast(context, '后备箱失败：设备尚未连接。'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomeHero extends StatelessWidget {
  const HomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 248,
      decoration: cyberBox(kBlue, radius: 14),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: MechanicalPainter(),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 18),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kBlue.withOpacity(.7)),
                boxShadow: [
                  BoxShadow(
                    color: kBlue.withOpacity(.32),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Icon(
                Icons.memory_rounded,
                color: kCyan,
                size: 38,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, .30),
            child: Container(
              width: 310,
              height: 102,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(58),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF7A0000),
                    Color(0xFFED0808),
                    Color(0xFF700000),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: kRed.withOpacity(.45),
                    blurRadius: 25,
                  ),
                ],
                border: Border.all(color: const Color(0xFFFF5B5B), width: 1.2),
              ),
              child: Stack(
                children: [
                  const Positioned(
                    top: 22,
                    left: 38,
                    child: Icon(Icons.wb_sunny_outlined, color: kCyan),
                  ),
                  const Positioned(
                    top: 22,
                    right: 38,
                    child: Icon(Icons.wb_sunny_outlined, color: kCyan),
                  ),
                  Center(
                    child: Icon(
                      Icons.directions_car_filled_rounded,
                      color: const Color(0xFF8F0000).withOpacity(.72),
                      size: 74,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, .73),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF12539A),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: kCyan.withOpacity(.75)),
              ),
              child: const Text(
                '陕A·0P92Y',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================
   临时借车
========================= */

class BorrowPage extends StatefulWidget {
  const BorrowPage({super.key});

  @override
  State<BorrowPage> createState() => _BorrowPageState();
}

class _BorrowPageState extends State<BorrowPage> {
  final List<String> times = ['5分钟', '1天', '2天', '3天', '4天', '5天', '6天', '7天'];

  int selectedTime = 0;
  String? tempPassword;

  String randomPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      6,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  void createPassword() {
    setState(() {
      tempPassword = randomPassword();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isGenerated = tempPassword != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      child: Column(
        children: [
          const PageHeader(title: '临时借车'),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: cyberBox(kLine),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('当前状态', style: TextStyle(color: kMuted, fontSize: 12)),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.key_outlined, color: kMuted, size: 26),
                    SizedBox(width: 10),
                    Text(
                      '无有效临时密码',
                      style: TextStyle(
                        color: kMuted,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '选择有效时间',
              style: TextStyle(color: kMuted, fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),

          GridView.builder(
            itemCount: times.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.85,
            ),
            itemBuilder: (context, index) {
              final selected = index == selectedTime;
              return InkWell(
                onTap: () => setState(() => selectedTime = index),
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  decoration: cyberBox(selected ? kBlue : kLine, radius: 7),
                  alignment: Alignment.center,
                  child: Text(
                    times[index],
                    style: TextStyle(
                      color: selected ? kCyan : kText,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: cyberBox(kLine),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('临时密码', style: TextStyle(color: kMuted, fontSize: 13)),
                const SizedBox(height: 10),
                Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isGenerated ? kBlue : kMuted.withOpacity(.35),
                      width: 1,
                    ),
                    color: const Color(0xFF030A10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isGenerated ? tempPassword! : '尚未生成',
                    style: TextStyle(
                      color: isGenerated ? kCyan : kMuted,
                      fontSize: isGenerated ? 29 : 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: isGenerated ? 5 : 0,
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                InkWell(
                  onTap: !isGenerated
                      ? null
                      : () async {
                          await Clipboard.setData(
                            ClipboardData(text: tempPassword!),
                          );
                          if (context.mounted) {
                            showToast(context, '临时密码已复制到剪贴板。');
                          }
                        },
                  child: Container(
                    height: 40,
                    decoration: cyberBox(isGenerated ? kBlue : kLine, radius: 7),
                    alignment: Alignment.center,
                    child: Text(
                      '▣   复制密码',
                      style: TextStyle(
                        color: isGenerated ? kCyan : kMuted,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          GlowButton(
            label: '生成临时密码',
            icon: Icons.key_rounded,
            color: kBlue,
            onTap: createPassword,
          ),
          const SizedBox(height: 10),
          GlowButton(
            label: '取消借车',
            icon: Icons.cancel_outlined,
            color: kRed,
            onTap: () {
              setState(() => tempPassword = null);
              showToast(context, '临时借车已取消。');
            },
          ),
        ],
      ),
    );
  }
}

/* =========================
   设置
========================= */

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool autoConnect = false;
  bool sound = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      child: Column(
        children: [
          const PageHeader(title: '设置'),
          const SizedBox(height: 12),
          Container(
            decoration: cyberBox(kLine),
            child: Column(
              children: [
                SettingRow(
                  icon: Icons.bluetooth_rounded,
                  title: '修改蓝牙密码',
                  onTap: () => openPage(context, const ChangeBluetoothPage()),
                ),
                SettingRow(
                  icon: Icons.restart_alt_rounded,
                  title: '恢复默认蓝牙密码',
                  onTap: () => openPage(context, const RestoreBluetoothPage()),
                ),
                SettingRow(
                  icon: Icons.phone_android_rounded,
                  title: '设备名称',
                  value: '陕A·0P92Y',
                  onTap: () => openPage(context, const DeviceNamePage()),
                ),
                SettingRow(
                  icon: Icons.access_time_rounded,
                  title: '时间同步设置',
                  onTap: () => openPage(context, const TimeSyncPage()),
                ),
                SettingRow(
                  icon: Icons.link_rounded,
                  title: '自动连接设置',
                  value: autoConnect ? '开启' : '关闭',
                  onTap: () {
                    setState(() => autoConnect = !autoConnect);
                    showToast(context, autoConnect ? '自动连接已开启。' : '自动连接已关闭。');
                  },
                ),
                SettingRow(
                  icon: Icons.volume_up_outlined,
                  title: '提示音设置',
                  value: sound ? '开启' : '关闭',
                  onTap: () {
                    setState(() => sound = !sound);
                    showToast(context, sound ? '提示音已开启。' : '提示音已关闭。');
                  },
                ),
                SettingRow(
                  icon: Icons.info_outline_rounded,
                  title: '关于系统',
                  onTap: () => openPage(context, const AboutPage()),
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================
   授权 / 设置子页面
========================= */

class AdminAuthPage extends StatefulWidget {
  const AdminAuthPage({super.key});

  @override
  State<AdminAuthPage> createState() => _AdminAuthPageState();
}

class _AdminAuthPageState extends State<AdminAuthPage> {
  final controller = TextEditingController();
  bool showText = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: '管理员授权',
      child: Column(
        children: [
          const SizedBox(height: 25),
          const Icon(Icons.admin_panel_settings_outlined, color: kOrange, size: 88),
          const SizedBox(height: 18),
          const Text(
            '请输入管理员密码进行授权',
            style: TextStyle(color: kText, fontSize: 16),
          ),
          const SizedBox(height: 22),
          TechTextField(
            label: '管理员密码',
            hint: '请输入管理员密码',
            controller: controller,
            obscure: !showText,
            onEyeTap: () => setState(() => showText = !showText),
          ),
          const SizedBox(height: 18),
          GlowButton(
            label: '确认授权',
            icon: Icons.verified_user_outlined,
            color: kOrange,
            onTap: () {
              if (controller.text.trim().isEmpty) {
                showToast(context, '请先输入管理员密码。');
              } else {
                showToast(context, '授权请求已提交。');
              }
            },
          ),
        ],
      ),
    );
  }
}

class ChangeBluetoothPage extends StatefulWidget {
  const ChangeBluetoothPage({super.key});

  @override
  State<ChangeBluetoothPage> createState() => _ChangeBluetoothPageState();
}

class _ChangeBluetoothPageState extends State<ChangeBluetoothPage> {
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();

  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: '修改蓝牙密码',
      child: Column(
        children: [
          TechTextField(
            label: '当前蓝牙密码',
            hint: '请输入当前蓝牙密码',
            controller: current,
            obscure: true,
          ),
          const SizedBox(height: 14),
          TechTextField(
            label: '新蓝牙密码',
            hint: '请输入新蓝牙密码',
            controller: next,
            obscure: true,
          ),
          const SizedBox(height: 14),
          TechTextField(
            label: '确认新密码',
            hint: '请再次输入新密码',
            controller: confirm,
            obscure: true,
          ),
          const SizedBox(height: 20),
          GlowButton(
            label: '保存新密码',
            icon: Icons.save_outlined,
            color: kBlue,
            onTap: () {
              if (next.text.isEmpty || confirm.text.isEmpty) {
                showToast(context, '请完整输入新密码。');
              } else if (next.text != confirm.text) {
                showToast(context, '两次输入的新密码不一致。');
              } else {
                showToast(context, '新蓝牙密码已保存。');
              }
            },
          ),
        ],
      ),
    );
  }
}

class RestoreBluetoothPage extends StatelessWidget {
  const RestoreBluetoothPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: '恢复默认蓝牙密码',
      child: Column(
        children: [
          const SizedBox(height: 35),
          const Icon(Icons.restart_alt_rounded, color: kCyan, size: 92),
          const SizedBox(height: 25),
          const Text(
            '恢复后蓝牙密码将重置为\n出厂默认值',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kText,
              fontSize: 17,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          GlowButton(
            label: '恢复默认蓝牙密码',
            icon: Icons.restart_alt_rounded,
            color: kRed,
            onTap: () => showToast(context, '恢复请求已提交，请先连接设备。'),
          ),
        ],
      ),
    );
  }
}

class DeviceNamePage extends StatefulWidget {
  const DeviceNamePage({super.key});

  @override
  State<DeviceNamePage> createState() => _DeviceNamePageState();
}

class _DeviceNamePageState extends State<DeviceNamePage> {
  final controller = TextEditingController(text: '陕A·0P92Y');

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: '设备名称',
      child: Column(
        children: [
          const SizedBox(height: 25),
          const Icon(Icons.phone_android_rounded, color: kCyan, size: 80),
          const SizedBox(height: 24),
          TechTextField(
            label: '设备名称',
            hint: '请输入设备名称',
            controller: controller,
          ),
          const SizedBox(height: 10),
          const Text(
            '设备名称将用于蓝牙连接和设备识别',
            style: TextStyle(color: kMuted, fontSize: 12),
          ),
          const SizedBox(height: 22),
          GlowButton(
            label: '保存',
            icon: Icons.save_outlined,
            color: kBlue,
            onTap: () => showToast(context, '设备名称已保存。'),
          ),
        ],
      ),
    );
  }
}

class TimeSyncPage extends StatelessWidget {
  const TimeSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: '时间同步设置',
      child: Column(
        children: [
          const SizedBox(height: 30),
          const Icon(Icons.access_time_rounded, color: kCyan, size: 88),
          const SizedBox(height: 20),
          const Text('当前状态', style: TextStyle(color: kMuted, fontSize: 14)),
          const SizedBox(height: 8),
          const Text(
            '未同步',
            style: TextStyle(color: kText, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 25),
          GlowButton(
            label: '立即同步',
            icon: Icons.sync_rounded,
            color: kBlue,
            onTap: () => showToast(context, '同步失败：设备尚未连接。'),
          ),
          const SizedBox(height: 10),
          const Text(
            '同步后将自动校准设备时间',
            style: TextStyle(color: kMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: '关于系统',
      child: Column(
        children: [
          const SizedBox(height: 28),
          const Icon(Icons.directions_car_filled_outlined, color: kCyan, size: 82),
          const SizedBox(height: 14),
          const Text(
            'Tian Key',
            style: TextStyle(
              color: kCyan,
              fontSize: 29,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 28),
          const AboutRow(label: '车型', value: '马自达昂克赛拉'),
          const AboutRow(label: '车牌', value: '陕A·0P92Y'),
          const AboutRow(label: '设备', value: 'ESP32'),
          const AboutRow(label: '设备状态', value: '未连接设备'),
        ],
      ),
    );
  }
}

class AboutRow extends StatelessWidget {
  final String label;
  final String value;

  const AboutRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: cyberBox(kLine),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: kMuted, fontSize: 14)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: kText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================
   通用页面组件
========================= */

class SubPage extends StatelessWidget {
  final String title;
  final Widget child;

  const SubPage({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
          child: Column(
            children: [
              PageHeader(
                title: title,
                showBack: true,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: cyberBox(kLine),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final bool showBack;

  const PageHeader({
    super.key,
    required this.title,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 45,
          child: showBack
              ? InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: kText),
                )
              : null,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kText,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 45),
      ],
    );
  }
}

class HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const HeaderCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: 49,
        height: 49,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF050D14),
          border: Border.all(color: kLine),
        ),
        child: Icon(icon, color: kText, size: 28),
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;

  const StatusCard({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
      decoration: cyberBox(kLine, radius: 6),
      child: Column(
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: kMuted, fontSize: 10),
          ),
          const Spacer(),
          Icon(icon, color: kMuted, size: 23),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: kMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class GlowButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const GlowButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 52,
        decoration: cyberBox(color, radius: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color == kOrange ? kOrange : kCyan, size: 26),
            const SizedBox(width: 13),
            Text(
              label,
              style: TextStyle(
                color: color == kOrange ? const Color(0xFFFFB17A) : kText,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;
  final bool isLast;

  const SettingRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: kLine)),
        ),
        child: Row(
          children: [
            Icon(icon, color: kCyan, size: 22),
            const SizedBox(width: 14),
            Text(title, style: const TextStyle(color: kText, fontSize: 15)),
            const Spacer(),
            if (value != null)
              Text(value!, style: const TextStyle(color: kMuted, fontSize: 13)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: kMuted),
          ],
        ),
      ),
    );
  }
}

class TechTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback? onEyeTap;

  const TechTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.onEyeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: kMuted, fontSize: 13)),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: kText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF52616D), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFF030A10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: kLine),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: kBlue),
            ),
            suffixIcon: onEyeTap == null
                ? null
                : IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: kMuted,
                    ),
                    onPressed: onEyeTap,
                  ),
          ),
        ),
      ],
    );
  }
}

class CyberBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const CyberBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['首页', '临时借车', '设置'];
    const icons = [
      Icons.home_rounded,
      Icons.people_outline_rounded,
      Icons.settings_rounded,
    ];

    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: Color(0xFF030A10),
        border: Border(top: BorderSide(color: kLine)),
      ),
      child: Row(
        children: List.generate(3, (index) {
          final active = index == currentIndex;

          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icons[index],
                    color: active ? kBlue : kMuted,
                    size: 27,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    labels[index],
                    style: TextStyle(
                      color: active ? kBlue : kMuted,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.normal,
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
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: color.withOpacity(.72), width: 1),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        kPanelLight,
        Color(0xFF02090F),
      ],
    ),
    boxShadow: [
      BoxShadow(
        color: color.withOpacity(.24),
        blurRadius: 12,
        spreadRadius: 0.2,
      ),
    ],
  );
}

void openPage(BuildContext context, Widget page) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => page),
  );
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFF0B1B27),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

class MechanicalPainter extends CustomPainter {
  const MechanicalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = kBlue.withOpacity(.26);

    for (double x = -100; x < size.width + 100; x += 25) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - 75, size.height),
        linePaint,
      );
    }

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = kBlue.withOpacity(.38);

    final center = Offset(size.width / 2, size.height * .42);

    canvas.drawCircle(center, 67, ringPaint);
    canvas.drawCircle(center, 45, ringPaint);
    canvas.drawCircle(center, 23, ringPaint);

    final glow = Paint()
      ..color = kBlue.withOpacity(.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    canvas.drawCircle(center, 10, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
