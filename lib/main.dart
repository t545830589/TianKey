import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ble_service.dart';

// ==================== Tian Key V4 视觉常量 ====================
class TKColors {
  // 背景底色
  static const Color bgPrimary = Color(0xFF080B10);       // 极客黑
  static const Color bgCard = Color(0xFF0C1118);          // 卡片/面板深色
  static const Color bgPanel = Color(0xFF0A1018);         // 面板次级

  // 科技蓝（主色/选中）
  static const Color neonBlue = Color(0xFF00E5FF);        // 发光电光蓝
  static const Color neonBlueDark = Color(0xFF0072FF);    // 深电光蓝
  static const Color neonBlueSoft = Color(0xFF00E5FF);    // 柔光蓝

  // 科技橙（警告/车窗/管理员）
  static const Color neonOrange = Color(0xFFFF8800);      // 发光金橙
  static const Color neonOrangeDark = Color(0xFFE67700);

  // 警示红（取消/重置/危险）
  static const Color neonRed = Color(0xFFFF2A2A);         // 发光红
  static const Color neonRedDark = Color(0xFFE61A1A);

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
  static const Color borderNeonBlue = Color(0xFF00E5FF);
  static const Color borderNeonOrange = Color(0xFFFF8800);
  static const Color borderNeonRed = Color(0xFFFF2A2A);
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
    final Color effectiveColor = isEnabled ? neonColor : TKColors.disabled;
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
      height: 60,
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

// 车牌标签
class TKLicensePlate extends StatelessWidget {
  final String plate;

  const TKLicensePlate({super.key, required this.plate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TKColors.neonBlue.withOpacity(0.6), width: 1.5),
        boxShadow: [BoxShadow(color: TKColors.neonBlue.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)],
      ),
      child: Text(
        plate,
        style: const TextStyle(color: TKColors.neonBlue, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
      ),
    );
  }
}

// 虚线边框卡片（临时密码区用）
class TKDashedCard extends StatelessWidget {
  final Widget child;
  final Color dashColor;
  final double dashWidth;
  final double dashGap;

  const TKDashedCard({super.key, required this.child, this.dashColor = TKColors.neonBlue, this.dashWidth = 6, this.dashGap = 4});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color: dashColor, strokeWidth: 2, dashWidth: dashWidth, dashGap: dashGap, radius: 12),
      child: Padding(padding: const EdgeInsets.all(2), child: child),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final double radius;

  _DashedRectPainter({required this.color, required this.strokeWidth, required this.dashWidth, required this.dashGap, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    final r = radius;
    final w = size.width;
    final h = size.height;

    // 画虚线圆角矩形
    void drawDashedLine(Offset p1, Offset p2) {
      final distance = (p2 - p1).distance;
      final dashCount = (distance / (dashWidth + dashGap)).floor();
      for (int i = 0; i < dashCount; i++) {
        final start = p1 + (p2 - p1) * (i * (dashWidth + dashGap) / distance);
        final end = p1 + (p2 - p1) * ((i * (dashWidth + dashGap) + dashWidth) / distance);
        canvas.drawLine(start, end, Paint()..color = color..strokeWidth = strokeWidth..style = PaintingStyle.stroke);
      }
    }

    // 四条边 + 圆角（简化：用直线近似）
    drawDashedLine(Offset(r, 0), Offset(w - r, 0));
    drawDashedLine(Offset(w, r), Offset(w, h - r));
    drawDashedLine(Offset(w - r, h), Offset(r, h));
    drawDashedLine(Offset(0, h - r), Offset(0, r));
    // 圆角用贝塞尔近似（简化忽略，或用 arcTo）
  }

  // 简化：直接用虚线矩形无圆角
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 简化版虚线卡片（用 Container + 装饰器近似）
class TKDashedBorderCard extends StatelessWidget {
  final Widget child;
  final Color borderColor;

  const TKDashedBorderCard({super.key, required this.child, this.borderColor = TKColors.neonBlue});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor.withOpacity(0.5), width: 1.5, style: BorderStyle.solid), // 简化用实线，如需虚线需 CustomPaint
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
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

// 空状态占位
class TKEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const TKEmptyState({super.key, required this.message, this.icon = Icons.inbox, this.color = TKColors.textMuted});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color.withOpacity(0.5), size: 48),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: color, fontSize: 14)),
        ],
      ),
    );
  }
}

// 加载指示器
class TKLoader extends StatelessWidget {
  final Color color;
  final double size;

  const TKLoader({super.key, this.color = TKColors.neonBlue, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
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
    dialogTheme: DialogThemeData(
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

enum PageTab { vehicle, borrow, settings, admin }
enum AccessMode { admin, borrower }

class TianKeyHome extends StatefulWidget {
  const TianKeyHome({super.key});

  @override
  State<TianKeyHome> createState() => _TianKeyHomeState();
}

class _TianKeyHomeState extends State<TianKeyHome> {
  static const defaultPassword = '13092991951';
  static const legacyPhoneId = 'PHONE-TIANKY-01';
  static const defaultName = '陕A0P92Y';

  final TianKeyBleService ble = TianKeyBleService();
  final List<String> logs = <String>[];
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController hoursController = TextEditingController(text: '2');

  SharedPreferences? prefs;
  PageTab tab = PageTab.vehicle;
  AccessMode? mode;
  BleScanItem? foundDevice;
  Timer? borrowExpiryTimer;
  Timer? commandTimer;

  bool ready = false;
  bool scanning = false;
  bool connecting = false;
  bool connected = false;
  bool authorized = true;
  bool adminSession = false;
  bool autoConnect = true;
  bool sound = true;
  bool locked = true;
  bool timeSynced = false;
  bool timeFail = false;
  int commandSeconds = 0;
  String activeCommand = '';
  String deviceName = defaultName;
  String adminPassword = defaultPassword;
  String? installId;
  String? adminDevice;
  String? savedRemoteId;
  String? borrowCode;
  DateTime? borrowStart;
  DateTime? borrowEnd;
  DateTime? espTime;
  String status = '系统待机：车辆功能锁定，请先进行蓝牙扫描';
  String lastCommand = '';

  bool get borrowValid {
    if (borrowCode == null || borrowStart == null || borrowEnd == null) return false;
    final now = DateTime.now();
    return !now.isBefore(borrowStart!) && now.isBefore(borrowEnd!);
  }

  bool get adminEnabled => connected && mode == AccessMode.admin && adminSession;

  bool get vehicleEnabled => connected && authorized &&
      ((mode == AccessMode.admin && adminSession) ||
          (mode == AccessMode.borrower && borrowValid));

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    borrowExpiryTimer?.cancel();
    commandTimer?.cancel();
    passwordController.dispose();
    newPasswordController.dispose();
    nameController.dispose();
    hoursController.dispose();
    unawaited(ble.dispose());
    super.dispose();
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
    authorized = p.getBool('authorized') ?? true;
    autoConnect = p.getBool('auto_connect') ?? true;
    sound = p.getBool('sound') ?? true;
    ready = true;
    _cleanupOldLogs();
    _log('APP启动');
    _scheduleBorrowExpiry();
    if (borrowEnd != null && !DateTime.now().isBefore(borrowEnd!)) {
      await _clearBorrow(logExpiry: true);
    }
    if (mounted) setState(() {});
  }

  void _log(String message) {
    logs.add('${DateTime.now()} $message');
    while (logs.length > 200) logs.removeAt(0);
    _cleanupOldLogs();
  }

  void _cleanupOldLogs() {
    if (logs.isEmpty) return;
    final now = DateTime.now();
    logs.removeWhere((entry) {
      try {
        final entryDate = DateTime.parse(entry.split(' ').first);
        return entryDate.isBefore(now.subtract(const Duration(days: 7)));
      } catch (_) {
        return false;
      }
    });
    while (logs.length > 200) logs.removeAt(0);
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: TKColors.textPrimary)),
      backgroundColor: TKColors.bgCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: TKColors.neonBlue, width: 1)),
    ));
  }

  void _scheduleBorrowExpiry() {
    borrowExpiryTimer?.cancel();
    final end = borrowEnd;
    if (end == null) return;
    final delay = end.difference(DateTime.now());
    if (delay <= Duration.zero) {
      unawaited(_clearBorrow(logExpiry: true));
      return;
    }
    borrowExpiryTimer = Timer(delay, () => unawaited(_clearBorrow(logExpiry: true)));
  }

  Future<void> scan() async {
    if (!ready || scanning || connecting || connected) return;
    setState(() {
      scanning = true;
      foundDevice = null;
      status = '正在扫描 BLE 设备...';
    });
    _log('BLE真实扫描开始');
    try {
      if (!await ble.isSupported()) {
        throw StateError('当前手机不支持 BLE');
      }
      final devices = await ble.scan();
      if (!mounted) return;
      if (devices.isEmpty) {
        setState(() => status = 'BLE扫描结束：未发现设备');
        _log('BLE扫描结束：未发现设备');
        _message('未发现 BLE 设备，请确认 ESP32 正在广播');
        return;
      }
      final selected = devices.length == 1 ? devices.first : await _chooseBleDevice(devices);
      if (selected == null || !mounted) return;
      foundDevice = selected;
      savedRemoteId = selected.remoteId;
      await prefs?.setString('ble_remote_id', selected.remoteId);
      setState(() => status = '发现设备：${selected.name}');
      _log('发现 BLE：${selected.name} / ${selected.remoteId}');
      _message('发现 ${selected.name}');
    } catch (error) {
      if (!mounted) return;
      setState(() => status = 'BLE扫描失败：$error');
      _log('BLE扫描失败：$error');
      _message('BLE扫描失败：$error');
    } finally {
      if (mounted) setState(() => scanning = false);
    }
  }

  Future<BleScanItem?> _chooseBleDevice(List<BleScanItem> devices) {
    return showDialog<BleScanItem>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF06101D),
        title: const Text('选择 BLE 设备'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final item = devices[index];
              return ListTile(
                leading: const Icon(Icons.bluetooth, color: Color(0xFF1595FF)),
                title: Text(item.name),
                subtitle: Text(item.remoteId),
                onTap: () => Navigator.pop(context, item),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> connect() async {
    if (connecting || connected) return;
    final target = foundDevice;
    if (target == null) {
      await scan();
      return;
    }
    if (autoConnect && authorized && adminDevice != null && adminDevice == installId) {
      await _connectBle(target, AccessMode.admin, skipPassword: true);
      return;
    }
    final selected = await showDialog<AccessMode>(
      context: context,
      builder: (context) => _authChoiceDialog(),
    );
    if (selected == null || !mounted) return;
    passwordController.clear();
    final ok = await _verify(selected);
    if (!ok || !mounted) return;
    await _connectBle(target, selected);
  }

  Future<void> _connectBle(BleScanItem target, AccessMode selected, {bool skipPassword = false}) async {
    if (connecting || connected) return;
    if (selected == AccessMode.admin && !skipPassword && adminDevice != null && adminDevice != installId && adminDevice != legacyPhoneId) {
      _message('当前管理员席位已被其他设备占用');
      _log('管理员席位拒绝：${adminDevice!}');
      return;
    }
    setState(() {
      connecting = true;
      status = '认证成功，正在建立真实 BLE 连接...';
    });
    try {
      await ble.connect(target.device);
      if (!mounted) return;
      if (selected == AccessMode.admin) {
        adminDevice = installId;
        adminSession = true;
        await prefs?.setString('admin_device_id', installId!);
      }
      await prefs?.setString('ble_remote_id', target.remoteId);
      savedRemoteId = target.remoteId;
      setState(() {
        connected = true;
        connecting = false;
        mode = selected;
        timeSynced = false;
        status = 'BLE真实连接成功，正在同步时间...';
      });
      _log('BLE真实连接成功：${target.name} / ${target.remoteId}');
      await syncTime();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        connecting = false;
        connected = false;
        status = 'BLE连接失败：$error';
      });
      _log('BLE连接失败：$error');
      _message('BLE连接失败：$error');
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

  Future<bool> _verify(AccessMode selected) async {
    final result = await showDialog<bool>(
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
              label: '验证并连接',
              icon: Icons.link,
              neonColor: TKColors.neonBlue,
              onTap: () {
                final value = passwordController.text.trim();
                final seatBlocked = selected == AccessMode.admin && adminDevice != null && adminDevice != installId && adminDevice != legacyPhoneId;
                final ok = !seatBlocked && (selected == AccessMode.admin ? value == adminPassword : borrowValid && value == borrowCode);
                if (ok) {
                  Navigator.pop(context, true);
                } else {
                  _message(seatBlocked ? '管理员席位已被占用' : '密码错误、授权无效或临时密码已过期');
                  _log('认证失败');
                }
              },
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> syncTime() async {
    if (!connected) return;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    if (timeFail) {
      setState(() {
        timeSynced = false;
        espTime = null;
        status = mode == AccessMode.admin ? '时间同步失败：管理员仍可使用' : '时间同步失败：无法确认临时授权有效期';
      });
      _log('时间同步失败（真实ESP32时间协议尚未接入）');
      return;
    }
    setState(() {
      timeSynced = true;
      espTime = DateTime.now();
      status = mode == AccessMode.admin ? '已连接 · 时间同步成功 · 管理员权限已开放' : '已连接 · 时间同步成功 · 临时借车权限已开放';
    });
    _log('APP时间状态已同步；ESP32实际写时协议待硬件协议接入');
  }

  Future<void> disconnect() async {
    commandTimer?.cancel();
    await ble.disconnect();
    if (!mounted) return;
    setState(() {
      connected = false;
      mode = null;
      adminSession = false;
      timeSynced = false;
      espTime = null;
      commandSeconds = 0;
      activeCommand = '';
      status = 'BLE已断开：车辆功能重新锁定';
    });
    _log('BLE真实断开，安全保护');
    _message('BLE已断开，车辆功能已锁定');
  }

  void vehicleCommand(String command) {
    if (!vehicleEnabled) {
      _message('当前没有车辆控制权限');
      _log('拒绝车辆指令 $command');
      return;
    }
    late final String protocol;
    late final String detail;
    late final int gpio;
    final timed = command == '升窗' || command == '降窗' || command == '后备箱';
    switch (command) {
      case '锁车':
        protocol = 'suoche'; gpio = 12; detail = 'GPIO12 锁车脉冲'; locked = true;
      case '解锁':
        protocol = 'jiesuo'; gpio = 13; detail = 'GPIO13 解锁脉冲'; locked = false;
      case '寻车':
        protocol = 'xunche'; gpio = 12; detail = 'GPIO12 连续两次锁车脉冲';
      case '升窗':
        protocol = 'chuangsheng'; gpio = 12; detail = 'GPIO12 保持7秒';
      case '降窗':
        protocol = 'chuangjiang'; gpio = 13; detail = 'GPIO13 保持7秒';
      default:
        protocol = 'houbeixiang'; gpio = 14; detail = 'GPIO14 保持7秒';
    }
    commandTimer?.cancel();
    if (timed) {
      commandSeconds = 7;
      activeCommand = command;
      commandTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) { timer.cancel(); return; }
        if (commandSeconds <= 1) {
          timer.cancel();
          setState(() { commandSeconds = 0; activeCommand = ''; status = '$command 7秒动作完成：$detail'; });
          _log('$protocol 7秒 APP动作完成；真实GPIO发送待协议接入');
          return;
        }
        setState(() => commandSeconds -= 1);
      });
    }
    lastCommand = '$protocol → GPIO$gpio → $detail';
    setState(() => status = timed ? '$command 已开始：7秒保持中（$commandSeconds）' : '$command 已发送：$lastCommand');
    _log('APP记录指令：$lastCommand；真实ESP32指令帧待协议接入');
    _message(timed ? '$command\n7秒保持中' : '$command\n$detail');
  }

  Future<void> generateBorrowCode() async {
    if (!adminEnabled) { _message('请先完成管理员认证'); return; }
    final hours = (int.tryParse(hoursController.text.trim()) ?? 2).clamp(1, 24).toInt();
    final code = (100000 + Random().nextInt(900000)).toString();
    final start = DateTime.now();
    final end = start.add(Duration(hours: hours));
    borrowCode = code; borrowStart = start; borrowEnd = end;
    await prefs?.setString('borrow_code', code);
    await prefs?.setInt('borrow_start', start.millisecondsSinceEpoch);
    await prefs?.setInt('borrow_end', end.millisecondsSinceEpoch);
    _scheduleBorrowExpiry();
    _log('生成临时借车密码');
    setState(() => status = '临时借车密码已生成');
    _message('临时密码：$code\n有效期：$hours 小时');
  }

  Future<void> _clearBorrow({bool logExpiry = false}) async {
    final hadCode = borrowCode != null;
    borrowExpiryTimer?.cancel(); borrowExpiryTimer = null;
    borrowCode = null; borrowStart = null; borrowEnd = null;
    await prefs?.remove('borrow_code');
    await prefs?.remove('borrow_start');
    await prefs?.remove('borrow_end');
    if (logExpiry && hadCode) _log('临时借车密码已到期并清除');
    if (mounted) {
      if (mode == AccessMode.borrower) {
        await ble.disconnect();
        connected = false; mode = null; timeSynced = false; espTime = null;
        status = '临时借车授权已失效，车辆功能重新锁定';
      }
      setState(() {});
    }
  }

  Future<void> toggleAuthorization() async {
    if (!adminEnabled) { _message('请先完成管理员认证'); return; }
    authorized = !authorized;
    await prefs?.setBool('authorized', authorized);
    _log(authorized ? '恢复设备授权' : '关闭设备授权');
    setState(() => status = authorized ? '授权已恢复：管理员会话仍有效，车辆功能已开放' : '授权已关闭：车辆锁定，但管理员会话保留，可再次打开授权');
    _message(authorized ? '授权已恢复' : '授权已关闭，管理员会话保留');
  }

  Future<void> changePassword() async {
    if (!adminEnabled) { _message('请先完成管理员认证'); return; }
    newPasswordController.clear();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => TKDialog(
        borderColor: TKColors.neonBlue,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TKPageTitle(title: '修改管理员/蓝牙密码'),
            const SizedBox(height: 16),
            TKTextField(controller: newPasswordController, label: '新密码', hint: '输入新密码', obscureText: true, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TKTextField(controller: TextEditingController(), label: '确认新密码', hint: '再次输入新密码', obscureText: true, keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: TKNeonButton(label: '取消', icon: Icons.cancel, neonColor: TKColors.textMuted, onTap: () => Navigator.pop(context), isEnabled: true, neonColor: TKColors.textMuted)),
                const SizedBox(width: 12),
                Expanded(child: TKNeonButton(label: '保存', icon: Icons.check, neonColor: TKColors.neonBlue, onTap: () => Navigator.pop(context, true), isEnabled: true)),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final value = newPasswordController.text.trim();
    if (value.length < 6) { _message('密码至少6位'); return; }
    adminPassword = value;
    await prefs?.setString('admin_password', value);
    _log('管理员密码已保存到APP状态；ESP32实际持久化协议待接入');
    setState(() {});
    _message('新密码已生效，旧密码失效');
  }

Future<void> changeDeviceName() async {
    if (!adminEnabled) { _message('请先完成管理员认证'); return; }
    nameController.text = deviceName;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => TKDialog(
        borderColor: TKColors.neonBlue,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TKPageTitle(title: '修改设备名称'),
            const SizedBox(height: 16),
            TKTextField(controller: nameController, label: 'BLE设备名称', hint: '输入设备名称'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: TKNeonButton(label: '取消', icon: Icons.cancel, neonColor: TKColors.textMuted, onTap: () => Navigator.pop(context), isEnabled: true, neonColor: TKColors.textMuted)),
                const SizedBox(width: 12),
                Expanded(child: TKNeonButton(label: '保存', icon: Icons.check, neonColor: TKColors.neonBlue, onTap: () => Navigator.pop(context, true), isEnabled: true)),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final value = nameController.text.trim();
    if (value.isEmpty) return;
    deviceName = value;
    await prefs?.setString('device_name', value);
    _log('设备名称已保存到APP状态；ESP32实际广播名称修改待协议接入');
    setState(() {});
    _message('设备名称已更新');
  }

  Future<void> factoryReset() async {
    if (!adminEnabled) { _message('请先完成管理员认证'); return; }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => TKDialog(
        borderColor: TKColors.neonRed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TKPageTitle(title: '恢复出厂'),
            const SizedBox(height: 16),
            const Icon(Icons.warning_amber_rounded, color: TKColors.neonRed, size: 48),
            const SizedBox(height: 16),
            const Text('此操作将清除所有管理员绑定、授权状态、临时借车授权和已保存 BLE 设备，并恢复为未绑定初始状态。', style: TextStyle(color: TKColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: TKNeonButton(label: '取消', icon: Icons.cancel, neonColor: TKColors.textMuted, onTap: () => Navigator.pop(context), isEnabled: true, neonColor: TKColors.textMuted)),
                const SizedBox(width: 12),
                Expanded(child: TKNeonButton(label: '确认恢复出厂', icon: Icons.delete_forever, neonColor: TKColors.neonRed, onTap: () => Navigator.pop(context, true), isEnabled: true)),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await ble.disconnect();
    await prefs?.clear();
    adminPassword = defaultPassword;
    adminDevice = null; savedRemoteId = null; authorized = true; autoConnect = true; sound = true;
    deviceName = defaultName; borrowCode = null; borrowStart = null; borrowEnd = null;
    connected = false; foundDevice = null; mode = null; adminSession = false; timeSynced = false;
    final newId = 'TK-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1000000)}';
    installId = newId;
    await prefs?.setString('install_id', newId);
    _log('恢复出厂');
    if (mounted) setState(() { status = '已恢复未绑定初始状态'; tab = PageTab.vehicle; });
    _message('恢复出厂完成，管理员初始密码恢复为13092991951');
  }

  void _toggleAutoConnect() async { autoConnect = !autoConnect; await prefs?.setBool('auto_connect', autoConnect); _log(autoConnect ? '自动连接开启' : '自动连接关闭'); setState(() {}); }
  void _toggleSound() async { sound = !sound; await prefs?.setBool('sound', sound); _log(sound ? '声音反馈开启' : '声音反馈关闭'); setState(() {}); }

  InputDecoration _field(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF030A13),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1595FF))),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF8A1C), width: 2)),
      );

  Widget _dialogButton(String text, IconData icon, Color color, VoidCallback onPressed) => SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(text), style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.black)),
      );

  Widget _transparentHotspot({required VoidCallback? onTap, double radius = 12}) => Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius), splashColor: Colors.white10, highlightColor: Colors.white10),
      );

  Widget _targetImagePage({required String asset, required double aspectRatio, required Widget Function(double width, double height) overlays}) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          top: false,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = width / aspectRatio;
              return SingleChildScrollView(child: Center(child: SizedBox(width: width, height: height, child: Stack(fit: StackFit.expand, children: <Widget>[Image.asset(asset, fit: BoxFit.fill), overlays(width, height)]))));
            },
          ),
        ),
      );

  Widget vehiclePage() => Scaffold(
        backgroundColor: TKColors.bgPrimary,
        body: SafeArea(
          child: Column(
            children: [
              // 顶部栏：设置 | Tian Key | 帮助
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TKIconButton(icon: Icons.settings, color: TKColors.neonBlue, onTap: () => setState(() => tab = PageTab.settings)),
                    TKLogoText(),
                    TKIconButton(icon: Icons.help_outline, color: TKColors.textMuted, onTap: () => _message('帮助：长按按钮查看功能说明')),
                  ],
                ),
              ),

              // 汽车背景区域
              Expanded(
                flex: 5,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 背景图：home_car_bg.png
                    Image.asset(
                      'assets/home_car_bg.png',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                    ),
                    // 车牌号
                    Positioned(
                      bottom: 30,
                      child: TKLicensePlate(plate: '陕A·0P92Y'),
                    ),
                  ],
                ),
              ),

              // 5 个状态卡片
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    TKStatusCard(
                      icon: Icons.bluetooth,
                      title: '设备状态',
                      status: connected ? '已连接' : '未连接',
                      statusColor: connected ? TKColors.neonBlue : TKColors.textMuted,
                    ),
                    TKStatusCard(
                      icon: Icons.shield,
                      title: '管理员状态',
                      status: adminEnabled ? '已授权' : '未授权',
                      statusColor: adminEnabled ? TKColors.neonOrange : TKColors.textMuted,
                      iconColor: TKColors.neonOrange,
                    ),
                    TKStatusCard(
                      icon: Icons.bolt,
                      title: '供电状态',
                      status: '未知',
                      statusColor: TKColors.textMuted,
                      iconColor: TKColors.neonBlue,
                    ),
                    TKStatusCard(
                      icon: Icons.sync,
                      title: '时间同步',
                      status: timeSynced ? '已同步' : '未同步',
                      statusColor: timeSynced ? TKColors.neonBlue : TKColors.textMuted,
                      iconColor: TKColors.neonBlue,
                    ),
                    TKStatusCard(
                      icon: Icons.vpn_key,
                      title: '临时借车',
                      status: borrowValid ? '有效' : '无有效密码',
                      statusColor: borrowValid ? TKColors.neonBlue : TKColors.textMuted,
                      iconColor: TKColors.neonOrange,
                    ),
                  ],
                ),
              ),

              // 8 个功能按钮：2 列 4 行
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: TKNeonButton(label: '连接设备', icon: Icons.bluetooth, neonColor: TKColors.neonBlue, onTap: connected ? disconnect : connect, isEnabled: true)),
                        const SizedBox(width: 12),
                        Expanded(child: TKNeonButton(label: '管理员授权', icon: Icons.shield, neonColor: TKColors.neonOrange, onTap: adminEnabled ? toggleAuthorization : () => _message('请先完成管理员认证'), isEnabled: true)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TKNeonButton(label: '锁车', icon: Icons.lock, neonColor: TKColors.neonBlue, onTap: vehicleEnabled ? () => vehicleCommand('锁车') : null, isEnabled: vehicleEnabled)),
                        const SizedBox(width: 12),
                        Expanded(child: TKNeonButton(label: '解锁', icon: Icons.lock_open, neonColor: TKColors.neonBlue, onTap: vehicleEnabled ? () => vehicleCommand('解锁') : null, isEnabled: vehicleEnabled)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TKNeonButton(label: '车窗升', icon: Icons.keyboard_double_arrow_up, neonColor: TKColors.neonOrange, onTap: vehicleEnabled ? () => vehicleCommand('车窗升') : null, isEnabled: vehicleEnabled)),
                        const SizedBox(width: 12),
                        Expanded(child: TKNeonButton(label: '车窗降', icon: Icons.keyboard_double_arrow_down, neonColor: TKColors.neonOrange, onTap: vehicleEnabled ? () => vehicleCommand('车窗降') : null, isEnabled: vehicleEnabled)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TKNeonButton(label: '寻车', icon: Icons.wifi_tethering, neonColor: TKColors.neonBlue, onTap: vehicleEnabled ? () => vehicleCommand('寻车') : null, isEnabled: vehicleEnabled)),
                        const SizedBox(width: 12),
                        Expanded(child: TKNeonButton(label: '后备箱', icon: Icons.directions_car, neonColor: TKColors.neonBlue, onTap: vehicleEnabled ? () => vehicleCommand('后备箱') : null, isEnabled: vehicleEnabled)),
                      ],
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

  Widget _neonIconButton(IconData icon, {required Color color, required VoidCallback? onTap}) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, spreadRadius: 1),
          ],
        ),
        child: IconButton(
          icon: Icon(icon, color: color, size: 24),
          onPressed: onTap,
          splashColor: color.withOpacity(0.2),
        ),
      );

  Widget _buildStatusCard(IconData icon, String title, String status, Color statusColor) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF07111A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.blue, size: 24),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );

  Widget _buildNeonButton(String label, IconData icon, Color color, VoidCallback? onTap) => Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.6), width: 2),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, spreadRadius: 1),
            BoxShadow(color: color.withOpacity(0.2), blurRadius: 24, spreadRadius: 2),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: color.withOpacity(0.2),
            highlightColor: color.withOpacity(0.1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildBottomNav() => Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF02060D),
          border: Border(top: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, '首页', tab == PageTab.vehicle, () => setState(() => tab = PageTab.vehicle)),
            _buildNavItem(Icons.people, '临时借车', tab == PageTab.borrow, () => setState(() => tab = PageTab.borrow)),
            _buildNavItem(Icons.settings, '设置', tab == PageTab.settings, () => setState(() => tab = PageTab.settings)),
          ],
        ),
      );

  Widget _buildNavItem(IconData icon, String label, bool selected, VoidCallback onTap) => Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: selected ? Colors.blue : Colors.grey, size: 24),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.blue : Colors.grey,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
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
                    TKIconButton(icon: Icons.grid_view, color: TKColors.textMuted, onTap: () => _message('借车记录')),
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
                    // 8 个时间按钮：2 行 × 4 列
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildTimeSelectButton('5分钟', Duration(minutes: 5)),
                        _buildTimeSelectButton('1天', Duration(days: 1)),
                        _buildTimeSelectButton('2天', Duration(days: 2)),
                        _buildTimeSelectButton('3天', Duration(days: 3)),
                        _buildTimeSelectButton('4天', Duration(days: 4)),
                        _buildTimeSelectButton('5天', Duration(days: 5)),
                        _buildTimeSelectButton('6天', Duration(days: 6)),
                        _buildTimeSelectButton('7天', Duration(days: 7)),
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
                      const Icon(Icons.lock, color: TKColors.neonOrange, size: 48),
                      const SizedBox(height: 12),
                      const Text('尚未生成', style: TextStyle(color: TKColors.textSecondary, fontSize: 16)),
                      const SizedBox(height: 16),
                      // 复制密码按钮（未生成时禁用）
                      TKNeonButton(
                        label: '复制密码',
                        icon: Icons.content_copy,
                        neonColor: TKColors.neonBlue,
                        onTap: null,
                        isEnabled: false,
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
                        onTap: adminEnabled ? generateBorrowCode : () => _message('请先完成管理员认证'),
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
                        onTap: borrowValid ? _clearBorrow : null,
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
  Widget _buildTimeSelectButton(String label, Duration duration) {
    final int minutes = duration.inMinutes;
    final bool isSelected = hoursController.text == minutes.toString();

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 16 * 2 - 10 * 3) / 4,
      height: 56,
      child: TKNeonButton(
        label: label,
        icon: Icons.access_time,
        neonColor: TKColors.neonBlue,
        onTap: () {
          setState(() {
            hoursController.text = duration.inMinutes.toString();
          });
        },
        isEnabled: true,
        neonColor: hoursController.text == duration.inMinutes.toString() ? TKColors.neonBlue : TKColors.neonBlueDark,
      ),
    );
  }

  Future<void> _editBorrowHours() async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => TKDialog(
        borderColor: TKColors.neonOrange,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TKPageTitle(title: '临时借车有效期', fontSize: 20),
            const SizedBox(height: 16),
            TKTextField(
              controller: hoursController,
              label: '有效期',
              hint: '小时数 1-24',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: TKNeonButton(label: '取消', icon: Icons.cancel, neonColor: TKColors.textMuted, onTap: () => Navigator.pop(context), isEnabled: true, neonColor: TKColors.textMuted)),
                const SizedBox(width: 12),
                Expanded(child: TKNeonButton(label: '确定', icon: Icons.check, neonColor: TKColors.neonBlue, onTap: () => Navigator.pop(context, hoursController.text), isEnabled: true)),
              ],
            ),
          ],
        ),
      ),
    );
    if (value == null || !adminEnabled) return;
    hoursController.text = value;
    await generateBorrowCode();
  }

  Future<void> _connectAsBorrower() async {
    if (!borrowValid || connected) return;
    if (foundDevice == null) { await scan(); }
    if (foundDevice == null) return;
    passwordController.clear();
    final ok = await _verify(AccessMode.borrower);
    if (!ok) return;
    await _connectBle(foundDevice!, AccessMode.borrower);
    if (mounted && connected) setState(() => tab = PageTab.vehicle);
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
                    // 修改蓝牙密码
                    TKSettingTile(
                      title: '修改蓝牙密码',
                      leadingIcon: Icons.lock,
                      trailingText: '>',
                      onTap: adminEnabled ? changePassword : () => _message('请先完成管理员认证'),
                    ),
                    // 恢复默认蓝牙密码
                    TKSettingTile(
                      title: '恢复默认蓝牙密码',
                      leadingIcon: Icons.restore,
                      trailingText: '>',
                      onTap: adminEnabled ? () => _showFactoryResetDialog() : () => _message('请先完成管理员认证'),
                    ),
                    // 设备名称
                    TKSettingTile(
                      title: '设备名称',
                      leadingIcon: Icons.device_hub,
                      trailingText: deviceName,
                      onTap: adminEnabled ? changeDeviceName : () => _message('请先完成管理员认证'),
                    ),
                    // 时间同步设置
                    TKSettingTile(
                      title: '时间同步设置',
                      leadingIcon: Icons.access_time,
                      trailingText: '>',
                      onTap: adminEnabled ? () => _showTimeSyncDialog() : () => _message('请先完成管理员认证'),
                    ),
                    // 自动连接设置
                    TKSwitchTile(
                      title: '自动连接设置',
                      subtitle: '开启后，APP启动时将自动连接已配对设备',
                      value: autoConnect,
                      onChanged: _toggleAutoConnect,
                      leadingIcon: Icons.bluetooth_connected,
                    ),
                    // 提示音设置
                    TKSwitchTile(
                      title: '提示音设置',
                      subtitle: '开启后，操作时播放提示音',
                      value: sound,
                      onChanged: _toggleSound,
                      leadingIcon: Icons.volume_up,
                    ),
                    // 关于系统
                    TKSettingTile(
                      title: '关于系统',
                      leadingIcon: Icons.info_outline,
                      trailingText: '>',
                      onTap: () => _showAboutDialog(),
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

  Widget adminPage() => Scaffold(
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
                    const TKPageTitle(title: '管理员操作'),
                    Icon(connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled, color: connected ? TKColors.neonBlue : TKColors.textMuted, size: 28),
                  ],
                ),
              ),

              // 内容区
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    // 管理员权限状态卡
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: TKColors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: adminEnabled ? TKColors.neonOrange.withOpacity(0.5) : TKColors.borderSubtle, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.admin_panel_settings, color: adminEnabled ? TKColors.neonOrange : TKColors.textMuted, size: 24),
                              const SizedBox(width: 12),
                              Expanded(child: Text('管理员权限', style: const TextStyle(color: TKColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: adminEnabled ? TKColors.neonOrange.withOpacity(0.2) : TKColors.textMuted.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  adminEnabled ? '已开启' : '未认证',
                                  style: TextStyle(color: adminEnabled ? TKColors.neonOrange : TKColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(adminEnabled ? '管理员权限已开启：可修改设备保存信息。' : '请先通过管理员密码认证。', style: const TextStyle(color: TKColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 操作列表
                    _AdminActionTile(title: '修改管理员/蓝牙密码', icon: Icons.password, onTap: adminEnabled ? changePassword : () => _message('请先完成管理员认证')),
                    _AdminActionTile(title: '修改设备名称', icon: Icons.edit, onTap: adminEnabled ? changeDeviceName : () => _message('请先完成管理员认证')),
                    _AdminActionTile(title: '生成临时借车密码', icon: Icons.key, onTap: adminEnabled ? generateBorrowCode : () => _message('请先完成管理员认证')),
                    _AdminActionTile(title: authorized ? '关闭授权' : '恢复授权', icon: Icons.verified_user, onTap: adminEnabled ? toggleAuthorization : () => _message('请先完成管理员认证')),
                    _AdminActionTile(title: '重新同步时间', icon: Icons.sync, onTap: adminEnabled ? syncTime : () => _message('请先完成管理员认证')),
                    _AdminActionTile(title: '统一日志', icon: Icons.receipt_long, onTap: showLogs),
                    _AdminActionTile(title: '自动连接：${autoConnect ? '开启' : '关闭'}', icon: Icons.bluetooth, onTap: _toggleAutoConnect),
                    _AdminActionTile(title: '恢复出厂', icon: Icons.delete_forever, onTap: adminEnabled ? factoryReset : () => _message('请先完成管理员认证'), isDanger: true),
                    const SizedBox(height: 20),

                    // 关键状态卡
                    _buildAdminStatusCard(),
                    const SizedBox(height: 16),
                    _buildBoundaryCard(),
                  ],
                ),
              ),

              // 底部导航栏
              TKBottomNav(currentTab: tab, onTabChanged: (t) => setState(() => tab = t)),
            ],
          ),
        ),
      );

  Widget _buildAdminStatusCard() {
    final seatStatus = adminDevice == installId ? '当前安装' : adminDevice == null ? '未绑定' : '其他安装';
    final bleStatus = connected ? '已连接' : '未连接';
    final authorizationStatus = authorized ? '有效' : '关闭';
    final timeStatus = timeSynced ? '已同步' : '未同步';
    final vehicleStatus = locked ? '已锁定' : '已解锁';
    final borrowStatus = borrowValid ? '有效至 ${_formatTime(borrowEnd!)}' : '无有效授权';

    return Container(
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
          const Text('关键状态', style: TextStyle(color: TKColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildStatusRow('管理员席位', seatStatus, TKColors.neonOrange),
          _buildStatusRow('BLE', bleStatus, connected ? TKColors.neonBlue : TKColors.textMuted),
          _buildStatusRow('授权', authorizationStatus, authorized ? TKColors.neonBlue : TKColors.neonRed),
          _buildStatusRow('时间', timeStatus, timeSynced ? TKColors.neonBlue : TKColors.neonOrange),
          _buildStatusRow('车辆', vehicleStatus, locked ? TKColors.neonRed : TKColors.neonBlue),
          _buildStatusRow('临时借车', borrowStatus, borrowValid ? TKColors.neonBlue : TKColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: TKColors.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBoundaryCard() {
    return Container(
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
          const Text('当前实现边界', style: TextStyle(color: TKColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('真实 BLE 扫描、连接、断开已接入；车辆指令帧、ESP32 时间写入、密码持久化、设备名写入仍未接入，等待既有硬件协议/固件代码。', style: TextStyle(color: TKColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  void _requireAdmin() => _message('请先连接车辆并使用管理员密码：$defaultPassword');

  // 设置页子弹窗
  void _showFactoryResetDialog() => showDialog(
        context: context,
        builder: (context) => TKDialog(
          borderColor: TKColors.neonRed,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TKPageTitle(title: '恢复默认蓝牙密码'),
              const SizedBox(height: 16),
              const Icon(Icons.restart_alt, color: TKColors.neonRed, size: 48),
              const SizedBox(height: 16),
              const Text('恢复后蓝牙密码将重置为出厂默认密码 13092991951', style: TextStyle(color: TKColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: TKNeonButton(label: '取消', icon: Icons.cancel, neonColor: TKColors.textMuted, onTap: () => Navigator.pop(context), isEnabled: true, neonColor: TKColors.textMuted)),
                  const SizedBox(width: 12),
                  Expanded(child: TKNeonButton(label: '恢复默认蓝牙密码', icon: Icons.restore, neonColor: TKColors.neonRed, onTap: () { Navigator.pop(context); factoryReset(); }, isEnabled: true)),
                ],
              ),
            ],
          ),
        ),
      );
  }

  void _showTimeSyncDialog() => showDialog(
        context: context,
        builder: (context) => TKDialog(
          borderColor: TKColors.neonBlue,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TKPageTitle(title: '时间同步设置'),
              const SizedBox(height: 16),
              TKBigIcon(icon: Icons.access_time, color: TKColors.neonBlue, size: 80),
              const SizedBox(height: 16),
              Text('当前状态', style: const TextStyle(color: TKColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 4),
              Text(timeSynced ? '已同步' : '未同步', style: TextStyle(color: timeSynced ? TKColors.neonBlue : TKColors.neonOrange, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TKNeonButton(label: '立即同步', icon: Icons.sync, neonColor: TKColors.neonBlue, onTap: syncTime, isEnabled: connected),
              const SizedBox(height: 12),
              const Text('点击按钮将手机时间同步至车辆 ESP32', style: TextStyle(color: TKColors.textMuted, fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
  }

  void _showAboutDialog() => showDialog(
        context: context,
        builder: (context) => TKDialog(
          borderColor: TKColors.neonBlue,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TKBigIcon(icon: Icons.directions_car_filled, color: TKColors.neonBlue, size: 100),
              const SizedBox(height: 16),
              const TKLogoText(text: 'Tian Key V11', fontSize: 28),
              const SizedBox(height: 8),
              const Text('马自达昂克赛拉 个人 BLE 手机车钥匙系统', style: TextStyle(color: TKColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              const Divider(color: TKColors.divider),
              const SizedBox(height: 16),
              const Text('版本 1.0.0+1', style: TextStyle(color: TKColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              const Text('© 2026 Tian Key Team', style: TextStyle(color: TKColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      );
  }

  void _showAdminAuthDialog() => showDialog(
        context: context,
        builder: (context) => TKDialog(
          borderColor: TKColors.neonOrange,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TKPageTitle(title: '管理员授权'),
              const SizedBox(height: 16),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: TKColors.neonOrange.withOpacity(0.4), blurRadius: 20, spreadRadius: 3)],
                ),
                child: const Icon(Icons.shield, color: TKColors.neonOrange, size: 60),
              ),
              const SizedBox(height: 16),
              const Text('请输入管理员密码进行授权', style: TextStyle(color: TKColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TKTextField(controller: passwordController, label: '管理员密码', hint: '请输入管理员密码', obscureText: true, keyboardType: TextInputType.number, showToggle: true),
              const SizedBox(height: 20),
              TKNeonButton(label: '确认授权', icon: Icons.verified_user, neonColor: TKColors.neonOrange, onTap: () {
                final value = passwordController.text.trim();
                if (value == adminPassword) {
                  Navigator.pop(context);
                  setState(() => adminSession = true);
                  _message('管理员授权成功');
                } else {
                  _message('密码错误');
                }
              }, isEnabled: true),
              const SizedBox(height: 12),
              const Text('授权后可使用全部控制功能', style: TextStyle(color: TKColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      );
  }

  // 管理员操作列表项
  Widget _AdminActionTile({
    required String title,
    required IconData icon,
    required VoidCallback? onTap,
    bool isDanger = false,
  }) {
    final Color accentColor = isDanger ? TKColors.neonRed : TKColors.neonBlue;
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
                Icon(icon, color: isDanger ? TKColors.neonRed : TKColors.neonBlue, size: 24),
                const SizedBox(width: 14),
                Expanded(child: Text(title, style: const TextStyle(color: TKColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500))),
                const Icon(Icons.chevron_right, color: TKColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      );
  }

  Widget _adminCard(String title, String body) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xCC020A14), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1595FF))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), const SizedBox(height: 7), Text(body, style: const TextStyle(color: Colors.white70))]));

  Widget _adminAction(String title, IconData icon, VoidCallback onTap, {bool danger = false}) { final color = danger ? const Color(0xFFFF2B1A) : const Color(0xFF19D36B); return Container(margin: const EdgeInsets.only(bottom: 9), decoration: BoxDecoration(color: const Color(0xFF09111B), borderRadius: BorderRadius.circular(15), border: Border.all(color: color)), child: ListTile(onTap: onTap, leading: Icon(icon, color: color), title: Text(title), trailing: const Icon(Icons.chevron_right))); }

  Future<void> showLogs() async => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: TKColors.bgPrimary,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: TKColors.textMuted, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const TKPageTitle(title: 'Tian Key 系统日志'),
          const Text('APP + BLE日志 · ≤200条 · 7天自动清理', style: TextStyle(color: TKColors.textSecondary, fontSize: 12)),
          const Divider(color: TKColors.divider, height: 24),
          Expanded(
            child: logs.isEmpty
                ? const TKEmptyState(message: '暂无日志', icon: Icons.article_outlined)
                : ListView.builder(
                    itemCount: logs.length,
                    reverse: true,
                    itemBuilder: (context, index) {
                      final log = logs[logs.length - 1 - index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(log, style: const TextStyle(color: TKColors.textPrimary, fontSize: 12, fontFamily: 'monospace')),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );

  String _formatTime(DateTime value) { String two(int v) => v.toString().padLeft(2, '0'); return '${value.month}/${value.day} ${two(value.hour)}:${two(value.minute)}'; }

  @override
  Widget build(BuildContext context) {
    if (!ready) return const Scaffold(backgroundColor: Color(0xFF02060D), body: Center(child: CircularProgressIndicator()));
    switch (tab) {
      case PageTab.vehicle: return vehiclePage();
      case PageTab.borrow: return borrowPage();
      case PageTab.settings: return settingsPage();
      case PageTab.admin: return adminPage();
    }
  }
}
