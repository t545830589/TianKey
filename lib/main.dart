import 'dart:ui';
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
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'sans',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF02070E),
      ),
      home: const TianKeyHome(),
    );
  }
}

class TianKeyHome extends StatefulWidget {
  const TianKeyHome({super.key});

  @override
  State<TianKeyHome> createState() => _TianKeyHomeState();
}

class _TianKeyHomeState extends State<TianKeyHome> {
  int _tabIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    BorrowPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _pages[_tabIndex],
      ),
      bottomNavigationBar: CyberBottomBar(
        currentIndex: _tabIndex,
        onChanged: (index) {
          setState(() => _tabIndex = index);
        },
      ),
    );
  }
}

/* =========================
   基础颜色与工具
========================= */

const Color kBg = Color(0xFF02070E);
const Color kPanel = Color(0xFF07111D);
const Color kPanel2 = Color(0xFF0A1725);
const Color kBlue = Color(0xFF00B8FF);
const Color kBlueLight = Color(0xFF39D8FF);
const Color kOrange = Color(0xFFFF8A27);
const Color kRed = Color(0xFFFF2E2E);
const Color kText = Color(0xFFE8F5FF);
const Color kGrey = Color(0xFF8995A5);

void showCyberMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: const Color(0xFF0A1725),
      behavior: SnackBarBehavior.floating,
      content: Text(
        message,
        style: const TextStyle(color: kText),
      ),
    ),
  );
}

BoxDecoration cyberPanel({Color borderColor = kBlue, double radius = 14}) {
  return BoxDecoration(
    color: kPanel,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor.withOpacity(.48), width: 1),
    boxShadow: [
      BoxShadow(
        color: borderColor.withOpacity(.10),
        blurRadius: 20,
        spreadRadius: 1,
      ),
    ],
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF0B1825).withOpacity(.95),
        const Color(0xFF030810).withOpacity(.98),
      ],
    ),
  );
}

/* =========================
   首页
========================= */

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        children: [
          const TopHeader(
            title: 'Tian Key',
            leftIcon: Icons.settings_outlined,
            rightIcon: Icons.help_outline_rounded,
          ),
          const SizedBox(height: 14),

          // 红色昂克赛拉主图区
          const CarHeroCard(),
          const SizedBox(height: 14),

          const StatusRow(),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: CyberButton(
                  label: '连接设备',
                  icon: Icons.bluetooth_rounded,
                  color: kBlue,
                  onTap: () => showCyberMessage(
                    context,
                    '尚未连接设备：请先完成设备配对。',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CyberButton(
                  label: '管理员授权',
                  icon: Icons.admin_panel_settings_outlined,
                  color: kOrange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminAuthorizationPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.55,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: [
              CyberButton(
                label: '锁车',
                icon: Icons.lock_rounded,
                color: kBlue,
                onTap: () => showCyberMessage(context, '锁车：设备未连接'),
              ),
              CyberButton(
                label: '解锁',
                icon: Icons.lock_open_rounded,
                color: kBlue,
                onTap: () => showCyberMessage(context, '解锁：设备未连接'),
              ),
              CyberButton(
                label: '车窗升',
                icon: Icons.keyboard_double_arrow_up_rounded,
                color: kOrange,
                onTap: () => showCyberMessage(context, '车窗升：设备未连接'),
              ),
              CyberButton(
                label: '车窗降',
                icon: Icons.keyboard_double_arrow_down_rounded,
                color: kOrange,
                onTap: () => showCyberMessage(context, '车窗降：设备未连接'),
              ),
              CyberButton(
                label: '寻车',
                icon: Icons.sensors_rounded,
                color: kBlue,
                onTap: () => showCyberMessage(context, '寻车：设备未连接'),
              ),
              CyberButton(
                label: '后备箱',
                icon: Icons.directions_car_filled_outlined,
                color: kBlue,
                onTap: () => showCyberMessage(context, '后备箱：设备未连接'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TopHeader extends StatelessWidget {
  final String title;
  final IconData leftIcon;
  final IconData rightIcon;

  const TopHeader({
    super.key,
    required this.title,
    required this.leftIcon,
    required this.rightIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(leftIcon, color: kBlueLight, size: 27),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kText,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              shadows: [
                Shadow(color: kBlue, blurRadius: 12),
              ],
            ),
          ),
        ),
        Icon(rightIcon, color: kBlueLight, size: 27),
      ],
    );
  }
}

class CarHeroCard extends StatelessWidget {
  const CarHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 238,
      width: double.infinity,
      decoration: cyberPanel(borderColor: kBlue),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: .28,
              child: CustomPaint(
                painter: GridPainter(),
              ),
            ),
          ),
          Positioned(
            top: 19,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kBlue.withOpacity(.46),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 若你的 1.png 就是红色昂克赛拉图片，会自动显示。
          // 若不是，把 pubspec.yaml 里的图片路径及此处名称改成正确文件名。
          Positioned(
            top: 28,
            left: 12,
            right: 12,
            child: SizedBox(
              height: 155,
              child: Image.asset(
                '1.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.directions_car_filled_rounded,
                  size: 122,
                  color: Color(0xFFE52028),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF063A80),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: kBlueLight),
                boxShadow: [
                  BoxShadow(
                    color: kBlue.withOpacity(.60),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Text(
                '陕A0P92Y',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
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

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kBlue.withOpacity(.28)
      ..strokeWidth = .5;

    for (double x = 0; x < size.width; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StatusRow extends StatelessWidget {
  const StatusRow({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatusData('设备状态', '未连接', Icons.bluetooth_disabled_rounded),
      _StatusData('管理员状态', '未授权', Icons.shield_outlined),
      _StatusData('供电状态', '未知', Icons.bolt_outlined),
      _StatusData('时间同步', '未同步', Icons.schedule_outlined),
      _StatusData('临时借车', '无有效密码', Icons.key_off_rounded),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: cyberPanel(borderColor: const Color(0xFF33475F)),
      child: Row(
        children: items
            .map(
              (item) => Expanded(
                child: Column(
                  children: [
                    Icon(item.icon, color: kGrey, size: 23),
                    const SizedBox(height: 5),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: kGrey, fontSize: 10),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: kGrey, fontSize: 10),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StatusData {
  final String title;
  final String value;
  final IconData icon;

  _StatusData(this.title, this.value, this.icon);
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
  String selectedTime = '5分钟';

  final List<String> times = ['5分钟', '1天', '3天', '7天'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        children: [
          const TopHeader(
            title: '临时借车',
            leftIcon: Icons.arrow_back_ios_new_rounded,
            rightIcon: Icons.list_alt_rounded,
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: cyberPanel(borderColor: const Color(0xFF4E6278)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('当前状态', style: TextStyle(color: kGrey, fontSize: 13)),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.key_off_rounded, color: kGrey, size: 28),
                    SizedBox(width: 10),
                    Text(
                      '无有效临时密码',
                      style: TextStyle(
                        color: kText,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF26394A), height: 30),
                const Text('选择有效时间', style: TextStyle(color: kGrey, fontSize: 13)),
                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: times.map((time) {
                    final isSelected = time == selectedTime;
                    return InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: () => setState(() => selectedTime = time),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? kBlue.withOpacity(.16)
                              : const Color(0xFF09131E),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: isSelected ? kBlueLight : const Color(0xFF33485B),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: kBlue.withOpacity(.40),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            color: isSelected ? kText : kGrey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                const Text('临时密码', style: TextStyle(color: kGrey, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 82,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF030A12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF3B5065),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, color: kGrey, size: 27),
                      SizedBox(height: 5),
                      Text('尚未生成', style: TextStyle(color: kGrey, fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CyberButton(
            label: '生成临时密码',
            icon: Icons.vpn_key_rounded,
            color: kBlue,
            wide: true,
            onTap: () => showCyberMessage(
              context,
              '尚未连接设备，无法生成临时密码。',
            ),
          ),
          const SizedBox(height: 12),
          CyberButton(
            label: '取消借车',
            icon: Icons.cancel_outlined,
            color: kRed,
            wide: true,
            onTap: () => showCyberMessage(
              context,
              '当前没有有效临时借车。',
            ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        children: [
          const TopHeader(
            title: '设置',
            leftIcon: Icons.arrow_back_ios_new_rounded,
            rightIcon: Icons.settings_rounded,
          ),
          const SizedBox(height: 18),

          Container(
            decoration: cyberPanel(borderColor: const Color(0xFF4E6278)),
            child: Column(
              children: [
                SettingTile(
                  icon: Icons.key_rounded,
                  title: '修改蓝牙密码',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangeBluetoothPage()),
                  ),
                ),
                SettingTile(
                  icon: Icons.restart_alt_rounded,
                  title: '恢复默认蓝牙密码',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RestoreBluetoothPage()),
                  ),
                ),
                SettingTile(
                  icon: Icons.phone_android_rounded,
                  title: '设备名称',
                  value: '陕A0P92Y',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DeviceNamePage()),
                  ),
                ),
                SettingTile(
                  icon: Icons.schedule_rounded,
                  title: '时间同步设置',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TimeSyncPage()),
                  ),
                ),
                SettingSwitchTile(
                  icon: Icons.bluetooth_searching_rounded,
                  title: '自动连接设置',
                  value: autoConnect,
                  onChanged: (value) => setState(() => autoConnect = value),
                ),
                SettingSwitchTile(
                  icon: Icons.volume_up_outlined,
                  title: '提示音设置',
                  value: sound,
                  onChanged: (value) => setState(() => sound = value),
                ),
                SettingTile(
                  icon: Icons.info_outline_rounded,
                  title: '关于系统',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutPage()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const InitialStateTip(),
        ],
      ),
    );
  }
}

class InitialStateTip extends StatelessWidget {
  const InitialStateTip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF07111D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF25394E)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: kGrey),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '当前为首次安装初始状态：未连接设备、未授权、未同步时间。',
              style: TextStyle(color: kGrey, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================
   设置子页面
========================= */

class CyberSubPage extends StatelessWidget {
  final String title;
  final Widget child;

  const CyberSubPage({
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: kBlueLight,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kText,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 28),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class AdminAuthorizationPage extends StatelessWidget {
  const AdminAuthorizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CyberSubPage(
      title: '管理员授权',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: cyberPanel(borderColor: kOrange),
        child: Column(
          children: [
            const Icon(
              Icons.admin_panel_settings_rounded,
              size: 82,
              color: kOrange,
            ),
            const SizedBox(height: 20),
            const Text(
              '管理员状态：未授权',
              style: TextStyle(color: kText, fontSize: 18),
            ),
            const SizedBox(height: 12),
            const Text(
              '首次使用需完成管理员身份验证。为保护安全，此界面不展示或保存任何密码内容。',
              textAlign: TextAlign.center,
              style: TextStyle(color: kGrey, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 24),
            const CyberInput(label: '管理员验证信息', hint: '请输入授权信息'),
            const SizedBox(height: 18),
            CyberButton(
              label: '确认授权',
              icon: Icons.verified_user_outlined,
              color: kOrange,
              wide: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class ChangeBluetoothPage extends StatelessWidget {
  const ChangeBluetoothPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CyberSubPage(
      title: '修改蓝牙密码',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: cyberPanel(borderColor: kBlue),
        child: Column(
          children: [
            const Icon(Icons.key_rounded, size: 72, color: kBlueLight),
            const SizedBox(height: 20),
            const Text(
              '设备未连接',
              style: TextStyle(color: kText, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              '连接设备并完成管理员授权后，才可修改蓝牙密码。',
              textAlign: TextAlign.center,
              style: TextStyle(color: kGrey, fontSize: 13),
            ),
            const SizedBox(height: 22),
            const CyberInput(label: '当前蓝牙密码', hint: '请输入当前蓝牙密码'),
            const SizedBox(height: 12),
            const CyberInput(label: '新蓝牙密码', hint: '请输入新蓝牙密码'),
            const SizedBox(height: 12),
            const CyberInput(label: '确认新密码', hint: '请再次输入新密码'),
            const SizedBox(height: 18),
            CyberButton(
              label: '保存新密码',
              icon: Icons.save_outlined,
              color: kBlue,
              wide: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class RestoreBluetoothPage extends StatelessWidget {
  const RestoreBluetoothPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CyberSubPage(
      title: '恢复默认蓝牙密码',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: cyberPanel(borderColor: kRed),
        child: Column(
          children: [
            const Icon(Icons.restart_alt_rounded, color: kBlueLight, size: 82),
            const SizedBox(height: 20),
            const Text(
              '恢复后蓝牙密码将重置为出厂默认值',
              textAlign: TextAlign.center,
              style: TextStyle(color: kText, fontSize: 17),
            ),
            const SizedBox(height: 12),
            const Text(
              '为了安全，默认密码内容不会在 APP 内显示。',
              textAlign: TextAlign.center,
              style: TextStyle(color: kGrey, fontSize: 13),
            ),
            const SizedBox(height: 28),
            CyberButton(
              label: '恢复默认蓝牙密码',
              icon: Icons.restart_alt_rounded,
              color: kRed,
              wide: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceNamePage extends StatelessWidget {
  const DeviceNamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CyberSubPage(
      title: '设备名称',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: cyberPanel(borderColor: kBlue),
        child: Column(
          children: [
            const Icon(Icons.phone_android_rounded, size: 78, color: kBlueLight),
            const SizedBox(height: 20),
            const Text(
              '设备名称',
              style: TextStyle(color: kGrey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '陕A0P92Y',
              style: TextStyle(
                color: kText,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 22),
            const CyberInput(label: '新设备名称', hint: '陕A0P92Y'),
            const SizedBox(height: 18),
            CyberButton(
              label: '保存',
              icon: Icons.save_outlined,
              color: kBlue,
              wide: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class TimeSyncPage extends StatelessWidget {
  const TimeSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CyberSubPage(
      title: '时间同步设置',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: cyberPanel(borderColor: kBlue),
        child: Column(
          children: [
            const Icon(Icons.schedule_rounded, color: kBlueLight, size: 84),
            const SizedBox(height: 18),
            const Text('当前状态：未同步', style: TextStyle(color: kText, fontSize: 18)),
            const SizedBox(height: 10),
            const Text(
              '连接设备后可同步手机当前时间。',
              style: TextStyle(color: kGrey, fontSize: 13),
            ),
            const SizedBox(height: 25),
            CyberButton(
              label: '立即同步',
              icon: Icons.sync_rounded,
              color: kBlue,
              wide: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CyberSubPage(
      title: '关于系统',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: cyberPanel(borderColor: kBlue),
        child: const Column(
          children: [
            Icon(Icons.directions_car_filled_rounded, size: 80, color: kBlueLight),
            SizedBox(height: 18),
            Text(
              'Tian Key',
              style: TextStyle(
                color: kText,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            SizedBox(height: 28),
            AboutLine('车型', '马自达昂克赛拉'),
            AboutLine('车牌', '陕A0P92Y'),
            AboutLine('设备', 'ESP32'),
            AboutLine('设备状态', '未连接设备'),
          ],
        ),
      ),
    );
  }
}

class AboutLine extends StatelessWidget {
  final String left;
  final String right;

  const AboutLine(this.left, this.right, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Text(left, style: const TextStyle(color: kGrey, fontSize: 15)),
          const Spacer(),
          Text(
            right,
            style: const TextStyle(color: kText, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

/* =========================
   通用组件
========================= */

class CyberButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool wide;

  const CyberButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: wide ? double.infinity : null,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 1.2),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(.29),
                const Color(0xFF07101B),
                color.withOpacity(.13),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(.35),
                blurRadius: 13,
                spreadRadius: .2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: kText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(color: color.withOpacity(.8), blurRadius: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CyberInput extends StatelessWidget {
  final String label;
  final String hint;

  const CyberInput({
    super.key,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: true,
      style: const TextStyle(color: kText),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF5B6979)),
        labelStyle: const TextStyle(color: kGrey),
        suffixIcon: const Icon(Icons.visibility_off_outlined, color: kGrey),
        filled: true,
        fillColor: const Color(0xFF040B13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFF30485C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: kBlueLight),
        ),
      ),
    );
  }
}

class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;

  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF1E3243)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: kBlueLight, size: 23),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: kText, fontSize: 16),
              ),
            ),
            if (value != null)
              Text(value!, style: const TextStyle(color: kGrey, fontSize: 13)),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right_rounded, color: kGrey),
          ],
        ),
      ),
    );
  }
}

class SettingSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E3243))),
      ),
      child: Row(
        children: [
          Icon(icon, color: kBlueLight, size: 23),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: kText, fontSize: 16),
            ),
          ),
          Text(
            value ? '开启' : '关闭',
            style: const TextStyle(color: kGrey, fontSize: 12),
          ),
          Switch(
            value: value,
            activeColor: kBlueLight,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class CyberBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const CyberBottomBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _BottomItem(Icons.home_filled, '首页'),
      _BottomItem(Icons.group_outlined, '临时借车'),
      _BottomItem(Icons.settings_rounded, '设置'),
    ];

    return Container(
      height: 78,
      decoration: const BoxDecoration(
        color: Color(0xFF07101B),
        border: Border(top: BorderSide(color: Color(0xFF1A3D58))),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = currentIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    color: selected ? kBlueLight : kGrey,
                    size: 27,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: selected ? kBlueLight : kGrey,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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

class _BottomItem {
  final IconData icon;
  final String label;

  _BottomItem(this.icon, this.label);
}
