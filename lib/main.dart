import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'Tian Key V11 UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF030710), // 赛博超深蓝黑底色
        primaryColor: const Color(0xFF00F0FF),
      ),
      home: const NinePagesScrollViewer(),
    );
  }
}

// =========================================================================
// 9 页全量横向滑动展示控制器 (可滑动滑动浏览全套 9 页UI)
// =========================================================================
class NinePagesScrollViewer extends StatefulWidget {
  const NinePagesScrollViewer({Key? key}) : super(key: key);

  @override
  State<NinePagesScrollViewer> createState() => _NinePagesScrollViewerState();
}

class _NinePagesScrollViewerState extends State<NinePagesScrollViewer> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _pageTitles = [
    "1.首页",
    "2.临时借车",
    "3.设置",
    "4.管理员授权",
    "5.修改蓝牙密码",
    "6.恢复默认密码",
    "7.设备名称",
    "8.时间同步",
    "9.关于系统",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部 9 页切换控制胶囊条
            Container(
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF07101E),
                border: Border(bottom: BorderSide(color: Color(0xFF00F0FF), width: 0.8)),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _pageTitles.length,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemBuilder: (context, index) {
                  bool isSelected = _currentPage == index;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFF0B172A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFF1B355A),
                        ),
                        boxShadow: isSelected
                            ? [const BoxShadow(color: Color(0xFF00F0FF), blurRadius: 8)]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          _pageTitles[index],
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 9 页横向滑动主区域
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: const [
                  PhoneMockupFrame(child: Page1Home()),
                  PhoneMockupFrame(child: Page2TempBorrow()),
                  PhoneMockupFrame(child: Page3Settings()),
                  PhoneMockupFrame(child: Page4AdminAuth()),
                  PhoneMockupFrame(child: Page5ModifyBlePass()),
                  PhoneMockupFrame(child: Page6RestoreDefault()),
                  PhoneMockupFrame(child: Page7DeviceName()),
                  PhoneMockupFrame(child: Page8TimeSync()),
                  PhoneMockupFrame(child: Page9AboutSystem()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 手机机身渲染容器外壳（确保比例精准）
class PhoneMockupFrame extends StatelessWidget {
  final Widget child;
  const PhoneMockupFrame({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 410, maxHeight: 840),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF050B15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1A3356), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0xFF00F0FF), blurRadius: 10, spreadRadius: -5)
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: child,
        ),
      ),
    );
  }
}

// =========================================================================
// 自定义赛博发光组件 Toolkit (告别毛坯感)
// =========================================================================

class CyberHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  const CyberHeader({Key? key, required this.title, this.showBack = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF071120),
        border: Border(bottom: BorderSide(color: Color(0xFF132845), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          showBack
              ? const Icon(Icons.arrow_back_ios_new, color: Color(0xFF00F0FF), size: 18)
              : const Icon(Icons.settings, color: Colors.white54, size: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          showBack
              ? const SizedBox(width: 20)
              : const Icon(Icons.help_outline, color: Color(0xFF00F0FF), size: 20),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(50);
}

class CyberButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color glowColor;
  final VoidCallback? onTap;
  final bool isOutlined;

  const CyberButton({
    Key? key,
    required this.text,
    this.icon,
    this.glowColor = const Color(0xFF00F0FF),
    this.onTap,
    this.isOutlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : glowColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: glowColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 0,
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: isOutlined ? glowColor : Colors.white, size: 18),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: TextStyle(
                color: isOutlined ? glowColor : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CyberTextField extends StatelessWidget {
  final String label;
  final String hint;
  final bool obscureText;
  final String? initialValue;

  const CyberTextField({
    Key? key,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.initialValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF071224),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF1B3860), width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: initialValue,
                  obscureText: obscureText,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (obscureText)
                const Icon(Icons.remove_red_eye_outlined, color: Colors.white38, size: 18)
            ],
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// 第 1 页：首页 (Home Page)
// =========================================================================
class Page1Home extends StatelessWidget {
  const Page1Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CyberHeader(title: "Tian Key"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 马自达昂克赛拉 HUD 卡片
            Container(
              height: 175,
              decoration: BoxDecoration(
                color: const Color(0xFF081428),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.5), width: 1.2),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00F0FF).withOpacity(0.15), blurRadius: 12)
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 雷达背景圈
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.2), width: 1),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_sharp, size: 85, color: Colors.redAccent.shade400),
                      const SizedBox(height: 4),
                      // 陕A·0P92Y 蓝色车牌
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0040A8),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: Colors.white, width: 0.8),
                        ),
                        child: const Text(
                          "陕A·0P92Y",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 5 大未初始化状态栏
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF07101E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF142742)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statusBadge(Icons.bluetooth_disabled, "设备状态", "未连接"),
                  _statusBadge(Icons.shield_outlined, "管理员状态", "未授权"),
                  _statusBadge(Icons.bolt, "供电状态", "未知"),
                  _statusBadge(Icons.access_time, "时间同步", "未同步"),
                  _statusBadge(Icons.key_off, "临时借车", "无有效密码"),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 连接设备 & 管理员授权
            const Row(
              children: [
                Expanded(child: CyberButton(text: "连接设备", icon: Icons.bluetooth, glowColor: Color(0xFF00F0FF))),
                SizedBox(width: 10),
                Expanded(child: CyberButton(text: "管理员授权", icon: Icons.security, glowColor: Color(0xFFFFB800))),
              ],
            ),
            const SizedBox(height: 10),

            // 6 个车控按键 (2x3)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: const [
                CyberButton(text: "锁车", icon: Icons.lock_outline, isOutlined: true),
                CyberButton(text: "解锁", icon: Icons.lock_open, isOutlined: true),
                CyberButton(text: "车窗升", icon: Icons.keyboard_double_arrow_up, isOutlined: true),
                CyberButton(text: "车窗降", icon: Icons.keyboard_double_arrow_down, isOutlined: true),
                CyberButton(text: "寻车", icon: Icons.cell_tower, isOutlined: true),
                CyberButton(text: "后备箱", icon: Icons.minor_crash_outlined, isOutlined: true),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _cyberBottomNav(0),
    );
  }

  Widget _statusBadge(IconData icon, String label, String val) {
    return Column(
      children: [
        Icon(icon, size: 15, color: Colors.grey),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54)),
        Text(val, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// =========================================================================
// 第 2 页：临时借车 (Temp Borrow)
// =========================================================================
class Page2TempBorrow extends StatelessWidget {
  const Page2TempBorrow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> times = ["5分钟", "1天", "2天", "3天", "4天", "5天", "6天", "7天"];
    return Scaffold(
      appBar: const CyberHeader(title: "临时借车", showBack: true),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("当前状态", style: TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 4),
            const Row(
              children: [
                Icon(Icons.key_off, color: Colors.grey, size: 18),
                SizedBox(width: 6),
                Text("无有效临时密码", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            const Text("选择有效时间", style: TextStyle(color: Color(0xFF00F0FF), fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: times.map((t) {
                bool isSelected = t == "5分钟";
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFF09162A),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFF1B3860)),
                  ),
                  child: Text(t, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text("临时密码", style: TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF071224),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF183256)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.lock_clock, color: Colors.white24, size: 32),
                  SizedBox(height: 6),
                  Text("尚未生成", style: TextStyle(color: Colors.white38, fontSize: 14)),
                  SizedBox(height: 10),
                  Text("复制密码", style: TextStyle(color: Colors.white24, fontSize: 11)),
                ],
              ),
            ),
            const Spacer(),
            const CyberButton(text: "生成临时密码", glowColor: Color(0xFF00F0FF)),
            const SizedBox(height: 8),
            const CyberButton(text: "取消借车", glowColor: Colors.redAccent, isOutlined: true),
          ],
        ),
      ),
      bottomNavigationBar: _cyberBottomNav(1),
    );
  }
}

// =========================================================================
// 第 3 页：设置 (Settings)
// =========================================================================
class Page3Settings extends StatelessWidget {
  const Page3Settings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CyberHeader(title: "设置"),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _settingsTile(Icons.lock_reset, "修改蓝牙密码", ""),
          _settingsTile(Icons.restore, "恢复默认蓝牙密码", ""),
          _settingsTile(Icons.directions_car, "设备名称", "陕A0P92Y"),
          _settingsTile(Icons.sync, "时间同步设置", ""),
          _settingsTile(Icons.bluetooth_searching, "自动连接设置", "关闭"),
          _settingsTile(Icons.volume_up, "提示音设置", "关闭"),
          _settingsTile(Icons.info_outline, "关于系统", ""),
        ],
      ),
      bottomNavigationBar: _cyberBottomNav(2),
    );
  }

  Widget _settingsTile(IconData icon, String title, String val) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF071224),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF132845)),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: const Color(0xFF00F0FF), size: 18),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (val.isNotEmpty) Text(val, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 第 4 页：管理员授权 (Admin Auth)
// =========================================================================
class Page4AdminAuth extends StatelessWidget {
  const Page4AdminAuth({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CyberHeader(title: "管理员授权", showBack: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFB800).withOpacity(0.1),
                border: Border.all(color: const Color(0xFFFFB800), width: 1.5),
                boxShadow: [BoxShadow(color: const Color(0xFFFFB800).withOpacity(0.2), blurRadius: 15)],
              ),
              child: const Icon(Icons.shield, size: 55, color: Color(0xFFFFB800)),
            ),
            const SizedBox(height: 16),
            const Text("请输入管理员密码进行授权", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 20),
            const CyberTextField(label: "管理员密码", hint: "请输入管理员密码", obscureText: true),
            const SizedBox(height: 24),
            const CyberButton(text: "确认授权", glowColor: Color(0xFFFFB800)),
            const SizedBox(height: 10),
            const Text("授权后可使用全部管理员功能", style: TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 第 5 页：修改蓝牙密码 (Modify BLE Password)
// =========================================================================
class Page5ModifyBlePass extends StatelessWidget {
  const Page5ModifyBlePass({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CyberHeader(title: "修改蓝牙密码", showBack: true),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            CyberTextField(label: "当前蓝牙密码", hint: "请输入当前蓝牙密码", obscureText: true),
            SizedBox(height: 12),
            CyberTextField(label: "新蓝牙密码", hint: "请输入新蓝牙密码", obscureText: true),
            SizedBox(height: 12),
            CyberTextField(label: "确认新密码", hint: "请再次输入新密码", obscureText: true),
            SizedBox(height: 24),
            CyberButton(text: "保存新密码", glowColor: Color(0xFF00F0FF)),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 第 6 页：恢复默认蓝牙密码 (Restore Default Password)
// =========================================================================
class Page6RestoreDefault extends StatelessWidget {
  const Page6RestoreDefault({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CyberHeader(title: "恢复默认蓝牙密码", showBack: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withOpacity(0.1),
                border: Border.all(color: Colors.redAccent, width: 1.5),
              ),
              child: const Icon(Icons.refresh_rounded, size: 55, color: Colors.redAccent),
            ),
            const SizedBox(height: 20),
            // 隐藏 123456789，严格不显示真实密码
            const Text(
              "恢复后蓝牙密码将重置为出厂默认值",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const CyberButton(text: "恢复默认蓝牙密码", glowColor: Colors.redAccent),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 第 7 页：设备名称 (Device Name)
// =========================================================================
class Page7DeviceName extends StatelessWidget {
  const Page7DeviceName({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CyberHeader(title: "设备名称", showBack: true),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(height: 10),
            Icon(Icons.phone_android, size: 55, color: Color(0xFF00F0FF)),
            SizedBox(height: 16),
            CyberTextField(label: "设备名称", hint: "设备名称", initialValue: "陕A0P92Y"),
            SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("设备名称将用于蓝牙连接和设备识别", style: TextStyle(color: Colors.grey, fontSize: 10)),
            ),
            SizedBox(height: 24),
            CyberButton(text: "保存", glowColor: Color(0xFF00F0FF)),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 第 8 页：时间同步设置 (Time Sync)
// =========================================================================
class Page8TimeSync extends StatelessWidget {
  const Page8TimeSync({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CyberHeader(title: "时间同步设置", showBack: true),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time_filled, size: 70, color: Color(0xFF00F0FF)),
              SizedBox(height: 16),
              Text("当前状态", style: TextStyle(color: Colors.white54, fontSize: 11)),
              SizedBox(height: 2),
              Text("未同步", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 24),
              CyberButton(text: "立即同步", glowColor: Color(0xFF00F0FF)),
              SizedBox(height: 8),
              Text("同步后将自动校准设备时间", style: TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// 第 9 页：关于系统 (About System)
// =========================================================================
class Page9AboutSystem extends StatelessWidget {
  const Page9AboutSystem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CyberHeader(title: "关于系统", showBack: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Tian Key",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF00F0FF), letterSpacing: 1.5),
            ),
            const SizedBox(height: 10),
            const Icon(Icons.shield_outlined, size: 55, color: Colors.cyanAccent),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF071224),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF132845)),
              ),
              child: Column(
                children: [
                  _infoRow("车型", "马自达昂克赛拉"),
                  const Divider(color: Color(0xFF132845)),
                  _infoRow("车牌", "陕A0P92Y"),
                  const Divider(color: Color(0xFF132845)),
                  _infoRow("设备", "ESP32"),
                  const Divider(color: Color(0xFF132845)),
                  _infoRow("显示", "未连接设备"),
                ],
              ),
            ),
            const Spacer(),
            const Text("Tian Key 智能车钥匙控制系统", style: TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

// 底部通用 Nav
Widget _cyberBottomNav(int activeIdx) {
  return Container(
    height: 48,
    decoration: const BoxDecoration(
      color: Color(0xFF060E1A),
      border: Border(top: BorderSide(color: Color(0xFF132845), width: 1)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _navItem(Icons.home, "首页", activeIdx == 0),
        _navItem(Icons.key, "临时借车", activeIdx == 1),
        _navItem(Icons.settings, "设置", activeIdx == 2),
      ],
    ),
  );
}

Widget _navItem(IconData icon, String label, bool isActive) {
  Color col = isActive ? const Color(0xFF00F0FF) : Colors.grey;
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, color: col, size: 18),
      Text(label, style: TextStyle(color: col, fontSize: 9)),
    ],
  );
}
