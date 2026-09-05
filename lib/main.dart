import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ble_service.dart';
import 'ble_characteristic_gateway.dart';

// ==================== Tian Key V4 视觉常量 ====================
class TKColors {
  static const Color bgPrimary = Color(0xFF080B10);
  static const Color bgCard = Color(0xFF0C1118);
  static const Color bgPanel = Color(0xFF0A1018);
  static const Color neonBlue = Color(0xFF00E5FF);
  static const Color neonOrange = Color(0xFFFF8800);
  static const Color neonRed = Color(0xFFFF2A2A);
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8C9BAB);
  static const Color textMuted = Color(0xFF5A6A7A);
  static const Color success = Color(0xFF00E5FF);
  static const Color warning = Color(0xFFFF8800);
  static const Color error = Color(0xFFFF2A2A);
  static const Color disabled = Color(0xFF3A4450);
  static const Color borderSubtle = Color(0xFF1A2530);
  static const Color divider = Color(0xFF141D26);
}

// ==================== 通用科技 UI 组件库 ====================

class TKNeonButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color neonColor;
  final VoidCallback? onTap;
  final bool isEnabled;
  final double height;

  const TKNeonButton({
    super.key,
    required this.label,
    required this.icon,
    required this.neonColor,
    this.onTap,
    this.isEnabled = true,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final Color glowColor = isEnabled ? neonColor.withOpacity(0.45) : Colors.transparent;
    final Color borderColor = isEnabled ? neonColor.withOpacity(0.7) : TKColors.disabled;

    return SizedBox(
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          splashColor: neonColor.withOpacity(0.18),
          highlightColor: neonColor.withOpacity(0.08),
          child: Ink(
            decoration: BoxDecoration(
              color: TKColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(color: glowColor, blurRadius: 12, spreadRadius: 1),
                      BoxShadow(color: glowColor.withOpacity(0.3), blurRadius: 24, spreadRadius: 2),
                    ]
                  : [],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: isEnabled ? neonColor : TKColors.disabled, size: 26),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: isEnabled ? neonColor : TKColors.disabled,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TKStatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  final Color statusColor;
  final Color iconColor;

  const TKStatusCard({
    super.key,
    required this.icon,
    required this.title,
    required this.status,
    required this.statusColor,
    this.iconColor = TKColors.neonBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: TKColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TKColors.borderSubtle, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(color: TKColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class TKBottomNav extends StatelessWidget {
  final PageTab currentTab;
  final ValueChanged<PageTab> onTabChanged;

  const TKBottomNav({super.key, required this.currentTab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: TKColors.bgPrimary,
        border: Border(top: BorderSide(color: TKColors.borderSubtle, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home, label: '首页', selected: currentTab == PageTab.vehicle, onTap: () => onTabChanged(PageTab.vehicle)),
          _NavItem(icon: Icons.settings, label: '设置', selected: currentTab == PageTab.settings, onTap: () => onTabChanged(PageTab.settings)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? TKColors.neonBlue : TKColors.textMuted, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: selected ? TKColors.neonBlue : TKColors.textMuted,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TKIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const TKIconButton({super.key, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TKColors.bgCard.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 24),
        onPressed: onTap,
        splashColor: color.withOpacity(0.2),
      ),
    );
  }
}

class TKTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final bool showToggle;
  final ValueChanged<bool>? onVisibilityChanged;
  final TextInputType keyboardType;

  const TKTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.showToggle = false,
    this.onVisibilityChanged,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: TKColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: TKColors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: TKColors.textMuted, fontSize: 16),
            filled: true,
            fillColor: TKColors.bgCard,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: TKColors.borderSubtle, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: TKColors.neonBlue, width: 2),
            ),
            suffixIcon: showToggle
                ? IconButton(
                    icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: TKColors.textSecondary, size: 20),
                    onPressed: () => onVisibilityChanged?.call(!obscureText),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class TKSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData leadingIcon;

  const TKSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: TKColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TKColors.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          Icon(leadingIcon, color: TKColors.neonBlue, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: TKColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: TKColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: TKColors.neonBlue,
            activeTrackColor: TKColors.neonBlue.withOpacity(0.4),
            inactiveThumbColor: TKColors.textMuted,
            inactiveTrackColor: TKColors.borderSubtle,
          ),
        ],
      ),
    );
  }
}

class TKSettingTile extends StatelessWidget {
  final String title;
  final String? trailingText;
  final IconData leadingIcon;
  final VoidCallback? onTap;
  final bool showChevron;

  const TKSettingTile({
    super.key,
    required this.title,
    this.trailingText,
    required this.leadingIcon,
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: TKColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TKColors.borderSubtle, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(leadingIcon, color: TKColors.neonBlue, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(title, style: const TextStyle(color: TKColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
                ),
                if (trailingText != null) ...[
                  Text(trailingText!, style: const TextStyle(color: TKColors.textSecondary, fontSize: 13)),
                  const SizedBox(width: 8),
                ],
                if (showChevron) Icon(Icons.chevron_right, color: TKColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TKDialog extends StatelessWidget {
  final Widget child;
  final Color borderColor;

  const TKDialog({super.key, required this.child, this.borderColor = TKColors.neonBlue});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: TKColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: borderColor, width: 2)),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}

class TKPageTitle extends StatelessWidget {
  final String title;

  const TKPageTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: TKColors.neonBlue,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        shadows: [
          Shadow(color: TKColors.neonBlue.withOpacity(0.8), blurRadius: 10),
          Shadow(color: TKColors.neonBlue.withOpacity(0.4), blurRadius: 20),
        ],
      ),
    );
  }
}

class TKLogoText extends StatelessWidget {
  final String text;

  const TKLogoText({super.key, this.text = 'Tian Key'});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: TKColors.neonBlue,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        shadows: [
          Shadow(color: TKColors.neonBlue.withOpacity(0.9), blurRadius: 12),
          Shadow(color: TKColors.neonBlue.withOpacity(0.6), blurRadius: 24),
        ],
      ),
    );
  }
}

class TKBigIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const TKBigIcon({super.key, required this.icon, this.color = TKColors.neonBlue, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, spreadRadius: 3)],
      ),
      child: Icon(icon, color: color, size: size * 0.6),
    );
  }
}

// ==================== 主题配置 ====================
ThemeData _buildTKTheme() {
  return ThemeData.dark(useMaterial3: true).copyWith(
    scaffoldBackgroundColor: TKColors.bgPrimary,
    colorScheme: const ColorScheme.dark(
      primary: TKColors.neonBlue,
      secondary: TKColors.neonOrange,
      error: TKColors.neonRed,
      surface: TKColors.bgCard,
      onSurface: TKColors.textPrimary,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: TKColors.bgCard,
      contentTextStyle: TextStyle(color: TKColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TianKeyApp());
}

class TianKeyApp extends StatelessWidget {
  const TianKeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tian Key V12',
      theme: _buildTKTheme(),
      home: const TianKeyHome(),
    );
  }
}

enum PageTab { vehicle, settings }

class TianKeyHome extends StatefulWidget {
  const TianKeyHome({super.key});

  @override
  State<TianKeyHome> createState() => _TianKeyHomeState();
}

class _TianKeyHomeState extends State<TianKeyHome> with WidgetsBindingObserver {
  static const defaultPassword = '123456';
  static const defaultName = 'TianKey';

  final TianKeyBleService ble = TianKeyBleService();
  final BleCharacteristicGateway bleGateway = BleCharacteristicGateway();
  final TextEditingController passwordController = TextEditingController();

  SharedPreferences? prefs;
  PageTab tab = PageTab.vehicle;
  BleScanItem? foundDevice;
  List<BleScanItem> scannedDevices = [];
  Timer? commandTimer;
  Timer? _heartbeatTimer;
  Timer? _rssiTimer;
  Timer? _scanRssiTimer;
  StreamSubscription<BluetoothAdapterState>? _btAdapterSub;
  bool _connectCooldown = false;
  bool _userDisconnected = false;

  bool ready = false;
  bool scanning = false;
  bool connecting = false;
  bool connected = false;
  bool _autoConnecting = false;
  bool authorized = false;
  bool adminSession = false;
  bool autoConnect = true;
  bool timeSynced = false;
  int rssiValue = 0;
  int commandSeconds = 0;
  bool vehicleBusy = false;
  String deviceName = defaultName;
  String carModel = '未设置';
  String adminPassword = defaultPassword;
  String? installId;
  String? savedRemoteId;
  bool cpuSleepEnabled = true;
  String status = '系统待机：车辆功能锁定，请先进行蓝牙扫描';
  bool splashDone = false;

  bool get vehicleEnabled => connected && adminSession && timeSynced;

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor: const Color(0xFF1A2332),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ==================== LIGHTWEIGHT LOG ====================
  static const int _maxLogEntries = 200;
  static const Duration _maxLogAge = Duration(days: 5);

  Future<void> _logEvent(String type, String message) async {
    if (prefs == null) return;
    // 每次写入前清理过期日志
    await _cleanupLogs();
    final now = DateTime.now().millisecondsSinceEpoch;
    final logsJson = prefs!.getString('app_logs') ?? '[]';
    List<Map<String, dynamic>> logs = [];
    try {
      final decoded = jsonDecode(logsJson);
      if (decoded is List) {
        logs = decoded.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    logs.add({'t': now, 'type': type, 'msg': message});
    // 200条上限
    if (logs.length > _maxLogEntries) {
      logs = logs.sublist(logs.length - _maxLogEntries);
    }
    await prefs!.setString('app_logs', jsonEncode(logs));
  }

  Future<void> _cleanupLogs() async {
    if (prefs == null) return;
    final logsJson = prefs!.getString('app_logs');
    if (logsJson == null) return;
    List<Map<String, dynamic>> logs = [];
    try {
      final decoded = jsonDecode(logsJson);
      if (decoded is List) logs = decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      await prefs!.remove('app_logs');
      return;
    }
    final cutoff = DateTime.now().subtract(_maxLogAge).millisecondsSinceEpoch;
    logs.removeWhere((e) => (e['t'] as int? ?? 0) < cutoff);
    if (logs.length > _maxLogEntries) {
      logs = logs.sublist(logs.length - _maxLogEntries);
    }
    await prefs!.setString('app_logs', jsonEncode(logs));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _btAdapterSub = FlutterBluePlus.adapterState.listen((state) {
      // 蓝牙重新打开时，自动连接开启则尝试重连
      if (state == BluetoothAdapterState.on &&
          autoConnect &&
          !_userDisconnected &&
          !connected &&
          !connecting &&
          !_autoConnecting &&
          savedRemoteId != null &&
          savedRemoteId!.isNotEmpty) {
        _tryAutoConnect();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _btAdapterSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    commandTimer?.cancel();
    _stopHeartbeat();
    _stopRssiPolling();
    _stopScanRssi();
    passwordController.dispose();
    unawaited(bleGateway.dispose());
    unawaited(ble.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!mounted) return;
      final actuallyConnected = ble.isConnected;
      if (connected && !actuallyConnected) {
        _stopHeartbeat();
        _stopRssiPolling();
        setState(() {
          connected = false;
          connecting = false;
          adminSession = false;
          timeSynced = false;
          commandSeconds = 0;
          foundDevice = null;
          status = 'BLE连接已断开';
        });
        // 回到前台时自动重连
        if (autoConnect) {
          _tryAutoConnect();
        } else if (savedRemoteId != null && savedRemoteId!.isNotEmpty) {
          _startScanRssi();
        }
      } else if (!connected && !connecting && !_autoConnecting) {
        if (autoConnect) {
          _tryAutoConnect();
        } else if (savedRemoteId != null && savedRemoteId!.isNotEmpty) {
          _startScanRssi();
        }
      }
    }
  }

  Future<void> _load() async {
    prefs = await SharedPreferences.getInstance();
    final p = prefs!;
    installId = p.getString('install_id');
    if (installId == null || installId!.isEmpty) {
      installId = 'TK-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1000000)}';
      await p.setString('install_id', installId!);
    }
    deviceName = p.getString('device_name') ?? defaultName;
    carModel = p.getString('car_model') ?? '未设置';
    adminPassword = p.getString('admin_password') ?? defaultPassword;
    savedRemoteId = p.getString('ble_remote_id');
    authorized = p.getBool('authorized') ?? false;
    autoConnect = p.getBool('auto_connect') ?? true;
    cpuSleepEnabled = p.getBool('cpu_sleep_en') ?? true;

    // 清理旧版废弃键
    await p.remove('borrow_code');
    await p.remove('borrow_start');
    await p.remove('borrow_end');
    await p.remove('access_mode');
    await p.remove('admin_device_id');
    await p.remove('time_fail');

    ready = true;
    if (mounted) setState(() {});
    _cleanupLogs();

    // 检查蓝牙是否开启（不等动画结束）
    if (mounted) {
      try {
        final adapterState = await FlutterBluePlus.adapterState.first;
        final isOn = adapterState == BluetoothAdapterState.on;
        if (!isOn && mounted) {
          final shouldEnable = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF0A1628),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF00E5FF), width: 1),
              ),
              title: const Row(
                children: [
                  Icon(Icons.bluetooth_disabled, color: Color(0xFFFF8800), size: 24),
                  SizedBox(width: 8),
                  Text('蓝牙未开启', style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
              content: const Text('请开启蓝牙以搜索和连接设备', style: TextStyle(color: Colors.white70, fontSize: 14)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('稍后', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('去开启', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          if (shouldEnable == true) {
            try {
              await FlutterBluePlus.turnOn();
            } catch (_) {}
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      } catch (_) {}
    }

    if (mounted) setState(() {});

    // 启动后自动连接（不等动画结束）
    if (autoConnect) {
      _tryAutoConnect();
    } else if (savedRemoteId != null && savedRemoteId!.isNotEmpty) {
      _startScanRssi();
    }

    // 开机动画继续播2秒（不影响上面的BLE操作）
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => splashDone = true);
  }

  Future<void> _tryAutoConnect() async {
    if (!autoConnect) return;
    if (_autoConnecting || connected || connecting) return;
    if (!authorized || savedRemoteId == null || savedRemoteId!.isEmpty) return;
    _stopScanRssi();
    _autoConnecting = true;
    try {
      setState(() => status = '正在自动重连...');
      final target = BleScanItem(
        device: BluetoothDevice.fromId(savedRemoteId!),
        name: deviceName,
        remoteId: savedRemoteId!,
      );
      final ok = await _connectBle(target, autoAuth: true);
      if (ok) return;
      // 直接连接失败，扫描匹配保存的设备
      if (mounted && !connected) {
        setState(() => status = '自动扫描匹配中...');
        final devices = await ble.scan(timeout: const Duration(seconds: 6));
        if (!mounted) return;
        final match = devices.where((d) => d.remoteId == savedRemoteId).toList();
        if (match.isNotEmpty) {
          await _connectBle(match.first, autoAuth: true);
        } else {
          setState(() => status = '自动重连失败，未找到保存的设备');
        }
      }
    } catch (_) {
      if (mounted && !connected) setState(() => status = '自动重连失败');
    } finally {
      _autoConnecting = false;
      if (!connected && !autoConnect && savedRemoteId != null && savedRemoteId!.isNotEmpty) {
        _startScanRssi();
      }
    }
  }

  Future<void> scan({Duration? timeout}) async {
    if (!ready) return;
    _stopScanRssi();
    setState(() {
      scanning = true;
      foundDevice = null;
      scannedDevices = [];
      status = '正在扫描 BLE 设备...';
    });
    try {
      if (!await ble.isSupported()) {
        throw StateError('当前手机不支持 BLE');
      }
      final devices = await ble.scan(timeout: timeout ?? const Duration(seconds: 6));
      if (!mounted) return;
      scannedDevices = devices;
      if (devices.isEmpty) {
        setState(() => status = 'BLE扫描结束：未发现设备');
        return;
      }
      if (devices.length == 1) {
        final selected = devices.first;
        foundDevice = selected;
        setState(() => status = '发现设备：${selected.name}');
      } else {
        setState(() => status = '发现 ${devices.length} 个设备，请选择');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => status = 'BLE扫描失败：$error');
    } finally {
      if (mounted) setState(() => scanning = false);
      if (!connected && savedRemoteId != null && savedRemoteId!.isNotEmpty) {
        _startScanRssi();
      }
    }
  }

  Future<void> connectToDevice(BleScanItem device) async {
    if (connecting || connected) return;
    _stopScanRssi();
    _userDisconnected = false;
    foundDevice = device;

    if (autoConnect && authorized && adminPassword.isNotEmpty) {
      setState(() => status = '正在连接并自动认证...');
      final ok = await _connectBle(device, autoAuth: true);
      if (!ok && mounted && !connected) setState(() => connecting = false);
      return;
    }

    passwordController.clear();
    final pwd = await _askPassword();
    if (pwd == null || !mounted) return;
    final ok = await _connectBle(device, password: pwd);
    if (!ok && mounted && !connected) setState(() => connecting = false);
  }

  Future<void> connect() async {
    if (connecting || connected || _autoConnecting) return;
    _stopScanRssi();
    _userDisconnected = false;
    var target = foundDevice;

    // 【修复】不再自己设置scanning=true，让scan()自己管理
    if (target == null) {
      setState(() => status = '正在扫描蓝牙设备...');
      await scan(timeout: const Duration(seconds: 3));
      if (!mounted) return;
      if (scannedDevices.isEmpty) {
        setState(() => status = '未发现设备，请确认ESP32已开启');
        _msg('未发现蓝牙设备，请确认ESP32已开启并靠近手机');
        return;
      }
      // 优先匹配保存的设备
      if (savedRemoteId != null) {
        final match = scannedDevices.where((d) => d.remoteId == savedRemoteId).toList();
        if (match.isNotEmpty) {
          foundDevice = match.first;
          target = foundDevice;
        }
      }
      // 只有一个设备就直接选
      if (target == null && scannedDevices.length == 1) {
        foundDevice = scannedDevices.first;
        target = foundDevice;
      }
      if (target == null) {
        setState(() => status = '发现 ${scannedDevices.length} 个设备，请选择');
        return;
      }
    }

    if (autoConnect && authorized && adminPassword.isNotEmpty) {
      setState(() => status = '自动连接中...');
      final ok = await _connectBle(target, autoAuth: true);
      if (!ok && mounted && !connected) setState(() => connecting = false);
      return;
    }

    passwordController.clear();
    final pwd = await _askPassword();
    if (pwd == null || !mounted) return;
    final ok = await _connectBle(target, password: pwd);
    if (!ok && mounted && !connected) setState(() => connecting = false);
  }

  Future<bool> _connectBle(BleScanItem target, {String? password, bool autoAuth = false}) async {
    if (connecting || connected) return false;
    setState(() {
      connecting = true;
      status = '正在建立BLE连接...';
    });
    try {
      if (target.device == null) throw StateError('BLE设备对象无效');

      bool bleReady = false;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          setState(() => status = '正在连接蓝牙设备（第${attempt}次尝试）...');
          await ble.connect(target.device!);
          setState(() => status = '蓝牙已连接，正在发现服务...');
          if (ble.discoveredServices.isEmpty) {
            throw StateError('服务列表为空');
          }
          setState(() => status = '服务发现完成（${ble.discoveredServices.length}个服务）');
          bleReady = true;
          break;
        } catch (e) {
          if (attempt < 3) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }
      if (!bleReady) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('蓝牙连接失败，请确认设备在附近'), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 3)),
          );
        }
        throw StateError('BLE连接失败');
      }

      ble.onDisconnect = () {
        _stopHeartbeat();
        _stopRssiPolling();
        if (mounted) {
          setState(() {
            connected = false;
            connecting = false;
            adminSession = false;
            timeSynced = false;
            commandSeconds = 0;
            vehicleBusy = false;
            foundDevice = null;
            status = _userDisconnected ? '已断开' : 'BLE连接意外断开';
          });
          if (!_userDisconnected && mounted) {
            _logEvent('DISCONNECT', 'BLE连接意外断开（非用户操作）');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('蓝牙连接断开'), backgroundColor: TKColors.neonOrange, duration: const Duration(seconds: 2)),
            );
          }
        }
        _userDisconnected = false;
        if (!autoConnect && savedRemoteId != null && savedRemoteId!.isNotEmpty) {
          _startScanRssi();
        }
      };

      bool serviceFound = false;
      final services = ble.discoveredServices;
      for (final service in services) {
        if (service.serviceUuid.str.toUpperCase().contains('6E400001')) {
          BluetoothCharacteristic? writeChar;
          BluetoothCharacteristic? notifyChar;
          for (final c in service.characteristics) {
            final uuid = c.characteristicUuid.str.toUpperCase();
            if (uuid.contains('6E400002')) writeChar = c;
            if (uuid.contains('6E400003')) notifyChar = c;
          }
          if (writeChar != null) {
            setState(() => status = '正在绑定NUS通信通道...');
            bleGateway.bind(writeCharacteristic: writeChar, notifyCharacteristic: notifyChar);
            setState(() => status = '通信通道绑定成功');
            if (notifyChar != null) {
              setState(() => status = '正在启动通知监听...');
              await bleGateway.startNotify();
              setState(() => status = '通知监听已启动');
              await Future.delayed(const Duration(milliseconds: 200));
            }
            serviceFound = true;
            break;
          } else {
            throw StateError('NUS服务存在但写命令通道未找到');
          }
        }
      }
      if (!serviceFound) {
        throw StateError('无法发现NUS服务');
      }

      // AUTH + TIME merged
      if (autoAuth) {
        final savedPwd = prefs?.getString('admin_password');
        if (savedPwd == null || savedPwd.isEmpty) {
          await ble.disconnect();
          setState(() {
            connecting = false;
            status = '无保存密码，需手动认证';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('无保存密码，请手动连接'), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 3)),
            );
          }
          return false;
        }
        setState(() => status = 'BLE已连接，正在用密码认证...');
        final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        String? reply;
        for (int retry = 0; retry < 3; retry++) {
          reply = await bleGateway.sendAndWait(utf8.encode('!AUTH $savedPwd $ts'), expectPrefix: 'OK');
          if (reply != null && (reply.contains('OK') || reply.contains('ERR'))) break;
          if (retry < 2) await Future.delayed(const Duration(milliseconds: 100));
        }
        if (reply != null && reply.contains('OK')) {
          adminSession = true;
          authorized = true;
          timeSynced = true;
          await prefs?.setBool('authorized', true);
          _logEvent('AUTH', '自动认证成功');
        } else if (reply != null && reply.contains('ERR')) {
          // ESP32明确回复ERR = 密码错误，清除保存密码
          authorized = false;
          await prefs?.setBool('authorized', false);
          await prefs?.remove('admin_password');
          _logEvent('AUTH', '密码错误，已清除保存密码');
          await ble.disconnect();
          setState(() {
            connecting = false;
            status = '密码错误，已清除保存的密码';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('密码错误，请手动重新连接'), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 3)),
            );
          }
          return false;
        } else {
          // 通信失败（超时/断开/通知未收到），保留密码，允许下次重试
          _logEvent('AUTH', '自动认证通信失败，保留密码');
          await ble.disconnect();
          setState(() {
            connecting = false;
            status = '自动认证通信失败，保留密码等待重试';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('通信失败，保留密码等待重试'), backgroundColor: TKColors.neonOrange, duration: const Duration(seconds: 3)),
            );
          }
          return false;
        }
      }

      if (password != null && !autoAuth) {
        if (!bleGateway.readyForWrite) {
          throw StateError('BLE写通道未就绪，无法发送认证命令');
        }
        setState(() => status = '正在发送认证命令...');
        final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        String? reply;
        for (int retry = 0; retry < 3; retry++) {
          reply = await bleGateway.sendAndWait(utf8.encode('!AUTH $password $ts'));
          if (reply != null) break;
          if (retry < 2) await Future.delayed(const Duration(milliseconds: 100));
        }
        if (reply != null && reply.contains('OK')) {
          adminSession = true;
          authorized = true;
          timeSynced = true;
          await prefs?.setBool('authorized', true);
          await prefs?.setString('admin_password', password);
          _logEvent('AUTH', '手动认证成功');
          setState(() => status = '认证回复: OK');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('密码验证成功，已连接'), backgroundColor: TKColors.neonGreen, duration: const Duration(seconds: 2)),
            );
          }
        } else if (reply != null && reply.contains('ERR')) {
          // ESP32明确回复ERR = 密码错误
          authorized = false;
          await prefs?.setBool('authorized', false);
          await prefs?.remove('admin_password');
          _logEvent('AUTH', '密码错误');
          await ble.disconnect();
          setState(() {
            connecting = false;
            status = '密码错误';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('密码错误'), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 3)),
            );
          }
          return false;
        } else {
          // 通信失败（超时/断开/通知未收到），保留密码
          _logEvent('AUTH', '手动认证通信失败');
          await ble.disconnect();
          setState(() {
            connecting = false;
            status = '通信失败，请重试';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('通信失败，请重试'), backgroundColor: TKColors.neonOrange, duration: const Duration(seconds: 3)),
            );
          }
          return false;
        }
      }

      if (!mounted) return false;

      await prefs?.setString('ble_remote_id', target.remoteId);
      savedRemoteId = target.remoteId;
      _logEvent('CONNECT', '已连接 ${target.remoteId}');
      setState(() {
        connected = true;
        connecting = false;
        status = 'BLE连接成功，已认证';
      });
      _startHeartbeat();
      _startRssiPolling();
      _stopScanRssi();
      _queryCpuSleepState();
      return true;
    } catch (error) {
      try {
        if (target.device != null && target.device!.isConnected) await target.device!.disconnect();
      } catch (_) {}
      try {
        await bleGateway.dispose();
      } catch (_) {}
      if (!mounted) return false;
      setState(() {
        connecting = false;
        connected = false;
        status = '连接失败：$error';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('连接失败：$error'), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 3)),
        );
      }
      return false;
    }
  }

  Future<String?> _askPassword() async {
    bool submitting = false;
    String? errorMsg;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => TKDialog(
          borderColor: TKColors.neonOrange,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('管理员密码', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: TKColors.textPrimary)),
              if (errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(errorMsg!, style: const TextStyle(fontSize: 13, color: TKColors.neonRed)),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                keyboardType: TextInputType.number,
                enabled: !submitting,
                style: const TextStyle(color: TKColors.textPrimary, fontSize: 18),
                decoration: InputDecoration(
                  hintText: '请输入密码',
                  hintStyle: const TextStyle(color: TKColors.textMuted),
                  filled: true,
                  fillColor: TKColors.bgCard,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: TKColors.borderSubtle, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: TKColors.neonBlue, width: 2),
                  ),
                ),
                onSubmitted: submitting
                    ? null
                    : (_) {
                        final pwd = passwordController.text.trim();
                        if (pwd.isEmpty) {
                          setDialogState(() => errorMsg = '密码不能为空');
                          return;
                        }
                        setDialogState(() {
                          submitting = true;
                          errorMsg = null;
                        });
                        Navigator.pop(context, pwd);
                      },
              ),
              const SizedBox(height: 16),
              if (submitting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: TKColors.neonBlue)),
                    SizedBox(width: 12),
                    Text('正在连接...', style: TextStyle(color: TKColors.neonBlue, fontSize: 15)),
                  ]),
                )
              else
                TKNeonButton(
                  label: '确认',
                  icon: Icons.link,
                  neonColor: TKColors.neonBlue,
                  onTap: () {
                    final pwd = passwordController.text.trim();
                    if (pwd.isEmpty) {
                      setDialogState(() => errorMsg = '密码不能为空');
                      return;
                    }
                    setDialogState(() {
                      submitting = true;
                      errorMsg = null;
                    });
                    Navigator.pop(context, pwd);
                  },
                  height: 52,
                ),
            ],
          ),
        ),
      ),
    );
    if (result == null || result.isEmpty) return null;
    return result;
  }

  // ==================== RSSI ====================
  void _startRssiPolling() {
    _stopRssiPolling();
    _rssiTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!connected || !ble.isConnected) return;
      try {
        final device = ble.connectedDevice;
        if (device != null) {
          final rssi = await device.readRssi();
          if (mounted) setState(() => rssiValue = rssi);
        }
      } catch (_) {}
    });
    // 立即读一次
    _readRssiOnce();
  }

  void _stopRssiPolling() {
    _rssiTimer?.cancel();
    _rssiTimer = null;
  }

  Future<void> _readRssiOnce() async {
    if (!connected || !ble.isConnected) return;
    try {
      final device = ble.connectedDevice;
      if (device != null) {
        final rssi = await device.readRssi();
        if (mounted) setState(() => rssiValue = rssi);
      }
    } catch (_) {}
  }

  // ==================== UNCONNECTED RSSI SCAN ====================
  void _startScanRssi() {
    _stopScanRssi();
    _scanRssiTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (connected || scanning || connecting || _autoConnecting || !mounted) return;
      try {
        final devices = await ble.scan(timeout: const Duration(seconds: 3));
        if (!mounted) return;
        // 更新扫描列表中设备的RSSI
        for (final d in devices) {
          final idx = scannedDevices.indexWhere((s) => s.remoteId == d.remoteId);
          if (idx >= 0) {
            scannedDevices[idx] = d;
          }
        }
        // 如果有保存的设备，更新其RSSI
        if (savedRemoteId != null) {
          final match = devices.where((d) => d.remoteId == savedRemoteId).toList();
          if (match.isNotEmpty) {
            final rssi = match.first.rssi;
            if (rssi != 0) {
              setState(() => rssiValue = rssi);
            }
          }
        }
      } catch (_) {}
    });
  }

  void _stopScanRssi() {
    _scanRssiTimer?.cancel();
    _scanRssiTimer = null;
  }

  // ==================== HEARTBEAT ====================
  int _heartbeatFailCount = 0;

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatFailCount = 0;
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (connected) {
        _heartbeatCheck();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _heartbeatCheck() async {
    if (!connected || !bleGateway.readyForWrite) return;
    try {
      await bleGateway.writeCommand(utf8.encode('!HEARTBEAT'), withoutResponse: true);
      _heartbeatFailCount = 0;
    } catch (e) {
      _heartbeatFailCount++;
    }
    if (_heartbeatFailCount >= 6 && connected) {
      _stopHeartbeat();
      _stopRssiPolling();
      setState(() {
        connected = false;
        adminSession = false;
        timeSynced = false;
        commandSeconds = 0;
        vehicleBusy = false;
        foundDevice = null;
        status = '心跳超时（60秒），连接已断开';
      });
      _msg('连接已断开');
    }
  }

  Future<void> _queryCpuSleepState() async {
    if (!connected || !bleGateway.readyForWrite) return;
    try {
      final reply = await bleGateway.sendAndWait(utf8.encode('!CPUSLEEP?'), expectPrefix: 'CPUSLEEP');
      if (reply != null && reply.startsWith('CPUSLEEP:')) {
        final enabled = reply.substring(9) == '1';
        if (mounted) setState(() {
          cpuSleepEnabled = enabled;
        });
        await prefs?.setBool('cpu_sleep_en', enabled);
      }
    } catch (e) {
      debugPrint('queryCpuSleepState error: $e');
    }
  }

  Future<void> disconnect() async {
    _logEvent('DISCONNECT', '用户断开连接');
    _userDisconnected = true;
    _stopHeartbeat();
    _stopRssiPolling();
    _stopScanRssi();
    commandTimer?.cancel();
    try {
      await bleGateway.dispose();
    } catch (_) {}
    try {
      await ble.disconnect();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      connected = false;
      connecting = false;
      _autoConnecting = false;
      foundDevice = null;
      adminSession = false;
      timeSynced = false;
      commandSeconds = 0;
      vehicleBusy = false;
      rssiValue = 0;
      status = '已断开：车辆功能重新锁定';
    });
    _msg('已断开，车辆功能已锁定');
  }

  Future<void> vehicleCommand(String command) async {
    if (!vehicleEnabled) {
      _msg('未连接，无法执行');
      return;
    }
    if (vehicleBusy) {
      _msg('车辆操作进行中，请稍候');
      return;
    }
    late final String protocol;
    final timed;
    switch (command) {
      case '锁车':
        protocol = '!LOCK';
        timed = false;
      case '解锁':
        protocol = '!UNLOCK';
        timed = false;
      case '寻车':
        protocol = '!FINDCAR';
        timed = false;
      case '车窗升':
        protocol = '!WINDOWUP';
        timed = true;
      case '车窗降':
        protocol = '!WINDOWDOWN';
        timed = true;
      case '后备箱':
        protocol = '!TRUNK';
        timed = true;
      default:
        _msg('未知车辆命令');
        return;
    }

    if (bleGateway.readyForWrite) {
      try {
        await bleGateway.writeCommand(utf8.encode(protocol), withoutResponse: true);
      } catch (e) {
        _msg('$command 发送失败');
        return;
      }
    } else {
      _msg('BLE通道未就绪，请重新连接');
      return;
    }
    setState(() => status = '$command 已发送');
    _logEvent('VEHICLE', command);
    _msg(timed ? '$command 已发送（保持4秒）' : '$command 执行成功');
    commandTimer?.cancel();
    if (timed) {
      vehicleBusy = true;
      commandSeconds = 4;
      commandTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (commandSeconds <= 1) {
          timer.cancel();
          setState(() {
            commandSeconds = 0;
            vehicleBusy = false;
            status = '$command 完成';
          });
          return;
        }
        setState(() => commandSeconds -= 1);
      });
      setState(() => status = '$command 4秒保持中（$commandSeconds）');
    } else {
      setState(() => status = '$command 成功');
    }
  }

  Future<void> _requireAdminAuth(VoidCallback onVerified) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TKColors.bgCard,
        title: const Text('验证管理员密码', style: TextStyle(color: TKColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: TKColors.textPrimary),
          decoration: const InputDecoration(hintText: '请输入管理员密码', hintStyle: TextStyle(color: TKColors.textMuted)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text.trim() == adminPassword), child: const Text('确认')),
        ],
      ),
    );
    if (ok == true) {
      onVerified();
    }
  }

  String _rssiLabel(int rssi) {
    if (rssi > -50) return '很强';
    if (rssi > -65) return '较强';
    if (rssi > -80) return '较弱';
    return '很弱';
  }

  Widget vehiclePage() => Scaffold(
        backgroundColor: TKColors.bgPrimary,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => tab = PageTab.settings),
                      child: const Icon(Icons.settings, color: TKColors.neonBlue, size: 22),
                    ),
                    const SizedBox(width: 48),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF0D1117),
                            title: const Text('功能说明', style: TextStyle(color: TKColors.neonBlue)),
                            content: const SingleChildScrollView(
                              child: Text(
                                '锁车/解锁/后备箱：点击立即执行\n\n升降窗：点击自动保持4秒\n\n寻车：模拟按两次锁车键\n\nRSSI信号：数字越接近0越靠近车',
                                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('知道了', style: TextStyle(color: TKColors.neonBlue)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Icon(Icons.help_outline, color: TKColors.textMuted, size: 22),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 170,
                width: double.infinity,
                child: Image.asset(
                  'assets/home_car_bg.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, 0.1),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            TKStatusCard(icon: Icons.bluetooth, title: '设备', status: connected ? '已连接' : '未连接', statusColor: connected ? TKColors.neonBlue : TKColors.textMuted),
                            TKStatusCard(icon: Icons.shield, title: '管理员', status: adminSession ? '已授权' : '未授权', statusColor: adminSession ? TKColors.neonOrange : TKColors.textMuted, iconColor: TKColors.neonOrange),
                            TKStatusCard(
                              icon: Icons.signal_cellular_alt,
                              title: '信号',
                              status: connected
                                  ? (rssiValue == 0 ? '--' : '$rssiValue dBm\n${_rssiLabel(rssiValue)}')
                                  : (scannedDevices.isNotEmpty && foundDevice != null ? '${foundDevice!.rssi} dBm' : '--'),
                              statusColor: connected
                                  ? (rssiValue == 0 ? TKColors.textMuted : (rssiValue > -60 ? TKColors.neonBlue : rssiValue > -80 ? TKColors.neonOrange : TKColors.neonRed))
                                  : TKColors.textMuted,
                              iconColor: TKColors.neonBlue,
                            ),
                            TKStatusCard(icon: Icons.sync, title: '同步', status: timeSynced ? '已同步' : '未同步', statusColor: timeSynced ? TKColors.neonBlue : TKColors.textMuted, iconColor: TKColors.neonBlue),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Column(
                          children: [
                            if (!connected) ...[
                              if (scanning) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF06101D),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF0D3B66).withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: TKColors.neonBlue)),
                                      const SizedBox(width: 8),
                                      Text('正在搜索BLE设备...', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ] else if (scannedDevices.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF06101D),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF0D3B66).withOpacity(0.5)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.bluetooth_searching, color: Color(0xFF00E5FF), size: 18),
                                          const SizedBox(width: 8),
                                          Text('发现 ${scannedDevices.length} 个设备，点击选择', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ...scannedDevices.map((device) => ListTile(
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            leading: Icon(
                                              device.name.contains('Tian') ? Icons.directions_car : Icons.bluetooth,
                                              color: device.name.contains('Tian') ? const Color(0xFFFF8800) : const Color(0xFF00E5FF),
                                              size: 20,
                                            ),
                                            title: Text(device.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                            subtitle: Text('${device.remoteId}  ${device.rssi} dBm', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                                            trailing: const Icon(Icons.chevron_right, color: Color(0xFF00E5FF), size: 18),
                                            onTap: () => connectToDevice(device),
                                          )),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                            ],
                            Row(children: [
                              Expanded(
                                child: TKNeonButton(
                                  label: connected ? '断开连接' : (_connectCooldown ? '请稍候...' : '快速连接'),
                                  icon: Icons.bluetooth,
                                  neonColor: TKColors.neonBlue,
                                  onTap: connected
                                      ? () => disconnect()
                                      : (_connectCooldown
                                          ? null
                                          : () async {
                                              _connectCooldown = true;
                                              setState(() {});
                                              try {
                                                await connect();
                                              } finally {
                                                Future.delayed(const Duration(seconds: 3), () {
                                                  if (mounted) {
                                                    _connectCooldown = false;
                                                    setState(() {});
                                                  }
                                                });
                                              }
                                            }),
                                  isEnabled: true,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(child: TKNeonButton(label: '锁车', icon: Icons.lock, neonColor: TKColors.neonBlue, onTap: (vehicleEnabled && !vehicleBusy) ? () => vehicleCommand('锁车') : null, isEnabled: vehicleEnabled && !vehicleBusy)),
                              const SizedBox(width: 10),
                              Expanded(child: TKNeonButton(label: '解锁', icon: Icons.lock_open, neonColor: TKColors.neonBlue, onTap: (vehicleEnabled && !vehicleBusy) ? () => vehicleCommand('解锁') : null, isEnabled: vehicleEnabled && !vehicleBusy)),
                            ]),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(child: TKNeonButton(label: '车窗升', icon: Icons.keyboard_double_arrow_up, neonColor: TKColors.neonOrange, onTap: (vehicleEnabled && !vehicleBusy) ? () => vehicleCommand('车窗升') : null, isEnabled: vehicleEnabled && !vehicleBusy)),
                              const SizedBox(width: 10),
                              Expanded(child: TKNeonButton(label: '车窗降', icon: Icons.keyboard_double_arrow_down, neonColor: TKColors.neonOrange, onTap: (vehicleEnabled && !vehicleBusy) ? () => vehicleCommand('车窗降') : null, isEnabled: vehicleEnabled && !vehicleBusy)),
                            ]),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(child: TKNeonButton(label: '寻车', icon: Icons.volume_up, neonColor: TKColors.neonBlue, onTap: (vehicleEnabled && !vehicleBusy) ? () => vehicleCommand('寻车') : null, isEnabled: vehicleEnabled && !vehicleBusy)),
                              const SizedBox(width: 10),
                              Expanded(child: TKNeonButton(label: '后备箱', icon: Icons.open_in_new, neonColor: TKColors.neonOrange, onTap: (vehicleEnabled && !vehicleBusy) ? () => vehicleCommand('后备箱') : null, isEnabled: vehicleEnabled && !vehicleBusy)),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: TKBottomNav(currentTab: tab, onTabChanged: (t) => setState(() => tab = t)),
      );

  Widget _changeAdminPasswordPage(BuildContext pageCtx) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool saving = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    return StatefulBuilder(
      builder: (context, setLocalState) => Scaffold(
        backgroundColor: TKColors.bgPrimary,
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                TKIconButton(icon: Icons.arrow_back, color: TKColors.neonBlue, onTap: () => Navigator.pop(pageCtx)),
                const TKPageTitle(title: '修改管理员密码'),
                const SizedBox(width: 48),
              ]),
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
                const SizedBox(height: 24),
                TKBigIcon(icon: Icons.admin_panel_settings, color: TKColors.neonOrange, size: 80),
                const SizedBox(height: 24),
                TKTextField(controller: currentCtrl, label: '当前管理员密码', hint: '请输入当前管理员密码', obscureText: obscureCurrent, keyboardType: TextInputType.number, showToggle: true, onVisibilityChanged: (v) => setLocalState(() => obscureCurrent = v)),
                const SizedBox(height: 16),
                TKTextField(controller: newCtrl, label: '新管理员密码', hint: '请输入新管理员密码', obscureText: obscureNew, keyboardType: TextInputType.number, showToggle: true, onVisibilityChanged: (v) => setLocalState(() => obscureNew = v)),
                const SizedBox(height: 16),
                TKTextField(controller: confirmCtrl, label: '确认新密码', hint: '请再次输入新密码', obscureText: obscureConfirm, keyboardType: TextInputType.number, showToggle: true, onVisibilityChanged: (v) => setLocalState(() => obscureConfirm = v)),
                const SizedBox(height: 32),
                TKNeonButton(
                  label: saving ? '正在保存...' : '保存新密码',
                  icon: saving ? Icons.hourglass_top : Icons.check,
                  neonColor: TKColors.neonOrange,
                  onTap: saving
                      ? null
                      : () async {
                          if (!connected || !bleGateway.readyForWrite) {
                            _msg('请先连接设备');
                            return;
                          }
                          if (currentCtrl.text.trim() != adminPassword) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('当前密码错误'), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)));
                            return;
                          }
                          if (newCtrl.text.trim().length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('新密码至少6位'), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)));
                            return;
                          }
                          if (newCtrl.text.trim() != confirmCtrl.text.trim()) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('两次密码不一致'), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)));
                            return;
                          }
                          setLocalState(() => saving = true);
                          try {
                            // 【修复】必须ESP32成功后才改本地密码
                            final reply = await bleGateway.sendAndWait(utf8.encode('!PWD ${currentCtrl.text.trim()} ${newCtrl.text.trim()}'));
                            if (reply == null || !reply.contains('OK')) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('ESP32修改密码失败'), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)));
                              setLocalState(() => saving = false);
                              return;
                            }
                            // ESP32成功后才更新本地
                            adminPassword = newCtrl.text.trim();
                            await prefs?.setString('admin_password', adminPassword);
                            _logEvent('SETTINGS', '管理员密码已修改');
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('密码修改成功'), backgroundColor: TKColors.neonBlue, duration: const Duration(seconds: 2)));
                            Navigator.pop(pageCtx);
                          } catch (e) {
                            setLocalState(() => saving = false);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('修改失败：$e'), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)));
                          }
                        },
                  isEnabled: !saving,
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _deviceNamePage(BuildContext pageCtx) {
    final ctrl = TextEditingController(text: deviceName);
    final modelCtrl = TextEditingController(text: carModel);
    bool saving = false;
    return StatefulBuilder(
      builder: (context, setLocalState) => Scaffold(
        backgroundColor: TKColors.bgPrimary,
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                TKIconButton(icon: Icons.arrow_back, color: TKColors.neonBlue, onTap: () => Navigator.pop(pageCtx)),
                const TKPageTitle(title: '设备名称'),
                const SizedBox(width: 48),
              ]),
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
                const SizedBox(height: 24),
                TKBigIcon(icon: Icons.device_hub, color: TKColors.neonBlue, size: 80),
                const SizedBox(height: 24),
                TKTextField(controller: ctrl, label: '设备名称', hint: '输入设备名称'),
                const SizedBox(height: 16),
                TKTextField(controller: modelCtrl, label: '车型', hint: '输入车型，如：马自达昂克赛拉'),
                const SizedBox(height: 12),
                const Text('修改名称后ESP32将自动重启以更新BLE广播名称', style: TextStyle(color: TKColors.textMuted, fontSize: 12)),
                const SizedBox(height: 32),
                TKNeonButton(
                  label: saving ? '正在保存...' : '保存',
                  icon: saving ? Icons.hourglass_top : Icons.check,
                  neonColor: TKColors.neonBlue,
                  onTap: saving
                      ? null
                      : () async {
                          final v = ctrl.text.trim();
                          if (v.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('名称不能为空'), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)));
                            return;
                          }
                          if (!connected || !bleGateway.readyForWrite) {
                            _msg('请先连接设备');
                            return;
                          }
                          setLocalState(() => saving = true);
                          try {
                            // 【修复】发送名称修改，ESP32会重启
                            final reply = await bleGateway.sendAndWait(utf8.encode('!NAME $v'));
                            if (reply == null || !reply.contains('OK')) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('ESP32修改名称失败'), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)));
                              setLocalState(() => saving = false);
                              return;
                            }
                            // ESP32成功后更新本地
                            deviceName = v;
                            await prefs?.setString('device_name', v);
                            _logEvent('SETTINGS', '设备名称已修改为 $v');
                            final m = modelCtrl.text.trim();
                            if (m.isNotEmpty) {
                              carModel = m;
                              await prefs?.setString('car_model', m);
                            }
                            // ESP32即将重启，断开连接
                            try { await ble.disconnect(); } catch (_) {}
                            connected = false;
                            adminSession = false;
                            timeSynced = false;
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('名称已更新，ESP32正在重启'), backgroundColor: TKColors.neonBlue, duration: const Duration(seconds: 2)));
                            Navigator.pop(pageCtx);
                          } catch (e) {
                            setLocalState(() => saving = false);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('修改失败：$e'), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)));
                          }
                        },
                  isEnabled: !saving,
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _autoConnectPage(BuildContext pageCtx) {
    return Scaffold(
      backgroundColor: TKColors.bgPrimary,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TKIconButton(icon: Icons.arrow_back, color: TKColors.neonBlue, onTap: () => Navigator.pop(pageCtx)),
              const TKPageTitle(title: '自动连接设置'),
              const SizedBox(width: 48),
            ]),
          ),
          Expanded(
            child: StatefulBuilder(
              builder: (context, setLocalState) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TKBigIcon(icon: Icons.bluetooth_connected, color: TKColors.neonBlue, size: 80),
                  const SizedBox(height: 24),
                  TKSwitchTile(
                    title: '自动连接',
                    subtitle: '开启后打开APP自动寻找并连接上次的ESP32',
                    value: autoConnect,
                    onChanged: (v) {
                      setLocalState(() {});
                      setState(() {
                        autoConnect = v;
                      });
                      prefs?.setBool('auto_connect', v);
                      _logEvent('SETTINGS', '自动连接${v ? '开启' : '关闭'}');
                    },
                    leadingIcon: Icons.bluetooth,
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _cpuSleepPage(BuildContext pageCtx) {
    return Scaffold(
      backgroundColor: TKColors.bgPrimary,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TKIconButton(icon: Icons.arrow_back, color: TKColors.neonBlue, onTap: () => Navigator.pop(pageCtx)),
              const TKPageTitle(title: 'CPU低功耗设置'),
              const SizedBox(width: 48),
            ]),
          ),
          Expanded(
            child: StatefulBuilder(
              builder: (context, setLocalState) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TKBigIcon(icon: Icons.battery_saver, color: TKColors.neonBlue, size: 80),
                  const SizedBox(height: 24),
                  TKSwitchTile(
                    title: 'CPU低功耗',
                    subtitle: '开启后CPU空闲时自动休眠，BLE保持广播可随时连接',
                    value: cpuSleepEnabled,
                    onChanged: (v) async {
                      if (!connected || !bleGateway.readyForWrite) {
                        _msg('未连接ESP32，无法修改CPU低功耗');
                        return;
                      }
                      final cmd = v ? '!CPUSLEEP 1' : '!CPUSLEEP 0';
                      try {
                        final reply = await bleGateway.sendAndWait(utf8.encode(cmd), expectPrefix: 'OK');
                        if (reply != null && reply.contains('OK')) {
                          setState(() {
                            cpuSleepEnabled = v;
                          });
                          await prefs?.setBool('cpu_sleep_en', v);
                          _logEvent('SETTINGS', 'CPU低功耗${v ? '开启' : '关闭'}');
                          setLocalState(() {});
                          _msg('CPU低功耗已${v ? '开启' : '关闭'}');
                        } else {
                          _msg('ESP32未确认修改成功');
                        }
                      } catch (e) {
                        _msg('修改CPU低功耗失败');
                      }
                    },
                    leadingIcon: Icons.battery_saver,
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _factoryResetPage(BuildContext pageCtx) {
    return Scaffold(
      backgroundColor: TKColors.bgPrimary,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TKIconButton(icon: Icons.arrow_back, color: TKColors.neonBlue, onTap: () => Navigator.pop(pageCtx)),
              const TKPageTitle(title: '恢复出厂'),
              const SizedBox(width: 48),
            ]),
          ),
          Expanded(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.warning_amber_rounded, color: TKColors.neonRed, size: 80),
                const SizedBox(height: 24),
                const Text(
                  '此操作将清除所有管理员绑定、授权状态、\n和已保存 BLE 设备，\n并恢复为未绑定初始状态。',
                  style: TextStyle(color: TKColors.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: TKNeonButton(
                    label: '确认恢复出厂',
                    icon: Icons.delete_forever,
                    neonColor: TKColors.neonRed,
                    onTap: () async {
                      if (!connected || !bleGateway.readyForWrite) {
                        _msg('请先连接设备');
                        return;
                      }
                      final ctrl = TextEditingController();
                      final ok = await showDialog<bool>(
                        context: pageCtx,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: TKColors.bgCard,
                          title: const Text('验证管理员密码', style: TextStyle(color: TKColors.textPrimary)),
                          content: TextField(
                            controller: ctrl,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: TKColors.textPrimary),
                            decoration: const InputDecoration(hintText: '请输入管理员密码', hintStyle: TextStyle(color: TKColors.textMuted)),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                            TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim() == adminPassword), child: const Text('确认')),
                          ],
                        ),
                      );
                      if (ok == true) {
                        bool espResetConfirmed = false;
                        try {
                          final reply = await bleGateway.sendAndWait(utf8.encode('!RESET'), expectPrefix: 'OK');
                          if (reply != null && reply.contains('OK')) {
                            espResetConfirmed = true;
                            _logEvent('RESET', '恢复出厂设置');
                          }
                        } catch (_) {
                          // ESP32重启导致BLE断开是正常的，但不能因此认为成功
                        }
                        if (!espResetConfirmed) {
                          ScaffoldMessenger.of(pageCtx).showSnackBar(
                            SnackBar(content: const Text('ESP32恢复出厂失败，未收到确认'), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)),
                          );
                          return;
                        }
                        // 收到OK RESET后，等待ESP32重启
                        await Future.delayed(const Duration(milliseconds: 500));
                        try { await ble.disconnect(); } catch (_) {}
                        await prefs?.clear();
                        ScaffoldMessenger.of(pageCtx).showSnackBar(
                          SnackBar(content: const Text('已恢复出厂设置'), backgroundColor: TKColors.neonBlue, duration: const Duration(seconds: 2)),
                        );
                        adminPassword = defaultPassword;
                        savedRemoteId = null;
                        authorized = false;
                        autoConnect = true;
                        deviceName = defaultName;
                        connected = false;
                        foundDevice = null;
                        adminSession = false;
                        timeSynced = false;
                        rssiValue = 0;
                        cpuSleepEnabled = true;
                        carModel = '未设置';
                        final newId = 'TK-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1000000)}';
                        installId = newId;
                        await prefs?.setString('install_id', newId);
                        setState(() {});
                        Navigator.pop(pageCtx);
                      }
                    },
                    isEnabled: true,
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: TKColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(color: TKColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _aboutPage() {
    return Scaffold(
      backgroundColor: TKColors.bgPrimary,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TKIconButton(icon: Icons.arrow_back, color: TKColors.neonBlue, onTap: () => Navigator.pop(context)),
              const TKPageTitle(title: '关于系统'),
              const SizedBox(width: 48),
            ]),
          ),
          Expanded(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TKBigIcon(icon: Icons.directions_car_filled, color: TKColors.neonBlue, size: 100),
                const SizedBox(height: 16),
                const TKLogoText(text: 'Tian Key'),
                const SizedBox(height: 8),
                const Text('Tian Key 智能车钥匙控制系统', style: TextStyle(color: TKColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 32),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: TKColors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: TKColors.borderSubtle)),
                  child: Column(children: [
                    _infoRow('车型', carModel),
                    _infoRow('车牌', deviceName),
                    _infoRow('设备ID', installId ?? '未知'),
                    const Divider(color: TKColors.divider, height: 20),
                    _infoRow('连接状态', connected ? '已连接' : '未连接'),
                    _infoRow('管理员', adminSession ? '已授权' : '未授权'),
                    _infoRow('固件版本', '3.0'),
                  ]),
                ),
                const SizedBox(height: 24),
                const Text('© 2026 Tian Key Team', style: TextStyle(color: TKColors.textMuted, fontSize: 12)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget settingsPage() => Scaffold(
        backgroundColor: TKColors.bgPrimary,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TKIconButton(icon: Icons.arrow_back, color: TKColors.neonBlue, onTap: () => setState(() => tab = PageTab.vehicle)),
                    const TKPageTitle(title: '设置'),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    TKSettingTile(
                      title: '修改密码',
                      leadingIcon: Icons.lock,
                      trailingText: connected ? '>' : '需连接',
                      onTap: () => _requireAdminAuth(() => Navigator.push(context, MaterialPageRoute(builder: (ctx) => Builder(builder: (_) => _changeAdminPasswordPage(ctx))))),
                    ),
                    TKSettingTile(
                      title: '设备名称',
                      leadingIcon: Icons.device_hub,
                      trailingText: deviceName,
                      onTap: () => _requireAdminAuth(() => Navigator.push(context, MaterialPageRoute(builder: (ctx) => Builder(builder: (_) => _deviceNamePage(ctx))))),
                    ),
                    TKSettingTile(
                      title: '自动连接设置',
                      leadingIcon: Icons.bluetooth_connected,
                      trailingText: autoConnect ? '已开启' : '已关闭',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => Builder(builder: (_) => _autoConnectPage(ctx)))),
                    ),
                    TKSettingTile(
                      title: 'CPU低功耗',
                      leadingIcon: Icons.battery_saver,
                      trailingText: cpuSleepEnabled ? '已开启' : '已关闭',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => Builder(builder: (_) => _cpuSleepPage(ctx)))),
                    ),
                    TKSettingTile(
                      title: '恢复出厂',
                      leadingIcon: Icons.delete_forever,
                      trailingText: connected ? '>' : '需连接',
                      onTap: () => _requireAdminAuth(() => Navigator.push(context, MaterialPageRoute(builder: (ctx) => Builder(builder: (_) => _factoryResetPage(ctx))))),
                    ),
                    TKSettingTile(
                      title: '关于系统',
                      leadingIcon: Icons.info_outline,
                      trailingText: '>',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _aboutPage())),
                    ),
                  ],
                ),
              ),
              TKBottomNav(currentTab: tab, onTabChanged: (t) => setState(() => tab = t)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return const Scaffold(backgroundColor: Color(0xFF02060D), body: Center(child: CircularProgressIndicator()));
    }
    if (!splashDone) {
      return Scaffold(
        backgroundColor: const Color(0xFF080B10),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: TKColors.neonBlue.withOpacity(0.4), blurRadius: 30, spreadRadius: 5)],
                ),
                child: const Icon(Icons.directions_car_filled, color: TKColors.neonBlue, size: 80),
              ),
              const SizedBox(height: 24),
              const Text('TIAN KEY', style: TextStyle(color: TKColors.neonBlue, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4)),
              const SizedBox(height: 8),
              const Text('智能车钥匙控制系统', style: TextStyle(color: TKColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 40),
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: TKColors.neonBlue)),
            ],
          ),
        ),
      );
    }
    switch (tab) {
      case PageTab.vehicle:
        return vehiclePage();
      case PageTab.settings:
        return settingsPage();
      default:
        return vehiclePage();
    }
  }
}
