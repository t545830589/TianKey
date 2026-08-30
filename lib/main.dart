import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ble_service.dart';
import 'ble_characteristic_gateway.dart';

// ==================== Tian Key V4 视觉常量 ====================
class TKColors {
  // 背景底色
  static const Color bgPrimary = Color(0xFF080B10);       // 极客黑
  static const Color bgCard = Color(0xFF0C1118);          // 卡片/面板深色
  static const Color bgPanel = Color(0xFF0A1018);         // 面板次级

  // 科技蓝（主色/选中）
  static const Color neonBlue = Color(0xFF00E5FF);        // 发光电光蓝

  // 科技橙（警告/车窗/管理员）
  static const Color neonOrange = Color(0xFFFF8800);      // 发光金橙

  // 警示红（取消/重置/危险）
  static const Color neonRed = Color(0xFFFF2A2A);         // 发光红

  // 文字
  static const Color textPrimary = Color(0xFFFFFFFF);     // 纯白
  static const Color textSecondary = Color(0xFF8C9BAB);   // 次要灰
  static const Color textMuted = Color(0xFF5A6A7A);       // 更淡灰

  // 状态
  static const Color success = Color(0xFF00E5FF);         // 同步/连接成功用蓝
  static const Color warning = Color(0xFFFF8800);         // 警告用橙
  static const Color error = Color(0xFFFF2A2A);           // 错误用红
  static const Color disabled = Color(0xFF3A4450);        // 禁用态

  // 边框/分割
  static const Color borderSubtle = Color(0xFF1A2530);
  static const Color divider = Color(0xFF141D26);
}

// ==================== 通用科技 UI 组件库 ====================

// 科技霓虹按钮（八角形/切角圆角、发光边框、内含 Icon+Label）
class TKNeonButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color neonColor;           // neonBlue / neonOrange / neonRed
  final VoidCallback? onTap;
  final bool isEnabled;
  final double height;
  final double iconSize;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const TKNeonButton({
    super.key,
    required this.label,
    required this.icon,
    required this.neonColor,
    this.onTap,
    this.isEnabled = true,
    this.height = 56,
    this.iconSize = 26,
    this.fontSize = 13,
    this.padding,
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
              boxShadow: isEnabled ? [
                BoxShadow(color: glowColor, blurRadius: 12, spreadRadius: 1),
                BoxShadow(color: glowColor.withOpacity(0.3), blurRadius: 24, spreadRadius: 2),
              ] : [],
            ),
            child: InkWell(
              onTap: isEnabled ? onTap : null,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Padding(
                  padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      ),
    );
  }
}

// 科技状态卡片（Icon + Title + Status，横向均分用）
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

// 科技导航栏（3 项：首页/临时借车/设置）
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
          _NavItem(icon: Icons.people, label: '临时借车', selected: currentTab == PageTab.borrow, onTap: () => onTabChanged(PageTab.borrow)),
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
    final bool isSel = selected;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSel ? TKColors.neonBlue : TKColors.textMuted, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSel ? TKColors.neonBlue : TKColors.textMuted,
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 科技图标按钮（顶栏用）
class TKIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double size;

  const TKIconButton({super.key, required this.icon, required this.color, this.onTap, this.size = 24});

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
        icon: Icon(icon, color: color, size: size),
        onPressed: onTap,
        splashColor: color.withOpacity(0.2),
      ),
    );
  }
}

// 科技标题栏（通用：左图标/返回、中间标题、右图标）
class TKAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final Color titleColor;
  final double height;

  const TKAppBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.titleColor = TKColors.neonBlue,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          leading ?? const SizedBox(width: 48),
          Center(
            child: Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: [
                  Shadow(color: titleColor.withOpacity(0.8), blurRadius: 12),
                  Shadow(color: titleColor.withOpacity(0.5), blurRadius: 24),
                ],
              ),
            ),
          ),
          trailing ?? const SizedBox(width: 48),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}

// 科技输入框（黑底、细蓝边框、右侧显隐图标）
class TKTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final bool showToggle;
  final ValueChanged<bool>? onVisibilityChanged;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const TKTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.showToggle = false,
    this.onVisibilityChanged,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
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
          maxLines: maxLines,
          validator: validator,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: TKColors.neonRed, width: 1.5),
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

// 科技开关项（设置页用）
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

// 科技列表项（设置页列表：左图标、中文名、右侧状态/箭头）
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

// 科技弹窗基类（深蓝背景、霓虹边框、圆角）
class TKDialog extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final double borderRadius;

  const TKDialog({super.key, required this.child, this.borderColor = TKColors.neonBlue, this.borderRadius = 18});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: TKColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius), side: BorderSide(color: borderColor, width: 2)),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}

// 科技标题文本（页面标题）
class TKPageTitle extends StatelessWidget {
  final String title;
  final double fontSize;

  const TKPageTitle({super.key, required this.title, this.fontSize = 22});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: TKColors.neonBlue,
        fontSize: fontSize,
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

// 科技 Logo 文字（首页顶部 Tian Key）
class TKLogoText extends StatelessWidget {
  final String text;
  final double fontSize;

  const TKLogoText({super.key, this.text = 'Tian Key', this.fontSize = 22});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: TKColors.neonBlue,
        fontSize: fontSize,
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

// 科技大图标展示（设置页子页面中央大图标）
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
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TKColors.bgCard,
      labelStyle: const TextStyle(color: TKColors.textSecondary),
      hintStyle: const TextStyle(color: TKColors.textMuted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TKColors.borderSubtle)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TKColors.borderSubtle)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TKColors.neonBlue, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TKColors.neonRed, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: TKColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: TKColors.neonBlue, width: 2)),
      titleTextStyle: const TextStyle(color: TKColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
      contentTextStyle: const TextStyle(color: TKColors.textSecondary, fontSize: 14),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: TKColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      modalBackgroundColor: TKColors.bgCard,
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
      title: 'Tian Key V11',
      theme: _buildTKTheme(),
      home: const TianKeyHome(),
    );
  }
}

enum PageTab { vehicle, borrow, settings }
enum AccessMode { admin, borrower }

// ==================== 模拟ESP32逻辑层 ====================
class SimulatedEsp32 {
  String adminPassword = '123456789';
  String? adminDevice;
  String? borrowCode;
  DateTime? borrowStart;
  DateTime? borrowEnd;
  String deviceName = '陕A0P92Y';
  bool timeSynced = false;
  DateTime? espTime;

  SimulatedEsp32();

  bool verifyAdminPassword(String password, String deviceId) {
    if (password != adminPassword) {
      return false;
    }
    adminDevice = deviceId;
    return true;
  }

  bool verifyBorrowPassword(String password) {
    if (borrowCode == null || password != borrowCode) {
      return false;
    }
    if (borrowEnd != null && DateTime.now().isAfter(borrowEnd!)) {
      return false;
    }
    return true;
  }

  bool isCurrentAdmin(String deviceId) {
    final result = adminDevice == deviceId;
    return result;
  }

  bool syncTime(DateTime phoneTime) {
    espTime = phoneTime;
    timeSynced = true;
    return true;
  }

  String generateBorrowCode(int hours) {
    // 哈希基于密码+过期时间戳，不再依赖6小时窗口
    final now = DateTime.now();
    borrowStart = now;
    borrowEnd = hours == 0
        ? now.add(const Duration(minutes: 5))
        : now.add(Duration(hours: hours));
    final expiryEpoch = borrowEnd!.millisecondsSinceEpoch ~/ 1000;
    final secret = '$adminPassword$expiryEpoch';
    final bytes = Uint8List.fromList(utf8.encode(secret));
    final digest = sha256.convert(bytes);
    final hashBytes = digest.bytes;
    final val = ((hashBytes[0] << 24) | (hashBytes[1] << 16) | (hashBytes[2] << 8) | hashBytes[3]) & 0x7FFFFFFF;
    final code = (val % 1000000).toString().padLeft(6, '0');
    
    borrowCode = code;
    return code;
  }

  bool changePassword(String newPassword) {
    adminPassword = newPassword;
    return true;
  }

  bool resetPassword() {
    adminPassword = '123456789';
    return true;
  }

  void factoryReset() {
    adminPassword = '123456789';
    adminDevice = null;
    borrowCode = null;
    borrowStart = null;
    borrowEnd = null;
    deviceName = '陕A0P92Y';
    timeSynced = false;
    espTime = null;
  }
}

class TianKeyHome extends StatefulWidget {
  const TianKeyHome({super.key});

  @override
  State<TianKeyHome> createState() => _TianKeyHomeState();
}

class _TianKeyHomeState extends State<TianKeyHome> with WidgetsBindingObserver {
  static const defaultPassword = '123456789';
  static const defaultName = '陕A0P92Y';

  final TianKeyBleService ble = TianKeyBleService();
  final BleCharacteristicGateway bleGateway = BleCharacteristicGateway();
  late final SimulatedEsp32 esp32 = SimulatedEsp32();
  final List<String> logs = <String>[];
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController hoursController = TextEditingController(text: '2');

  SharedPreferences? prefs;
  PageTab tab = PageTab.vehicle;
  AccessMode? mode;
  BleScanItem? foundDevice;
  List<BleScanItem> scannedDevices = [];
  Timer? borrowExpiryTimer;
  Timer? commandTimer;
  Timer? _heartbeatTimer;

  bool ready = false;
  bool scanning = false;
  bool connecting = false;
  bool connected = false;
  bool _autoConnecting = false;
  bool authorized = true;
  bool adminSession = false;
  bool autoConnect = true;
  bool simulationMode = false;
  bool timeSynced = false;
  bool timeFail = false;
  int rssiValue = 0;
  int commandSeconds = 0;
  String deviceName = defaultName;
  String adminPassword = defaultPassword;
  String? installId;
  String? adminDevice;
  String? savedRemoteId;
  String? borrowCode;
  DateTime? borrowStart;
  DateTime? borrowEnd;
  DateTime? espTime;
  bool sleepEnabled = false;
  int sleepHours = 0;
  int sleepMinutes = 30;
  int wakeMinutes = 30;
  bool esp32Sleeping = false;
  String status = '系统待机：车辆功能锁定，请先进行蓝牙扫描';
  bool splashDone = false;

  bool get borrowValid {
    if (borrowCode == null || borrowStart == null || borrowEnd == null) return false;
    final now = DateTime.now();
    return !now.isBefore(borrowStart!) && now.isBefore(borrowEnd!);
  }

  bool get adminEnabled => adminSession;

  bool get vehicleEnabled => connected && authorized;

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)), backgroundColor: const Color(0xFF1A2332), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating, margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    borrowExpiryTimer?.cancel();
    commandTimer?.cancel();
    _stopHeartbeat();
    passwordController.dispose();
    hoursController.dispose();
    unawaited(bleGateway.dispose());
    unawaited(ble.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!connected && !connecting && authorized && savedRemoteId != null) {
        connect();
        Future.delayed(const Duration(seconds: 3), () {
          if (!connected && !connecting && authorized && savedRemoteId != null && mounted) {
            connect();
          }
        });
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
    adminPassword = p.getString('admin_password') ?? defaultPassword;
    adminDevice = p.getString('admin_device_id');
    savedRemoteId = p.getString('ble_remote_id');
    borrowCode = p.getString('borrow_code');
    final start = p.getInt('borrow_start');
    final end = p.getInt('borrow_end');
    borrowStart = start == null ? null : DateTime.fromMillisecondsSinceEpoch(start);
    borrowEnd = end == null ? null : DateTime.fromMillisecondsSinceEpoch(end);
    authorized = p.getBool('authorized') ?? false;
    autoConnect = p.getBool('auto_connect') ?? true;
    simulationMode = p.getBool('simulation_mode') ?? false;
    timeFail = p.getBool('time_fail') ?? false;
    sleepEnabled = p.getBool('sleep_enabled') ?? false;
    sleepHours = p.getInt('sleep_hours') ?? 0;
    sleepMinutes = p.getInt('sleep_minutes') ?? 30;
    wakeMinutes = p.getInt('wake_minutes') ?? 30;
    esp32Sleeping = sleepEnabled;

    esp32.adminPassword = adminPassword;
    esp32.adminDevice = adminDevice;
    esp32.deviceName = deviceName;
    esp32.borrowCode = borrowCode;
    esp32.borrowStart = borrowStart;
    esp32.borrowEnd = borrowEnd;

    ready = true;
    _scheduleBorrowExpiry();
    if (borrowEnd != null && !DateTime.now().isBefore(borrowEnd!)) {
      await _clearBorrow();
    }

    if (mounted) setState(() {});
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => splashDone = true);

    // 检查蓝牙是否开启，没开就弹窗提示
    if (!simulationMode && mounted) {
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
            // 等待蓝牙就绪
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      } catch (_) {}
    }

    if (simulationMode && autoConnect) {
      await _autoConnectSimulation();
    } else if (!simulationMode && autoConnect && savedRemoteId != null) {
      await _autoConnectReal();
    }

    // 自动连接失败或首次使用（无保存设备），自动扫描弹出设备列表让用户手动选
    if (!connected && !simulationMode && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && !connected && !scanning) {
        try {
          final adapterState2 = await FlutterBluePlus.adapterState.first;
          if (adapterState2 == BluetoothAdapterState.on) scan();
        } catch (_) {
          scan();
        }
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _autoConnectSimulation() async {
    if (!simulationMode || connected || connecting || _autoConnecting) return;
    _autoConnecting = true;
    setState(() {
      connecting = true;
      status = '正在自动连接...';
    });
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    final simDevice = BleScanItem(name: esp32.deviceName, remoteId: 'SIM-ESP32-TIANKY');
    foundDevice = simDevice;
    savedRemoteId = simDevice.remoteId;
    final esp32HasAdmin = esp32.adminDevice != null && esp32.adminDevice!.isNotEmpty;
    final isCurrentAdmin = esp32HasAdmin && esp32.adminDevice == installId;
    if (isCurrentAdmin) {
      adminSession = true;
      mode = AccessMode.admin;
      await prefs?.setBool('authorized', true);
      authorized = true;
    } else {
      adminSession = false;
      mode = AccessMode.borrower;
      await prefs?.setBool('authorized', false);
      authorized = false;
    }
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() {
      connected = true;
      connecting = false;
      timeSynced = false;
      status = adminSession ? '自动连接成功，管理员模式' : '自动连接成功，非管理员模式，需输入密码';
    });
      _autoConnecting = false;
      await syncTime();
      _startHeartbeat();
    }

  Future<void> _autoConnectReal() async {
    if (simulationMode || connected || connecting || _autoConnecting) return;
    _autoConnecting = true;
    setState(() {
      connecting = true;
      status = '正在自动连接...';
    });
    try {
      if (savedRemoteId == null || savedRemoteId!.isEmpty) {
        setState(() { connecting = false; status = '自动连接失败：无保存设备'; });
        return;
      }
      final savedPwd = prefs?.getString('admin_password');
      if (savedPwd == null || savedPwd.isEmpty) {
        setState(() { connecting = false; status = '自动连接失败：无保存的密码'; });
        _msg('无保存密码，请手动连接');
        return;
      }
      // 用扫描方式找到设备（替代不可靠的fromId）
      setState(() => status = '正在扫描已保存设备...');
      final devices = await ble.scan(timeout: const Duration(milliseconds: 1500));
      if (!mounted) return;
      BleScanItem? target;
      if (devices.isNotEmpty) {
        // 优先用remoteId精确匹配
        final match = devices.where((d) => d.remoteId == savedRemoteId).toList();
        if (match.isNotEmpty) {
          target = match.first;
        }
      }
      if (target == null) {
        setState(() { connecting = false; status = '自动连接失败：设备不在附近'; });
        return;
      }
      foundDevice = target;
      // BLE连接
      await ble.connect(target.device!);
      if (ble.discoveredServices.isEmpty) {
        throw StateError('服务列表为空');
      }
      // 绑定NUS通道
      BluetoothCharacteristic? writeChar;
      BluetoothCharacteristic? notifyChar;
      for (final s in ble.discoveredServices) {
        for (final c in s.characteristics) {
          final uuid = c.characteristicUuid.str.toUpperCase();
          if (uuid.contains('6E400002')) writeChar = c;
          if (uuid.contains('6E400003')) notifyChar = c;
        }
      }
      if (writeChar != null) {
        bleGateway.bind(writeCharacteristic: writeChar, notifyCharacteristic: notifyChar);
      }
      if (bleGateway.readyForWrite) {
        await bleGateway.startNotify();
        await Future.delayed(const Duration(milliseconds: 100));
      }
      // 用保存的密码认证
      String? reply;
      for (int retry = 0; retry < 3; retry++) {
        reply = await bleGateway.sendAndWait(utf8.encode('!AUTH $savedPwd $installId'), expectPrefix: 'OK');
        if (reply != null && reply.contains('OK')) break;
        if (retry < 2) await Future.delayed(const Duration(milliseconds: 50));
      }
      if (reply != null && reply.contains('OK')) {
        esp32.verifyAdminPassword(savedPwd, installId ?? '');
        adminDevice = installId;
        adminSession = true;
        authorized = true;
        mode = AccessMode.admin;
        esp32.adminDevice = installId;
        await prefs?.setString('admin_device_id', installId!);
        await prefs?.setBool('authorized', true);
        setState(() {
          connected = true;
          connecting = false;
          timeSynced = false;
          status = '自动连接成功，管理员模式';
        });
        await syncTime();
        _startHeartbeat();
      } else {
        await ble.disconnect();
        setState(() { connecting = false; status = '自动连接失败：密码认证失败，请手动连接'; });
        _msg('自动认证失败，请手动连接');
      }
    } catch (e) {
      setState(() { connecting = false; status = '自动连接失败：$e'; });
      _msg('自动连接失败');
    } finally {
      _autoConnecting = false;
    }
  }

  void _scheduleBorrowExpiry() {
    borrowExpiryTimer?.cancel();
    final end = borrowEnd;
    if (end == null) return;
    final delay = end.difference(DateTime.now());
    if (delay <= Duration.zero) {
      _showBorrowExpiredDialog();
      unawaited(_clearBorrow());
      return;
    }
    borrowExpiryTimer = Timer(delay, () {
      _showBorrowExpiredDialog();
      unawaited(_clearBorrow());
    });
  }

  void _showBorrowExpiredDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TKColors.bgCard,
        title: const Text('借车授权已过期', style: TextStyle(color: TKColors.neonOrange)),
        content: const Text('临时借车密码已过期，车辆功能已重新锁定。', style: TextStyle(color: TKColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('知道了', style: TextStyle(color: TKColors.neonBlue))),
        ],
      ),
    );
  }

  Future<void> scan({Duration? timeout}) async {
    if (!ready || scanning || connecting || connected) return;
    setState(() {
      scanning = true;
      foundDevice = null;
      scannedDevices = [];
      status = simulationMode ? '模拟扫描中...' : '正在扫描 BLE 设备...';
    });
    try {
      if (simulationMode) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        final simDevice = BleScanItem(name: '陕A0P92Y', remoteId: 'SIM-ESP32-TIANKY');
        scannedDevices = [simDevice];
        foundDevice = simDevice;
        savedRemoteId = simDevice.remoteId;
        setState(() => status = '发现设备：${simDevice.name}');
      } else {
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
          savedRemoteId = selected.remoteId;
          await prefs?.setString('ble_remote_id', selected.remoteId);
          setState(() => status = '发现设备：${selected.name}');
        } else {
          setState(() => status = '发现 ${devices.length} 个设备，请选择');
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => status = '${simulationMode ? "模拟" : "BLE"}扫描失败：$error');
    } finally {
      if (mounted) setState(() => scanning = false);
    }
  }

  Future<void> connectToDevice(BleScanItem device) async {
    if (connecting || connected) return;
    foundDevice = device;
    savedRemoteId = device.remoteId;
    await prefs?.setString('ble_remote_id', device.remoteId);
    final selected = await showDialog<AccessMode>(
      context: context,
      builder: (context) => _authChoiceDialog(),
    );
    if (selected == null || !mounted) return;
    passwordController.clear();
    final pwd = await _askPassword(selected);
    if (pwd == null || !mounted) return;
    await _connectBle(device, selected, password: pwd);
  }

  Future<void> connect() async {
    if (connecting || connected || _autoConnecting) return;
    var target = foundDevice;

    // 没有已发现设备 → 扫描3秒找
    if (target == null) {
      setState(() { status = '正在扫描设备...'; });
      await scan(timeout: const Duration(seconds: 3));
      if (!mounted) return;
      if (scannedDevices.isEmpty) {
        setState(() { status = '未发现设备，请确认ESP32已开启'; });
        return;
      }
      // 已保存设备优先匹配
      if (savedRemoteId != null) {
        final match = scannedDevices.where((d) => d.remoteId == savedRemoteId).toList();
        if (match.isNotEmpty) {
          foundDevice = match.first;
          target = foundDevice;
        }
      }
      // 没匹配到保存设备，但只有一个设备就直接选
      if (target == null && scannedDevices.length == 1) {
        foundDevice = scannedDevices.first;
        target = foundDevice;
      }
      if (target == null) {
        setState(() { status = '发现${scannedDevices.length}个设备，请选择'; });
        return;
      }
    }
    if (autoConnect && authorized && adminDevice != null && adminDevice == installId) {
      await _connectBle(target, AccessMode.admin, autoConnectVerify: true);
      return;
    }
    final selected = await showDialog<AccessMode>(
      context: context,
      builder: (context) => _authChoiceDialog(),
    );
    if (selected == null || !mounted) return;
    passwordController.clear();
    final pwd = await _askPassword(selected);
    if (pwd == null || !mounted) return;
    await _connectBle(target, selected, password: pwd);
  }

  Future<void> _connectBle(BleScanItem target, AccessMode selected, {bool skipPassword = false, String? password, bool autoConnectVerify = false}) async {
    if (connecting || connected) return;
    setState(() {
      connecting = true;
      status = simulationMode ? '模拟连接中...' : '正在建立 BLE 连接...';
    });
    try {
      if (!simulationMode) {
        if (target.device == null) throw StateError('BLE设备对象无效');
        // 整个连接+服务发现流程带重试
        bool bleReady = false;
        for (int attempt = 1; attempt <= 2; attempt++) {
          try {
            await ble.connect(target.device!, timeout: const Duration(seconds: 3));
            if (ble.discoveredServices.isEmpty) {
              throw StateError('服务列表为空');
            }
            bleReady = true;
            break;
          } catch (e) {
            if (attempt < 2) {
              await Future.delayed(const Duration(milliseconds: 300));
            }
          }
        }
        if (!bleReady) {
          throw StateError('BLE连接失败，请确认设备在附近并重试');
        }
        ble.onDisconnect = () {
          _stopHeartbeat();
          if (mounted && connected) {
            setState(() {
              connected = false;
              mode = null;
              adminSession = false;
              timeSynced = false;
              espTime = null;
              commandSeconds = 0;
              status = 'BLE连接已断开，车辆功能锁定';
            });
          }
        };
        // ble.connect()已做服务发现，直接使用已发现的服务绑定NUS通道
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
              bleGateway.bind(writeCharacteristic: writeChar, notifyCharacteristic: notifyChar);
              if (notifyChar != null) {
                await bleGateway.startNotify();
                await Future.delayed(const Duration(milliseconds: 200));
              }
            }
            serviceFound = true;
            break;
          }
        }
        if (!serviceFound) {
          throw StateError('无法发现NUS服务，请确认ESP32固件正常');
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // 自动连接验证：根据身份发送不同验证命令
      if (autoConnectVerify && !simulationMode && bleGateway.readyForWrite) {
        final savedMode = prefs?.getString('access_mode');
        if (savedMode == 'borrower') {
          // 临时借车自动连接：发送!VERIFYBORROW验证
          final savedCode = prefs?.getString('borrow_code');
          if (savedCode == null || savedCode.isEmpty) {
            await ble.disconnect();
            setState(() { connecting = false; status = '借车授权已失效，请重新认证'; });
            return;
          }
          setState(() => status = 'BLE已连接，正在验证临时借车授权...');
          String? reply;
          for (int retry = 0; retry < 3; retry++) {
            reply = await bleGateway.sendAndWait(utf8.encode('!VERIFYBORROW $savedCode'), expectPrefix: 'OK');
            if (reply != null && reply.contains('OK')) break;
            if (retry < 2) await Future.delayed(const Duration(milliseconds: 100));
          }
          if (reply != null && reply.contains('OK')) {
            esp32.verifyBorrowPassword(savedCode);
          } else {
            await ble.disconnect();
            setState(() { connecting = false; status = '临时借车授权已过期或无效'; });
            return;
          }
        } else {
          // 管理员自动连接：发送!DEVID检查管理员席位
          setState(() => status = 'BLE已连接，正在验证管理员席位...');
          String? reply;
          for (int retry = 0; retry < 3; retry++) {
            reply = await bleGateway.sendAndWait(utf8.encode('!DEVID $installId'));
            if (reply != null && (reply.contains('OK') || reply.contains('NO_ADMIN'))) break;
            if (retry < 2) await Future.delayed(const Duration(milliseconds: 100));
          }
          if (reply != null && reply.contains('OK')) {
            adminSession = true;
            adminDevice = installId;
            await prefs?.setString('admin_device_id', installId!);
          } else {
            // !DEVID失败（无管理员/席位被占/其他），自动用保存密码认证，不弹密码框
            adminSession = false;
            final savedPwd = prefs?.getString('admin_password');
            if (savedPwd == null || savedPwd.isEmpty) {
              await ble.disconnect();
              setState(() { connecting = false; status = '无保存密码，需手动认证'; });
              return;
            }
            String? authReply;
            for (int retry = 0; retry < 3; retry++) {
              authReply = await bleGateway.sendAndWait(utf8.encode('!AUTH $savedPwd $installId'), expectPrefix: 'OK');
              if (authReply != null && authReply.contains('OK')) break;
              if (retry < 2) await Future.delayed(const Duration(milliseconds: 100));
            }
            if (authReply != null && authReply.contains('OK')) {
              esp32.verifyAdminPassword(savedPwd, installId ?? '');
              adminDevice = installId;
              adminSession = true;
              authorized = true;
              esp32.adminDevice = installId;
              await prefs?.setString('admin_device_id', installId!);
              await prefs?.setBool('authorized', true);
            } else {
              await ble.disconnect();
              setState(() { connecting = false; status = '自动认证失败'; });
              return;
            }
          }
      }
      }

      if (!skipPassword && password != null && !autoConnectVerify) {
        // 真实模式：BLE连上后，发送密码给ESP32验证
        if (!simulationMode && bleGateway.readyForWrite) {
          setState(() => status = 'BLE已连接，正在验证密码...');
          String? reply;
          if (selected == AccessMode.admin) {
            for (int retry = 0; retry < 3; retry++) {
              reply = await bleGateway.sendAndWait(utf8.encode('!AUTH $password $installId'), expectPrefix: 'OK');
              if (reply != null && reply.contains('OK')) break;
              if (retry < 2) await Future.delayed(const Duration(milliseconds: 100));
            }
            if (reply != null && reply.contains('OK')) {
              esp32.verifyAdminPassword(password, installId ?? '');
              adminDevice = installId;
              adminSession = true;
              authorized = true;
              esp32.adminDevice = installId;
              await prefs?.setString('admin_device_id', installId!);
              await prefs?.setBool('authorized', true);
            } else {
              await ble.disconnect();
              setState(() { connecting = false; status = '密码错误'; });
              return;
            }
          } else {
            for (int retry = 0; retry < 3; retry++) {
              reply = await bleGateway.sendAndWait(utf8.encode('!VERIFYBORROW $password'), expectPrefix: 'OK');
              if (reply != null && reply.contains('OK')) break;
              if (retry < 2) await Future.delayed(const Duration(milliseconds: 100));
            }
            if (reply != null && reply.contains('OK')) {
              esp32.verifyBorrowPassword(password);
              // 保存临时借车授权状态
              await prefs?.setBool('authorized', true);
              await prefs?.setString('ble_remote_id', target.remoteId);
              await prefs?.setString('access_mode', 'borrower');
              await prefs?.setString('borrow_code', password);
              if (esp32.borrowEnd != null) {
                await prefs?.setInt('borrow_end', esp32.borrowEnd!.millisecondsSinceEpoch);
              }
              authorized = true;
              savedRemoteId = target.remoteId;
            } else {
              await ble.disconnect();
              setState(() { connecting = false; status = '密码错误或已过期'; });
              return;
            }
          }
        } else {
          // 模拟模式：本地验证
          if (selected == AccessMode.admin) {
            if (!esp32.verifyAdminPassword(password, installId ?? '')) {
              setState(() { connecting = false; status = '密码错误'; });
              return;
            }
            adminDevice = installId;
            adminSession = true;
            esp32.adminDevice = installId;
            await prefs?.setString('admin_device_id', installId!);
          } else {
            if (!esp32.verifyBorrowPassword(password)) {
              setState(() { connecting = false; status = '密码错误或已过期'; });
              return;
            }
          }
        }
      }

      if (!mounted) return;
      if (selected == AccessMode.admin) {
        adminDevice = installId;
        adminSession = true;
        esp32.adminDevice = installId;
        await prefs?.setString('admin_device_id', installId!);
      }
      await prefs?.setString('ble_remote_id', target.remoteId);
      savedRemoteId = target.remoteId;
      // 保存访问模式
      await prefs?.setString('access_mode', selected == AccessMode.admin ? 'admin' : 'borrower');
      // 临时借车额外保存借车信息
      if (selected == AccessMode.borrower) {
        await prefs?.setString('borrow_code', password ?? '');
        if (esp32.borrowEnd != null) {
          await prefs?.setInt('borrow_end', esp32.borrowEnd!.millisecondsSinceEpoch);
        }
      }
      setState(() {
        connected = true;
        connecting = false;
        mode = selected;
        timeSynced = false;
        status = simulationMode ? '连接成功，正在同步时间...' : 'BLE真实连接成功，正在同步时间...';
      });
      await syncTime();
      _startHeartbeat();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        connecting = false;
        connected = false;
        status = '连接失败：$error';
      });
    }
  }

  Widget _authChoiceDialog() => TKDialog(
        borderColor: TKColors.neonBlue,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TKPageTitle(title: '选择连接身份'),
            const SizedBox(height: 20),
            TKNeonButton(
              label: '管理员连接',
              icon: Icons.admin_panel_settings,
              neonColor: TKColors.neonBlue,
              onTap: () => Navigator.pop(context, AccessMode.admin),
              height: 52,
            ),
            const SizedBox(height: 12),
            TKNeonButton(
              label: '临时借车连接',
              icon: Icons.key,
              neonColor: TKColors.neonOrange,
              onTap: () => Navigator.pop(context, AccessMode.borrower),
              height: 52,
            ),
          ],
        ),
      );

  Future<String?> _askPassword(AccessMode selected) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TKDialog(
        borderColor: TKColors.neonOrange,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 110, width: double.infinity, child: Image.asset('assets/popup_admin_auth.png', fit: BoxFit.contain)),
            Text(selected == AccessMode.admin ? '管理员密码' : '临时借车密码', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: TKColors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: TKColors.textPrimary, fontSize: 18),
              decoration: InputDecoration(
                hintText: '请输入密码',
                hintStyle: const TextStyle(color: TKColors.textMuted),
                filled: true,
                fillColor: TKColors.bgCard,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TKColors.borderSubtle, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TKColors.neonBlue, width: 2)),
              ),
            ),
            const SizedBox(height: 16),
            TKNeonButton(
              label: '确认',
              icon: Icons.link,
              neonColor: TKColors.neonBlue,
              onTap: () => Navigator.pop(context, passwordController.text.trim()),
              height: 52,
            ),
          ],
        ),
      ),
    );
    if (result == null || result.isEmpty) return null;
    return result;
  }

  Future<void> syncTime() async {
    if (!connected) return;
    if (!simulationMode && bleGateway.readyForWrite) {
      final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final reply = await bleGateway.sendAndWait(utf8.encode('!TIME $ts'), expectPrefix: 'TIME');
      if (reply != null && reply.contains('TIME OK')) {
        setState(() { timeSynced = true; });
        _msg('时间同步成功');
      } else {
        _msg('时间同步失败');
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    if (timeFail) {
      setState(() {
        timeSynced = false;
        espTime = null;
        status = mode == AccessMode.admin ? '时间同步失败：管理员仍可使用' : '时间同步失败：无法确认临时授权有效期';
      });
      _msg('时间同步失败');
      if (mode == AccessMode.admin) {
        authorized = true;
        await prefs?.setBool('authorized', true);
      }
      return;
    }
    esp32.syncTime(DateTime.now());
    setState(() {
      timeSynced = true;
      espTime = esp32.espTime;
      authorized = true;
      status = mode == AccessMode.admin ? '已连接 · 时间同步成功 · 管理员权限已开放' : '已连接 · 时间同步成功 · 临时借车权限已开放';
    });
    await prefs?.setBool('authorized', true);
    _msg('时间同步成功');
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (connected && !simulationMode) {
        queryRssi();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> queryRssi() async {
    if (!connected || simulationMode || !bleGateway.readyForWrite) return;
    try {
      final reply = await bleGateway.sendAndWait(utf8.encode('!RSSI?'), expectPrefix: 'RSSI');
      if (reply != null && reply.startsWith('RSSI:')) {
        final val = int.tryParse(reply.substring(5)) ?? 0;
        if (mounted) setState(() => rssiValue = val);
      }
    } catch (e) {
      debugPrint('queryRssi error: $e');
    }
  }

  Future<void> disconnect() async {
    _stopHeartbeat();
    commandTimer?.cancel();
    if (!simulationMode) {
      await bleGateway.dispose();
      await ble.disconnect();
    }
    if (!mounted) return;
    setState(() {
      connected = false;
      mode = null;
      adminSession = false;
      timeSynced = false;
      espTime = null;
      commandSeconds = 0;
      status = '已断开：车辆功能重新锁定';
    });
    _msg('已断开，车辆功能已锁定');
  }

  Future<void> vehicleCommand(String command) async {
    if (!vehicleEnabled) {
      _msg('未连接，无法执行');
      return;
    }
    late final String protocol;
    final timed = command == '车窗升' || command == '车窗降' || command == '后备箱';
    switch (command) {
      case '锁车':
        protocol = 'suoche';
      case '解锁':
        protocol = 'jiesuo';
      case '寻车':
        protocol = 'xunche';
      case '车窗升':
        protocol = 'chuangsheng';
      case '车窗降':
        protocol = 'chuangjiang';
      default:
        protocol = 'houbeixiang';
    }
    // 真实模式：直接发送，不等回复（ESP32瞬间执行）
    if (!simulationMode && bleGateway.readyForWrite) {
      try {
        await bleGateway.writeCommand(utf8.encode(protocol), withoutResponse: true);
      } catch (e) {
        _msg('$command 发送失败');
        return;
      }
    } else if (!simulationMode && !bleGateway.readyForWrite) {
      _msg('BLE通道未就绪，请重新连接');
      return;
    }
    setState(() { status = '✅ $command 已发送'; });
    _msg(timed ? '$command 已发送（保持4秒）' : '$command 执行成功');
    commandTimer?.cancel();
    if (timed) {
      commandSeconds = 4;
      commandTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) { timer.cancel(); return; }
        if (commandSeconds <= 1) {
          timer.cancel();
          setState(() { commandSeconds = 0; status = '✅ $command 完成'; });
          return;
        }
        setState(() => commandSeconds -= 1);
      });
    } else {
    }
    setState(() => status = timed ? '⏳ $command 4秒保持中（$commandSeconds）' : '✅ $command 成功');
  }

  Future<void> generateBorrowCode() async {
    if (!adminEnabled) { return; }
    final hours = (int.tryParse(hoursController.text.trim()) ?? 24).clamp(0, 168).toInt();
    final code = esp32.generateBorrowCode(hours);
    borrowCode = esp32.borrowCode;
    borrowStart = esp32.borrowStart;
    borrowEnd = esp32.borrowEnd;
    await prefs?.setString('borrow_code', code);
    await prefs?.setInt('borrow_start', borrowStart!.millisecondsSinceEpoch);
    await prefs?.setInt('borrow_end', borrowEnd!.millisecondsSinceEpoch);
    // 真实模式：发送 !BORROW 命令到ESP32
    if (!simulationMode && bleGateway.readyForWrite) {
      final reply = await bleGateway.sendAndWait(utf8.encode('!BORROW $code $hours'), expectPrefix: 'OK');
      if (reply == null || !reply.contains('OK')) {
        _msg('ESP32设置借车码失败');
        return;
      }
    }
    _scheduleBorrowExpiry();
    setState(() => status = '临时借车密码已生成');
    _msg('临时密码已生成：$code');
  }

  Future<void> _clearBorrow() async {
    borrowExpiryTimer?.cancel(); borrowExpiryTimer = null;
    borrowCode = null; borrowStart = null; borrowEnd = null;
    await prefs?.remove('borrow_code');
    await prefs?.remove('borrow_start');
    await prefs?.remove('borrow_end');
    if (!simulationMode && bleGateway.readyForWrite) {
      final reply = await bleGateway.sendAndWait(utf8.encode('!BORROWCLEAR'), expectPrefix: 'OK');
      if (reply == null || !reply.contains('OK')) {
        _msg('ESP32取消借车码失败');
        return;
      }
    }
    _msg('借车授权已取消');
    if (mounted) {
      if (mode == AccessMode.borrower) {
        if (!simulationMode) {
          await ble.disconnect();
        }
        connected = false; mode = null; timeSynced = false; espTime = null;
        status = '临时借车授权已失效，车辆功能重新锁定';
      }
      setState(() {});
    }
  }

  Future<void> _requireAdminAuth(VoidCallback onVerified) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TKColors.bgCard,
        title: const Text('验证管理员密码', style: TextStyle(color: TKColors.textPrimary)),
        content: TextField(controller: ctrl, obscureText: true, keyboardType: TextInputType.number, style: const TextStyle(color: TKColors.textPrimary), decoration: const InputDecoration(hintText: '请输入管理员密码', hintStyle: TextStyle(color: TKColors.textMuted))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text.trim() == adminPassword), child: const Text('确认')),
        ],
      ),
    );
    if (ok == true) {
      onVerified();
    } else {
    }
  }

  Widget vehiclePage() => Scaffold(
        backgroundColor: TKColors.bgPrimary,
        body: SafeArea(
          child: Column(
            children: [
              // 顶部栏（图片自带Tian Key文字，只保留设置/帮助图标）
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => tab = PageTab.settings),
                      child: Icon(Icons.settings, color: TKColors.neonBlue, size: 22),
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
                                '锁车/解锁/后备箱/寻车：\n  点击按钮立即执行\n\n升降窗：\n  点击一次自动保持4秒\n\n深度睡眠：\n  省电模式，定时唤醒\n\n临时借车：\n  生成临时密码借给他人',
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
                      child: Icon(Icons.help_outline, color: TKColors.textMuted, size: 22),
                    ),
                  ],
                ),
              ),

              // 汽车图片区域（图片自带Tian Key文字+车牌号）
              SizedBox(
                height: 170,
                width: double.infinity,
                child: Image.asset(
                  'assets/home_car_bg.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, 0.1),
                ),
              ),

              // 状态卡片 + 功能按钮（可滚动区域）
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            TKStatusCard(icon: Icons.bluetooth, title: '设备', status: connected ? '已连接' : '未连接', statusColor: connected ? TKColors.neonBlue : TKColors.textMuted),
                            TKStatusCard(icon: Icons.shield, title: '管理员', status: adminEnabled ? '已授权' : '未授权', statusColor: adminEnabled ? TKColors.neonOrange : TKColors.textMuted, iconColor: TKColors.neonOrange),
                            TKStatusCard(icon: Icons.signal_cellular_alt, title: '信号', status: connected ? '$rssiValue dBm' : '--', statusColor: connected ? (rssiValue > -60 ? TKColors.neonBlue : rssiValue > -80 ? TKColors.neonOrange : TKColors.neonRed) : TKColors.textMuted, iconColor: TKColors.neonBlue),
                            TKStatusCard(icon: Icons.sync, title: '同步', status: timeSynced ? '已同步' : '未同步', statusColor: timeSynced ? TKColors.neonBlue : TKColors.textMuted, iconColor: TKColors.neonBlue),
                            TKStatusCard(icon: Icons.vpn_key, title: '借车', status: borrowValid ? '有效' : '无', statusColor: borrowValid ? TKColors.neonBlue : TKColors.textMuted, iconColor: TKColors.neonOrange),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Column(
                          children: [
                            if (!connected) ...[
                              // 扫描结果/状态显示
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
                                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: TKColors.neonBlue)),
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
                                          device.name.contains('陕A') ? Icons.directions_car : Icons.bluetooth,
                                          color: device.name.contains('陕A') ? const Color(0xFFFF8800) : const Color(0xFF00E5FF),
                                          size: 20,
                                        ),
                                        title: Text(device.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                        subtitle: Text(device.remoteId, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
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
                              Expanded(child: TKNeonButton(label: connected ? '断开连接' : '快速连接', icon: Icons.bluetooth, neonColor: TKColors.neonBlue, onTap: connected ? () => disconnect() : () => connect(), isEnabled: true)),
                            ]),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(child: TKNeonButton(label: '锁车', icon: Icons.lock, neonColor: TKColors.neonBlue, onTap: vehicleEnabled ? () => vehicleCommand('锁车') : null, isEnabled: vehicleEnabled)),
                              const SizedBox(width: 10),
                              Expanded(child: TKNeonButton(label: '解锁', icon: Icons.lock_open, neonColor: TKColors.neonBlue, onTap: vehicleEnabled ? () => vehicleCommand('解锁') : null, isEnabled: vehicleEnabled)),
                            ]),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(child: TKNeonButton(label: '车窗升', icon: Icons.keyboard_double_arrow_up, neonColor: TKColors.neonOrange, onTap: vehicleEnabled ? () => vehicleCommand('车窗升') : null, isEnabled: vehicleEnabled)),
                              const SizedBox(width: 10),
                              Expanded(child: TKNeonButton(label: '车窗降', icon: Icons.keyboard_double_arrow_down, neonColor: TKColors.neonOrange, onTap: vehicleEnabled ? () => vehicleCommand('车窗降') : null, isEnabled: vehicleEnabled)),
                            ]),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(child: TKNeonButton(label: '寻车', icon: Icons.volume_up, neonColor: TKColors.neonBlue, onTap: vehicleEnabled ? () => vehicleCommand('寻车') : null, isEnabled: vehicleEnabled)),
                              const SizedBox(width: 10),
                              Expanded(child: TKNeonButton(label: '后备箱', icon: Icons.open_in_new, neonColor: TKColors.neonOrange, onTap: vehicleEnabled ? () => vehicleCommand('后备箱') : null, isEnabled: vehicleEnabled)),
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

  Widget borrowPage() => Scaffold(
        backgroundColor: TKColors.bgPrimary,
        body: SafeArea(
          child: Column(
            children: [
              // 顶部栏：返回 | 临时借车 | 网格图标
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TKIconButton(icon: Icons.arrow_back, color: TKColors.neonBlue, onTap: () => setState(() => tab = PageTab.vehicle)),
                    const TKPageTitle(title: '临时借车'),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // 当前状态区
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TKColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: TKColors.borderSubtle, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('当前状态', style: TextStyle(color: TKColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.vpn_key, color: TKColors.neonOrange, size: 24),
                          const SizedBox(width: 12),
                          Text(borrowValid ? borrowCode! : '无有效临时密码', style: const TextStyle(color: TKColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (borrowValid && borrowCode != null) ...[
                        const SizedBox(height: 12),
                        TKNeonButton(
                          label: '复制密码',
                          icon: Icons.content_copy,
                          neonColor: TKColors.neonBlue,
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: borrowCode!));
                            _msg('密码已复制到剪贴板');
                          },
                          isEnabled: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 选择有效时间
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('选择有效时间', style: TextStyle(color: TKColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildTimeSelectButton('5分钟', 0),
                        _buildTimeSelectButton('24小时', 24),
                        _buildTimeSelectButton('48小时', 48),
                        _buildTimeSelectButton('72小时', 72),
                        _buildTimeSelectButton('96小时', 96),
                        _buildTimeSelectButton('120小时', 120),
                        _buildTimeSelectButton('144小时', 144),
                        _buildTimeSelectButton('168小时', 168),
                      ],
                    ),
                  ],
                ),
              ),

              // 临时密码区（虚线边框卡片）
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: TKColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: TKColors.neonBlue.withOpacity(0.5), width: 1.5, style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      Icon(borrowValid ? Icons.vpn_key : Icons.lock, color: TKColors.neonOrange, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        borrowValid && borrowCode != null ? borrowCode! : '尚未生成',
                        style: TextStyle(
                          color: borrowValid ? TKColors.neonBlue : TKColors.textSecondary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TKNeonButton(
                        label: '复制密码',
                        icon: Icons.content_copy,
                        neonColor: TKColors.neonBlue,
                        onTap: borrowValid && borrowCode != null
                            ? () {
                                Clipboard.setData(ClipboardData(text: borrowCode!));
                                _msg('密码已复制到剪贴板');
                              }
                            : null,
                        isEnabled: borrowValid && borrowCode != null,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // 底部双大按钮
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: TKNeonButton(
                        label: '生成临时密码',
                        icon: Icons.vpn_key,
                        neonColor: TKColors.neonBlue,
                        onTap: adminEnabled ? () => generateBorrowCode() : () => {},
                        isEnabled: adminEnabled,
                        height: 56,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: TKNeonButton(
                        label: '取消借车',
                        icon: Icons.cancel,
                        neonColor: TKColors.neonRed,
                        onTap: borrowValid ? () => _clearBorrow() : null,
                        isEnabled: borrowValid,
                      ),
                    ),
                  ],
                ),
              ),

              // 底部导航栏
              TKBottomNav(currentTab: tab, onTabChanged: (t) => setState(() => tab = t)),
            ],
          ),
        ),
      );

// 时间选择按钮
  Widget _buildTimeSelectButton(String label, int hours) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 16 * 2 - 10 * 3) / 4,
      height: 56,
      child: TKNeonButton(
        label: label,
        icon: Icons.access_time,
        neonColor: TKColors.neonBlue,
        onTap: () {
          setState(() {
            hoursController.text = hours.toString();
          });
        },
        isEnabled: true,
      ),
    );
  }

  Widget settingsPage() => Scaffold(
        backgroundColor: TKColors.bgPrimary,
        body: SafeArea(
          child: Column(
            children: [
              // 顶部栏
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

              // 设置列表
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    TKSettingTile(
                      title: '修改密码',
                      leadingIcon: Icons.lock,
                      trailingText: '>',
                      onTap: () => _requireAdminAuth(() => Navigator.push(context, MaterialPageRoute(builder: (ctx) => Builder(builder: (_) => _changeAdminPasswordPage(ctx))))),
                    ),
                    TKSettingTile(
                      title: '设备名称',
                      leadingIcon: Icons.device_hub,
                      trailingText: deviceName,
                      onTap: () => _requireAdminAuth(() => Navigator.push(context, MaterialPageRoute(builder: (ctx) => Builder(builder: (_) => _deviceNamePage(ctx))))),
                    ),
                    TKSettingTile(
                      title: '时间同步设置',
                      leadingIcon: Icons.access_time,
                      trailingText: '>',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => Builder(builder: (_) => _timeSyncPage(ctx)))),
                    ),
                    TKSettingTile(
                      title: '自动连接设置',
                      leadingIcon: Icons.bluetooth_connected,
                      trailingText: autoConnect ? '已开启' : '已关闭',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => Builder(builder: (_) => _autoConnectPage(ctx)))),
                    ),
                    TKSettingTile(
                      title: '模拟模式',
                      leadingIcon: Icons.science,
                      trailingText: simulationMode ? '已开启' : '已关闭',
                      onTap: () {
                        setState(() => simulationMode = !simulationMode);
                        prefs?.setBool('simulation_mode', simulationMode);
                      },
                    ),
                    TKSettingTile(
                      title: '深度睡眠',
                      leadingIcon: Icons.bedtime,
                      trailingText: sleepEnabled ? '已开启' : '已关闭',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => Builder(builder: (_) => _deepSleepPage(ctx)))),
                    ),
                    TKSettingTile(
                      title: '恢复出厂',
                      leadingIcon: Icons.delete_forever,
                      trailingText: '>',
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

              // 底部导航栏
              TKBottomNav(currentTab: tab, onTabChanged: (t) => setState(() => tab = t)),
            ],
          ),
        ),
      );

  // ==================== 设置二级子页面 ====================

  // 1. 修改蓝牙密码

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
        body: SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TKIconButton(icon: Icons.arrow_back, color: TKColors.neonBlue, onTap: () => Navigator.pop(pageCtx)),
            const TKPageTitle(title: '修改管理员密码'),
            const SizedBox(width: 48),
          ])),
          Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
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
              onTap: saving ? null : () async {
                if (currentCtrl.text.trim() != adminPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('当前密码错误', style: const TextStyle(color: Colors.white)), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)));
                  return;
                }
                if (newCtrl.text.trim().length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('新密码至少6位', style: const TextStyle(color: Colors.white)), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)));
                  return;
                }
                if (newCtrl.text.trim() != confirmCtrl.text.trim()) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('两次密码不一致', style: const TextStyle(color: Colors.white)), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)));
                  return;
                }
                setLocalState(() => saving = true);
                try {
                  if (!simulationMode && bleGateway.readyForWrite) {
                    final reply = await bleGateway.sendAndWait(utf8.encode('!PWD ${newCtrl.text.trim()}'));
                    if (reply == null || !reply.contains('OK')) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ESP32修改密码失败', style: const TextStyle(color: Colors.white)), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)));
                      setLocalState(() => saving = false);
                      return;
                    }
                  }
                  adminPassword = newCtrl.text.trim();
                  esp32.changePassword(adminPassword);
                  prefs?.setString('admin_password', adminPassword);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('密码修改成功', style: const TextStyle(color: Colors.white)), backgroundColor: TKColors.neonBlue, duration: const Duration(seconds: 2)));
                  Navigator.pop(pageCtx);
                } catch (e) {
                  setLocalState(() => saving = false);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('修改失败：$e', style: const TextStyle(color: Colors.white)), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)));
                }
              },
              isEnabled: !saving,
            ),
          ])),
        ])),
      ),
    );
  }

  // 设备名称
  Widget _deviceNamePage(BuildContext pageCtx) {
    final ctrl = TextEditingController(text: deviceName);
    bool saving = false;
    return StatefulBuilder(
      builder: (context, setLocalState) => Scaffold(
        backgroundColor: TKColors.bgPrimary,
        body: SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TKIconButton(icon: Icons.arrow_back, color: TKColors.neonBlue, onTap: () => Navigator.pop(pageCtx)),
            const TKPageTitle(title: '设备名称'),
            const SizedBox(width: 48),
          ])),
          Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            const SizedBox(height: 24),
            TKBigIcon(icon: Icons.device_hub, color: TKColors.neonBlue, size: 80),
            const SizedBox(height: 24),
            TKTextField(controller: ctrl, label: '设备名称', hint: '输入设备名称'),
            const SizedBox(height: 12),
            const Text('设备名称将用于蓝牙连接和设备识别', style: TextStyle(color: TKColors.textMuted, fontSize: 12)),
            const SizedBox(height: 32),
            TKNeonButton(
              label: saving ? '正在保存...' : '保存',
              icon: saving ? Icons.hourglass_top : Icons.check,
              neonColor: TKColors.neonBlue,
              onTap: saving ? null : () async {
                final v = ctrl.text.trim();
                if (v.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('名称不能为空', style: const TextStyle(color: Colors.white)), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)));
                  return;
                }
                setLocalState(() => saving = true);
                try {
                  if (!simulationMode && bleGateway.readyForWrite) {
                    final reply = await bleGateway.sendAndWait(utf8.encode('!NAME $v'));
                    if (reply == null || !reply.contains('OK')) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ESP32修改名称失败', style: const TextStyle(color: Colors.white)), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)));
                      setLocalState(() => saving = false);
                      return;
                    }
                  }
                  deviceName = v;
                  prefs?.setString('device_name', v);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('设备名称已更新', style: const TextStyle(color: Colors.white)), backgroundColor: TKColors.neonBlue, duration: const Duration(seconds: 2)));
                  Navigator.pop(pageCtx);
                } catch (e) {
                  setLocalState(() => saving = false);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('修改失败：$e', style: const TextStyle(color: Colors.white)), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)));
                }
              },
              isEnabled: !saving,
            ),
          ])),
        ])),
      ),
    );
  }

  // 4. 时间同步设置
  Widget _timeSyncPage(BuildContext pageCtx) {
    return Scaffold(
      backgroundColor: TKColors.bgPrimary,
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TKIconButton(icon: Icons.arrow_back, color: TKColors.neonBlue, onTap: () => Navigator.pop(pageCtx)),
          const TKPageTitle(title: '时间同步设置'),
          const SizedBox(width: 48),
        ])),
        Expanded(child: StatefulBuilder(builder: (context, setLocalState) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TKBigIcon(icon: Icons.access_time, color: TKColors.neonBlue, size: 80),
          const SizedBox(height: 24),
          const Text('当前状态', style: TextStyle(color: TKColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Text(timeSynced ? '✅ 已同步' : '❌ 未同步', style: TextStyle(color: timeSynced ? TKColors.neonBlue : TKColors.neonOrange, fontSize: 22, fontWeight: FontWeight.bold)),
          if (espTime != null) Text('同步时间：$espTime', style: const TextStyle(color: TKColors.textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('模拟同步失败', style: TextStyle(color: TKColors.textSecondary, fontSize: 13)),
            const SizedBox(width: 8),
            Switch(value: timeFail, onChanged: (v) { setLocalState(() {}); setState(() => timeFail = v); prefs?.setBool('time_fail', v); }, activeColor: TKColors.neonOrange),
          ]),
          const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: TKNeonButton(label: '立即同步', icon: Icons.sync, neonColor: TKColors.neonBlue, onTap: connected ? () async { await syncTime(); setLocalState(() {}); } : null, isEnabled: connected)),
          const SizedBox(height: 16),
          const Text('同步后将自动校准设备时间', style: TextStyle(color: TKColors.textMuted, fontSize: 12)),
          const Text('开启"模拟同步失败"可测试时间同步失败场景', style: TextStyle(color: TKColors.textMuted, fontSize: 11)),
        ])))),
      ])),
    );
  }

  // 5. 自动连接设置
  Widget _autoConnectPage(BuildContext pageCtx) {
    return Scaffold(
      backgroundColor: TKColors.bgPrimary,
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TKIconButton(icon: Icons.arrow_back, color: TKColors.neonBlue, onTap: () => Navigator.pop(pageCtx)),
          const TKPageTitle(title: '自动连接设置'),
          const SizedBox(width: 48),
        ])),
        Expanded(child: StatefulBuilder(builder: (context, setLocalState) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TKBigIcon(icon: Icons.bluetooth_connected, color: TKColors.neonBlue, size: 80),
          const SizedBox(height: 24),
          TKSwitchTile(
            title: '自动连接',
            subtitle: '开启后，APP启动时将自动连接已配对设备',
            value: autoConnect,
            onChanged: (v) { setLocalState(() {}); setState(() { autoConnect = v; }); prefs?.setBool('auto_connect', v); },
            leadingIcon: Icons.bluetooth,
          ),
        ])))),
      ])),
    );
  }

  // 6.5 深度睡眠设置
  Widget _deepSleepPage(BuildContext pageCtx) {
    final hoursCtrl = TextEditingController(text: sleepHours.toString());
    final minutesCtrl = TextEditingController(text: sleepMinutes.toString());
    final wakeCtrl = TextEditingController(text: wakeMinutes.toString());
    return Scaffold(
      backgroundColor: TKColors.bgPrimary,
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TKIconButton(icon: Icons.arrow_back, color: TKColors.neonBlue, onTap: () => Navigator.pop(pageCtx)),
          const TKPageTitle(title: '深度睡眠设置'),
          const SizedBox(width: 48),
        ])),
        Expanded(child: StatefulBuilder(builder: (context, setLocalState) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TKBigIcon(icon: Icons.bedtime, color: TKColors.neonBlue, size: 80),
          const SizedBox(height: 24),
          TKSwitchTile(
            title: '深度睡眠',
            subtitle: '开启后，车熄火时ESP32进入深度睡眠省电',
            value: sleepEnabled,
            onChanged: (v) { setLocalState(() {}); setState(() { sleepEnabled = v; }); prefs?.setBool('sleep_enabled', v); },
            leadingIcon: Icons.power_settings_new,
          ),
          const SizedBox(height: 16),
          if (sleepEnabled) ...[
            const Text('睡眠时长', style: TextStyle(color: TKColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 80, child: TextField(
                controller: hoursCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(color: TKColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  fillColor: TKColors.bgCard,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: TKColors.borderSubtle)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: TKColors.borderSubtle)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: TKColors.neonBlue)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (v) { sleepHours = int.tryParse(v) ?? 0; },
              )),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('小时', style: TextStyle(color: TKColors.textSecondary, fontSize: 14))),
              SizedBox(width: 80, child: TextField(
                controller: minutesCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(color: TKColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  fillColor: TKColors.bgCard,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: TKColors.borderSubtle)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: TKColors.borderSubtle)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: TKColors.neonBlue)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (v) { sleepMinutes = int.tryParse(v) ?? 0; },
              )),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('分钟', style: TextStyle(color: TKColors.textSecondary, fontSize: 14))),
            ]),
            const SizedBox(height: 16),
            Text(
              '总计 ${sleepHours}小时${sleepMinutes}分钟',
              style: const TextStyle(color: TKColors.neonBlue, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text('唤醒时长', style: TextStyle(color: TKColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('醒来后广播蓝牙多久（分钟）', style: TextStyle(color: TKColors.textMuted, fontSize: 12)),
            const SizedBox(height: 12),
            SizedBox(width: 120, child: TextField(
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(color: TKColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                fillColor: TKColors.bgCard,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: TKColors.borderSubtle)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: TKColors.borderSubtle)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: TKColors.neonBlue)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixText: '分钟',
                suffixStyle: const TextStyle(color: TKColors.textSecondary, fontSize: 14),
              ),
              controller: wakeCtrl,
              onChanged: (v) { wakeMinutes = int.tryParse(v) ?? 30; },
            )),
          ],
          const SizedBox(height: 24),
          Text(
            esp32Sleeping ? '当前状态: 睡眠中 💤' : '当前状态: 已唤醒 ✅',
            style: TextStyle(color: esp32Sleeping ? TKColors.neonOrange : TKColors.neonBlue, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: TKNeonButton(
            label: '保存设置',
            icon: Icons.save,
            neonColor: TKColors.neonBlue,
            isEnabled: connected,
            onTap: connected ? () async {
              final totalMinutes = sleepHours * 60 + sleepMinutes;
              if (totalMinutes <= 0) {
                return;
              }
              if (!simulationMode && bleGateway.readyForWrite) {
                final reply = await bleGateway.sendAndWait(utf8.encode('!SLEEP $totalMinutes'), expectPrefix: 'OK');
                if (reply == null || !reply.contains('OK')) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('睡眠设置失败', style: const TextStyle(color: Colors.white)), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)));
                  return;
                }
                final wakeReply = await bleGateway.sendAndWait(utf8.encode('!WAKE $wakeMinutes'), expectPrefix: 'OK');
                if (wakeReply == null || !wakeReply.contains('OK')) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('唤醒设置失败', style: const TextStyle(color: Colors.white)), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)));
                  return;
                }
              }
              await prefs?.setInt('sleep_hours', sleepHours);
              await prefs?.setInt('sleep_minutes', sleepMinutes);
              await prefs?.setInt('wake_minutes', wakeMinutes);
              setState(() { esp32Sleeping = true; });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('睡眠设置已保存', style: const TextStyle(color: Colors.white)), backgroundColor: TKColors.neonBlue, duration: const Duration(seconds: 2)));
            } : null,
          )),
          const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: TKNeonButton(
            label: '立即唤醒',
            icon: Icons.alarm,
            neonColor: TKColors.neonOrange,
            isEnabled: connected,
            onTap: connected ? () async {
              if (!simulationMode && bleGateway.readyForWrite) {
                final reply = await bleGateway.sendAndWait(utf8.encode('!SLEEP 0'), expectPrefix: 'OK');
                if (reply == null || !reply.contains('OK')) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('唤醒失败', style: const TextStyle(color: Colors.white)), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)));
                  return;
                }
              }
              setState(() { sleepEnabled = false; esp32Sleeping = false; });
              setLocalState(() {});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已唤醒', style: const TextStyle(color: Colors.white)), backgroundColor: TKColors.neonBlue, duration: const Duration(seconds: 2)));
            } : null,
          )),
          const SizedBox(height: 16),
          const Text('设为0可关闭深度睡眠', style: TextStyle(color: TKColors.textMuted, fontSize: 12)),
          const Text('睡眠期间蓝牙关闭，定时醒来检查连接', style: TextStyle(color: TKColors.textMuted, fontSize: 12)),
        ])))),
      ])),
    );
  }

  // 7. 恢复出厂
  Widget _factoryResetPage(BuildContext pageCtx) {
    return Scaffold(
      backgroundColor: TKColors.bgPrimary,
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TKIconButton(icon: Icons.arrow_back, color: TKColors.neonBlue, onTap: () => Navigator.pop(pageCtx)),
          const TKPageTitle(title: '恢复出厂'),
          const SizedBox(width: 48),
        ])),
        Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.warning_amber_rounded, color: TKColors.neonRed, size: 80),
          const SizedBox(height: 24),
          const Text('此操作将清除所有管理员绑定、授权状态、\n临时借车授权和已保存 BLE 设备，\n并恢复为未绑定初始状态。', style: TextStyle(color: TKColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: TKNeonButton(label: '确认恢复出厂', icon: Icons.delete_forever, neonColor: TKColors.neonRed, onTap: () async {
            final ctrl = TextEditingController();
            final ok = await showDialog<bool>(context: pageCtx, builder: (ctx) => AlertDialog(
              backgroundColor: TKColors.bgCard,
              title: const Text('验证管理员密码', style: TextStyle(color: TKColors.textPrimary)),
              content: TextField(controller: ctrl, obscureText: true, keyboardType: TextInputType.number, style: const TextStyle(color: TKColors.textPrimary), decoration: const InputDecoration(hintText: '请输入管理员密码', hintStyle: TextStyle(color: TKColors.textMuted))),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim() == adminPassword), child: const Text('确认')),
              ],
            ));
            if (ok == true) {
              if (!simulationMode && bleGateway.readyForWrite) {
                final reply = await bleGateway.sendAndWait(utf8.encode('!RESET'), expectPrefix: 'OK');
                if (reply == null || reply.contains('ERR')) {
                  ScaffoldMessenger.of(pageCtx).showSnackBar(SnackBar(content: Text('ESP32恢复出厂失败，请重试', style: const TextStyle(color: Colors.white)), backgroundColor: TKColors.neonRed, duration: const Duration(seconds: 2)));
                  return;
                }
              }
              if (!simulationMode) await ble.disconnect();
              esp32.factoryReset();
              await prefs?.clear();
              ScaffoldMessenger.of(pageCtx).showSnackBar(SnackBar(content: Text('已恢复出厂设置', style: const TextStyle(color: Colors.white)), backgroundColor: TKColors.neonBlue, duration: const Duration(seconds: 2)));
              adminPassword = defaultPassword;
              adminDevice = null; savedRemoteId = null; authorized = false; autoConnect = true; simulationMode = false;
              deviceName = defaultName; borrowCode = null; borrowStart = null; borrowEnd = null;
              connected = false; foundDevice = null; mode = null; adminSession = false; timeSynced = false;
              final newId = 'TK-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1000000)}';
              installId = newId;
              await prefs?.setString('install_id', newId);
              Navigator.pop(pageCtx);
            } else {
            }
          }, isEnabled: true)),
        ]))),
      ])),
    );
  }

  // 8. 关于系统
  Widget _aboutPage() {
    return Scaffold(
      backgroundColor: TKColors.bgPrimary,
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TKIconButton(icon: Icons.arrow_back, color: TKColors.neonBlue, onTap: () => Navigator.pop(context)),
          const TKPageTitle(title: '关于系统'),
          const SizedBox(width: 48),
        ])),
        Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TKBigIcon(icon: Icons.directions_car_filled, color: TKColors.neonBlue, size: 100),
          const SizedBox(height: 16),
          const TKLogoText(text: 'Tian Key', fontSize: 28),
          const SizedBox(height: 8),
          const Text('Tian Key 智能车钥匙控制系统', style: TextStyle(color: TKColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 32),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: TKColors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: TKColors.borderSubtle)),
            child: Column(children: [
              _infoRow('车型', '马自达昂克赛拉'),
              _infoRow('车牌', deviceName),
              _infoRow('设备ID', installId ?? '未知'),
              const Divider(color: TKColors.divider, height: 20),
              _infoRow('连接状态', connected ? '已连接' : '未连接'),
              _infoRow('管理员', adminEnabled ? '已授权' : '未授权'),
              _infoRow('模拟模式', simulationMode ? '已开启' : '已关闭'),
              _infoRow('版本', '1.0.0+1'),
            ]),
          ),
          const SizedBox(height: 24),
          const Text('© 2026 Tian Key Team', style: TextStyle(color: TKColors.textMuted, fontSize: 12)),
        ]))),
      ])),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: TKColors.textSecondary, fontSize: 13)),
      Text(value, style: const TextStyle(color: TKColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
    ]));
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) return const Scaffold(backgroundColor: Color(0xFF02060D), body: Center(child: CircularProgressIndicator()));
    if (!splashDone) {
      return Scaffold(
        backgroundColor: const Color(0xFF080B10),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120, height: 120,
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
      case PageTab.vehicle: return vehiclePage();
      case PageTab.borrow: return borrowPage();
      case PageTab.settings: return settingsPage();
      default: return vehiclePage();
    }
  }
}
