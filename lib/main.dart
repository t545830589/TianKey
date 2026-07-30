import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // APP 固定竖屏。
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 设计图本身包含状态栏和底部横条，因此隐藏真实系统栏，
  // 让 11 张设计图完整铺满手机屏幕。
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const TianKeyShell(),
    );
  }
}

class TianKeyShell extends StatefulWidget {
  const TianKeyShell({super.key});

  @override
  State<TianKeyShell> createState() => _TianKeyShellState();
}

class _TianKeyShellState extends State<TianKeyShell> {
  String page = 'home';

  String selectedDuration = '5分钟';
  String? tempPassword;

  bool autoConnect = false;
  bool soundEnabled = false;
  bool authorized = false;

  String deviceName = '陕A·0P92Y';
  String bluetoothPassword = '123456';

  final List<String> durations = const [
    '5分钟',
    '1天',
    '2天',
    '3天',
    '4天',
    '5天',
    '6天',
    '7天',
  ];

  String createRandomPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();

    return List.generate(
      6,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  void go(String target) {
    setState(() => page = target);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF06131E),
      ),
    );
  }

  void showTextInputDialog({
    required String title,
    required String hint,
    bool obscureText = false,
    String initialText = '',
    required void Function(String value) onConfirm,
  }) {
    final controller = TextEditingController(text: initialText);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF07131C),
          title: Text(
            title,
            style: const TextStyle(color: Color(0xFF5BD8FF)),
          ),
          content: TextField(
            controller: controller,
            obscureText: obscureText,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF71808C)),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF248BD0)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF57D6FF), width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;

                Navigator.pop(dialogContext);
                onConfirm(value);
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  void confirmRestoreBluetoothPassword() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF07131C),
          title: const Text(
            '恢复默认蓝牙密码',
            style: TextStyle(color: Color(0xFFFF6B6B)),
          ),
          content: const Text('确定恢复默认蓝牙密码吗？当前密码将被替换。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFCE1010),
              ),
              onPressed: () {
                setState(() => bluetoothPassword = '123456');
                Navigator.pop(dialogContext);
                showMessage('已恢复默认蓝牙密码：123456');
              },
              child: const Text('恢复'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    switch (page) {
      case 'borrow':
        content = buildBorrowPage();
        break;
      case 'settings':
        content = buildSettingsPage();
        break;
      case 'admin':
        content = buildAdminPage();
        break;
      case 'changePassword':
        content = buildChangePasswordPage();
        break;
      case 'restorePassword':
        content = buildRestorePasswordPage();
        break;
      case 'deviceName':
        content = buildDeviceNamePage();
        break;
      case 'timeSync':
        content = buildTimeSyncPage();
        break;
      case 'sound':
        content = buildSoundPage();
        break;
      case 'autoConnect':
        content = buildAutoConnectPage();
        break;
      case 'about':
        content = buildAboutPage();
        break;
      case 'home':
      default:
        content = buildHomePage();
    }

    return Scaffold(
      body: content,
    );
  }

  /// 统一背景组件：
  /// 设计图完整铺满屏幕，点击区域根据图片比例定位。
  Widget imageScreen({
    required String asset,
    required List<Widget> children,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              asset,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
            ...children.map(
              (child) => SizedBox(
                width: width,
                height: height,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }

  /// 透明按钮。
  /// left / top / width / height 均是设计图比例，例如 0.1 = 10%。
  Widget touch({
    required double left,
    required double top,
    required double width,
    required double height,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, box) {
        return Positioned(
          left: box.maxWidth * left,
          top: box.maxHeight * top,
          width: box.maxWidth * width,
          height: box.maxHeight * height,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: onTap,
            ),
          ),
        );
      },
    );
  }

  /// 首页：1.png
  Widget buildHomePage() {
    return imageScreen(
      asset: '1.png',
      children: [
        // 左上齿轮：设置
        touch(
          left: 0.03,
          top: 0.03,
          width: 0.13,
          height: 0.09,
          onTap: () => go('settings'),
        ),

        // 右上问号：关于系统
        touch(
          left: 0.84,
          top: 0.03,
          width: 0.13,
          height: 0.09,
          onTap: () => go('about'),
        ),

        // 连接设备
        touch(
          left: 0.04,
          top: 0.585,
          width: 0.44,
          height: 0.07,
          onTap: () => showMessage('暂未发现设备，请先开启蓝牙并靠近设备。'),
        ),

        // 管理员授权
        touch(
          left: 0.52,
          top: 0.585,
          width: 0.44,
          height: 0.07,
          onTap: () => go('admin'),
        ),

        // 锁车
        touch(
          left: 0.04,
          top: 0.668,
          width: 0.44,
          height: 0.07,
          onTap: () => showMessage('锁车失败：设备尚未连接。'),
        ),

        // 解锁
        touch(
          left: 0.52,
          top: 0.668,
          width: 0.44,
          height: 0.07,
          onTap: () => showMessage('解锁失败：设备尚未连接。'),
        ),

        // 车窗升
        touch(
          left: 0.04,
          top: 0.750,
          width: 0.44,
          height: 0.07,
          onTap: () => showMessage('车窗升失败：设备尚未连接。'),
        ),

        // 车窗降
        touch(
          left: 0.52,
          top: 0.750,
          width: 0.44,
          height: 0.07,
          onTap: () => showMessage('车窗降失败：设备尚未连接。'),
        ),

        // 寻车
        touch(
          left: 0.04,
          top: 0.832,
          width: 0.44,
          height: 0.07,
          onTap: () => showMessage('寻车失败：设备尚未连接。'),
        ),

        // 后备箱
        touch(
          left: 0.52,
          top: 0.832,
          width: 0.44,
          height: 0.07,
          onTap: () => showMessage('后备箱失败：设备尚未连接。'),
        ),

        // 底部：首页
        touch(
          left: 0.02,
          top: 0.910,
          width: 0.30,
          height: 0.075,
          onTap: () => go('home'),
        ),

        // 底部：临时借车
        touch(
          left: 0.34,
          top: 0.910,
          width: 0.30,
          height: 0.075,
          onTap: () => go('borrow'),
        ),

        // 底部：设置
        touch(
          left: 0.67,
          top: 0.910,
          width: 0.30,
          height: 0.075,
          onTap: () => go('settings'),
        ),
      ],
    );
  }

  /// 临时借车：2.png
  Widget buildBorrowPage() {
    final positions = <Rect>[
      const Rect.fromLTWH(0.05, 0.255, 0.21, 0.055),
      const Rect.fromLTWH(0.28, 0.255, 0.21, 0.055),
      const Rect.fromLTWH(0.51, 0.255, 0.21, 0.055),
      const Rect.fromLTWH(0.74, 0.255, 0.21, 0.055),
      const Rect.fromLTWH(0.05, 0.320, 0.21, 0.055),
      const Rect.fromLTWH(0.28, 0.320, 0.21, 0.055),
      const Rect.fromLTWH(0.51, 0.320, 0.21, 0.055),
      const Rect.fromLTWH(0.74, 0.320, 0.21, 0.055),
    ];

    final selectedIndex = durations.indexOf(selectedDuration);

    return imageScreen(
      asset: '2.png',
      children: [
        // 8 个有效时间选项
        ...List.generate(8, (index) {
          final rect = positions[index];

          return touch(
            left: rect.left,
            top: rect.top,
            width: rect.width,
            height: rect.height,
            onTap: () {
              setState(() => selectedDuration = durations[index]);
              showMessage('已选择有效时间：${durations[index]}');
            },
          );
        }),

        // 当前选中时间的蓝色描边覆盖层
        if (selectedIndex >= 0)
          LayoutBuilder(
            builder: (context, box) {
              final rect = positions[selectedIndex];

              return Positioned(
                left: box.maxWidth * rect.left,
                top: box.maxHeight * rect.top,
                width: box.maxWidth * rect.width,
                height: box.maxHeight * rect.height,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: const Color(0xFF27B6FF),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xAA008DFF),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

        // 密码显示区：生成后覆盖“尚未生成”
        if (tempPassword != null)
          LayoutBuilder(
            builder: (context, box) {
              return Positioned(
                left: box.maxWidth * 0.10,
                top: box.maxHeight * 0.445,
                width: box.maxWidth * 0.80,
                height: box.maxHeight * 0.085,
                child: IgnorePointer(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF06131D),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF1AA9FF),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      tempPassword!,
                      style: const TextStyle(
                        color: Color(0xFF5CD9FF),
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        letterSpacing: 5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

        // 复制密码
        touch(
          left: 0.08,
          top: 0.543,
          width: 0.84,
          height: 0.055,
          onTap: () async {
            if (tempPassword == null) {
              showMessage('请先生成临时密码。');
              return;
            }

            await Clipboard.setData(
              ClipboardData(text: tempPassword!),
            );

            showMessage('临时密码已复制：$tempPassword');
          },
        ),

        // 生成临时密码
        touch(
          left: 0.06,
          top: 0.618,
          width: 0.88,
          height: 0.065,
          onTap: () {
            setState(() {
              tempPassword = createRandomPassword();
            });

            showMessage('已生成 $selectedDuration 有效的临时密码。');
          },
        ),

        // 取消借车
        touch(
          left: 0.06,
          top: 0.697,
          width: 0.88,
          height: 0.065,
          onTap: () {
            setState(() => tempPassword = null);
            showMessage('临时借车已取消。');
          },
        ),

        // 底部首页
        touch(
          left: 0.02,
          top: 0.910,
          width: 0.30,
          height: 0.075,
          onTap: () => go('home'),
        ),

        // 底部临时借车
        touch(
          left: 0.34,
          top: 0.910,
          width: 0.30,
          height: 0.075,
          onTap: () => go('borrow'),
        ),

        // 底部设置
        touch(
          left: 0.67,
          top: 0.910,
          width: 0.30,
          height: 0.075,
          onTap: () => go('settings'),
        ),
      ],
    );
  }

  /// 设置：3.png
  Widget buildSettingsPage() {
    return imageScreen(
      asset: '3.png',
      children: [
        // 修改蓝牙密码
        touch(
          left: 0.05,
          top: 0.155,
          width: 0.90,
          height: 0.073,
          onTap: () => go('changePassword'),
        ),

        // 恢复默认蓝牙密码
        touch(
          left: 0.05,
          top: 0.229,
          width: 0.90,
          height: 0.073,
          onTap: () => go('restorePassword'),
        ),

        // 设备名称
        touch(
          left: 0.05,
          top: 0.317,
          width: 0.90,
          height: 0.073,
          onTap: () => go('deviceName'),
        ),

        // 时间同步设置
        touch(
          left: 0.05,
          top: 0.392,
          width: 0.90,
          height: 0.073,
          onTap: () => go('timeSync'),
        ),

        // 自动连接设置
        touch(
          left: 0.05,
          top: 0.467,
          width: 0.90,
          height: 0.073,
          onTap: () => go('autoConnect'),
        ),

        // 提示音设置
        touch(
          left: 0.05,
          top: 0.542,
          width: 0.90,
          height: 0.073,
          onTap: () => go('sound'),
        ),

        // 关于系统
        touch(
          left: 0.05,
          top: 0.617,
          width: 0.90,
          height: 0.073,
          onTap: () => go('about'),
        ),

        // 底部首页
        touch(
          left: 0.02,
          top: 0.910,
          width: 0.30,
          height: 0.075,
          onTap: () => go('home'),
        ),

        // 底部临时借车
        touch(
          left: 0.34,
          top: 0.910,
          width: 0.30,
          height: 0.075,
          onTap: () => go('borrow'),
        ),

        // 底部设置
        touch(
          left: 0.67,
          top: 0.910,
          width: 0.30,
          height: 0.075,
          onTap: () => go('settings'),
        ),
      ],
    );
  }

  /// 管理员授权：4.png
  Widget buildAdminPage() {
    return imageScreen(
      asset: '4.png',
      children: [
        // 返回
        touch(
          left: 0.02,
          top: 0.035,
          width: 0.12,
          height: 0.075,
          onTap: () => go('home'),
        ),

        // 管理员密码输入框
        touch(
          left: 0.08,
          top: 0.615,
          width: 0.84,
          height: 0.065,
          onTap: () {
            showTextInputDialog(
              title: '管理员授权',
              hint: '请输入管理员密码',
              obscureText: true,
              onConfirm: (value) {
                setState(() => authorized = true);
                showMessage('管理员授权成功。');
              },
            );
          },
        ),

        // 确认授权
        touch(
          left: 0.08,
          top: 0.705,
          width: 0.84,
          height: 0.075,
          onTap: () {
            setState(() => authorized = true);
            showMessage(
              authorized ? '管理员已授权。' : '请输入管理员密码后授权。',
            );
          },
        ),
      ],
    );
  }

  /// 修改蓝牙密码：5.png
  Widget buildChangePasswordPage() {
    return imageScreen(
      asset: '5.png',
      children: [
        // 返回
        touch(
          left: 0.02,
          top: 0.035,
          width: 0.12,
          height: 0.075,
          onTap: () => go('settings'),
        ),

        // 三个密码输入区域都弹出修改窗口
        touch(
          left: 0.08,
          top: 0.285,
          width: 0.84,
          height: 0.065,
          onTap: () => openBluetoothPasswordInput(),
        ),
        touch(
          left: 0.08,
          top: 0.395,
          width: 0.84,
          height: 0.065,
          onTap: () => openBluetoothPasswordInput(),
        ),
        touch(
          left: 0.08,
          top: 0.505,
          width: 0.84,
          height: 0.065,
          onTap: () => openBluetoothPasswordInput(),
        ),

        // 保存新密码
        touch(
          left: 0.08,
          top: 0.625,
          width: 0.84,
          height: 0.075,
          onTap: () => openBluetoothPasswordInput(),
        ),
      ],
    );
  }

  void openBluetoothPasswordInput() {
    showTextInputDialog(
      title: '修改蓝牙密码',
      hint: '请输入新的蓝牙密码',
      obscureText: true,
      onConfirm: (value) {
        setState(() => bluetoothPassword = value);
        showMessage('蓝牙密码已保存。');
      },
    );
  }

  /// 恢复默认密码：7.png
  Widget buildRestorePasswordPage() {
    return imageScreen(
      asset: '7.png',
      children: [
        // 返回
        touch(
          left: 0.02,
          top: 0.035,
          width: 0.12,
          height: 0.075,
          onTap: () => go('settings'),
        ),

        // 恢复默认蓝牙密码
        touch(
          left: 0.08,
          top: 0.670,
          width: 0.84,
          height: 0.075,
          onTap: confirmRestoreBluetoothPassword,
        ),
      ],
    );
  }

  /// 设备名称：8.png
  Widget buildDeviceNamePage() {
    return imageScreen(
      asset: '8.png',
      children: [
        // 返回
        touch(
          left: 0.02,
          top: 0.035,
          width: 0.12,
          height: 0.075,
          onTap: () => go('settings'),
        ),

        // 名称输入框
        touch(
          left: 0.08,
          top: 0.475,
          width: 0.84,
          height: 0.065,
          onTap: () => editDeviceName(),
        ),

        // 保存
        touch(
          left: 0.08,
          top: 0.580,
          width: 0.84,
          height: 0.075,
          onTap: () => editDeviceName(),
        ),
      ],
    );
  }

  void editDeviceName() {
    showTextInputDialog(
      title: '设备名称',
      hint: '请输入设备名称',
      initialText: deviceName,
      onConfirm: (value) {
        setState(() => deviceName = value);
        showMessage('设备名称已保存：$deviceName');
      },
    );
  }

  /// 时间同步：9.png
  Widget buildTimeSyncPage() {
    return imageScreen(
      asset: '9.png',
      children: [
        // 返回
        touch(
          left: 0.02,
          top: 0.035,
          width: 0.12,
          height: 0.075,
          onTap: () => go('settings'),
        ),

        // 立即同步
        touch(
          left: 0.08,
          top: 0.600,
          width: 0.84,
          height: 0.075,
          onTap: () {
            final now = DateTime.now();
            showMessage(
              '时间同步完成：'
              '${now.year}-${now.month.toString().padLeft(2, '0')}-'
              '${now.day.toString().padLeft(2, '0')} '
              '${now.hour.toString().padLeft(2, '0')}:'
              '${now.minute.toString().padLeft(2, '0')}',
            );
          },
        ),
      ],
    );
  }

  /// 提示音：10.png
  Widget buildSoundPage() {
    return imageScreen(
      asset: '10.png',
      children: [
        // 返回
        touch(
          left: 0.02,
          top: 0.035,
          width: 0.12,
          height: 0.075,
          onTap: () => go('settings'),
        ),

        // 提示音开关
        touch(
          left: 0.70,
          top: 0.360,
          width: 0.22,
          height: 0.075,
          onTap: () {
            setState(() => soundEnabled = !soundEnabled);
            showMessage(soundEnabled ? '提示音已开启。' : '提示音已关闭。');
          },
        ),

        // 用真实开关显示当前状态
        LayoutBuilder(
          builder: (context, box) {
            return Positioned(
              left: box.maxWidth * 0.70,
              top: box.maxHeight * 0.355,
              width: box.maxWidth * 0.22,
              height: box.maxHeight * 0.075,
              child: IgnorePointer(
                child: Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: soundEnabled,
                    activeColor: const Color(0xFF2BB8FF),
                    onChanged: null,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// 自动连接：11.png
  Widget buildAutoConnectPage() {
    return imageScreen(
      asset: '11.png',
      children: [
        // 返回
        touch(
          left: 0.02,
          top: 0.035,
          width: 0.12,
          height: 0.075,
          onTap: () => go('settings'),
        ),

        // 自动连接开关
        touch(
          left: 0.70,
          top: 0.145,
          width: 0.22,
          height: 0.075,
          onTap: () {
            setState(() => autoConnect = !autoConnect);
            showMessage(autoConnect ? '自动连接已开启。' : '自动连接已关闭。');
          },
        ),

        // 用真实开关显示当前状态
        LayoutBuilder(
          builder: (context, box) {
            return Positioned(
              left: box.maxWidth * 0.70,
              top: box.maxHeight * 0.140,
              width: box.maxWidth * 0.22,
              height: box.maxHeight * 0.075,
              child: IgnorePointer(
                child: Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: autoConnect,
                    activeColor: const Color(0xFF2BB8FF),
                    onChanged: null,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// 关于系统：12.png
  Widget buildAboutPage() {
    return imageScreen(
      asset: '12.png',
      children: [
        // 返回
        touch(
          left: 0.02,
          top: 0.035,
          width: 0.12,
          height: 0.075,
          onTap: () => go('settings'),
        ),
      ],
    );
  }
}
