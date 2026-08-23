import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          _NavItem(icon: Icons.admin_panel_settings, label: '管理员', selected: currentTab == PageTab.admin, onTap: () => onTabChanged(PageTab.admin)),
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

enum PageTab { vehicle, borrow, settings, admin }
enum AccessMode { admin, borrower }

// ==================== 模拟ESP32逻辑层 ====================
class SimulatedEsp32 {
  final void Function(String)? onLog;
  String adminPassword = '13092991951';
  String? adminDevice;
  String? borrowCode;
  DateTime? borrowStart;
  DateTime? borrowEnd;
  String deviceName = '陕A0P92Y';
  bool timeSynced = false;
  DateTime? espTime;
  bool autoLockEnabled = true;

  SimulatedEsp32({this.onLog});

  void _logEsp32(String msg) {
    onLog?.call('[ESP32] $msg');
  }

  bool verifyAdminPassword(String password, String deviceId) {
    _logEsp32('收到管理员认证请求');
    if (password != adminPassword) {
      _logEsp32('管理员密码验证失败');
      return false;
    }
    adminDevice = deviceId;
    _logEsp32('管理员密码验证通过，设备：$deviceId');
    return true;
  }

  bool verifyBorrowPassword(String password) {
    _logEsp32('收到临时借车认证请求');
    if (borrowCode == null || password != borrowCode) {
      _logEsp32('临时密码验证失败');
      return false;
    }
    if (borrowEnd != null && DateTime.now().isAfter(borrowEnd!)) {
      _logEsp32('临时密码已过期');
      return false;
    }
    _logEsp32('临时密码验证通过');
    return true;
  }

  bool isCurrentAdmin(String deviceId) {
    final result = adminDevice == deviceId;
    _logEsp32('检查管理员席位：${result ? "是当前管理员" : "不是当前管理员"}');
    return result;
  }

  bool syncTime(DateTime phoneTime) {
    espTime = phoneTime;
    timeSynced = true;
    _logEsp32('时间同步成功：$phoneTime');
    return true;
  }

  String executeCommand(String command) {
    String detail;
    switch (command) {
      case 'suoche':
        detail = 'GPIO12 锁车脉冲';
        _logEsp32('收到suoche，GPIO12 执行脉冲');
      case 'jiesuo':
        detail = 'GPIO13 解锁脉冲';
        _logEsp32('收到jiesuo，GPIO13 执行脉冲');
      case 'xunche':
        detail = 'GPIO12 连续两次锁车脉冲';
        _logEsp32('收到xunche，GPIO12 连续两次脉冲');
      case 'chuangsheng':
        detail = 'GPIO12 保持7秒';
        _logEsp32('收到chuangsheng，GPIO12 保持7秒');
      case 'chuangjiang':
        detail = 'GPIO13 保持7秒';
        _logEsp32('收到chuangjiang，GPIO13 保持7秒');
      case 'houbeixiang':
        detail = 'GPIO14 保持7秒';
        _logEsp32('收到houbeixiang，GPIO14 保持7秒');
      default:
        detail = '未知命令';
        _logEsp32('收到未知命令：$command');
    }
    return detail;
  }

  String generateBorrowCode(int hours) {
    final code = (100000 + Random().nextInt(900000)).toString();
    borrowCode = code;
    borrowStart = DateTime.now();
    borrowEnd = DateTime.now().add(Duration(hours: hours));
    _logEsp32('生成临时借车密码：$code，有效期 $hours 小时');
    return code;
  }

  bool changePassword(String newPassword) {
    adminPassword = newPassword;
    _logEsp32('密码已更新');
    return true;
  }

  bool resetPassword() {
    adminPassword = '13092991951';
    _logEsp32('密码已恢复默认');
    return true;
  }

  bool changeDeviceName(String name) {
    deviceName = name;
    _logEsp32('设备名称已更新：$name');
    return true;
  }

  void factoryReset() {
    adminPassword = '13092991951';
    adminDevice = null;
    borrowCode = null;
    borrowStart = null;
    borrowEnd = null;
    deviceName = '陕A0P92Y';
    timeSynced = false;
    espTime = null;
    _logEsp32('恢复出厂：所有设置已清除');
  }

  void disconnect() {
    timeSynced = false;
    espTime = null;
    _logEsp32('BLE连接断开，执行安全保护');
    if (autoLockEnabled) {
      _logEsp32('自动落锁：已执行');
    }
  }
}

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
  late final SimulatedEsp32 esp32 = SimulatedEsp32(onLog: _log);
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
  bool simulationMode = true;
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
  bool splashDone = false;

  bool get borrowValid {
    if (borrowCode == null || borrowStart == null || borrowEnd == null) return false;
    final now = DateTime.now();
    return !now.isBefore(borrowStart!) && now.isBefore(borrowEnd!);
  }

  bool get adminEnabled => adminSession;

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
    authorized = p.getBool('authorized') ?? false;
    autoConnect = p.getBool('auto_connect') ?? true;
    sound = p.getBool('sound') ?? true;
    simulationMode = p.getBool('simulation_mode') ?? true;
    timeFail = p.getBool('time_fail') ?? false;
    esp32.autoLockEnabled = p.getBool('auto_lock') ?? true;

    esp32.adminPassword = adminPassword;
    esp32.adminDevice = adminDevice;
    esp32.deviceName = deviceName;
    esp32.borrowCode = borrowCode;
    esp32.borrowStart = borrowStart;
    esp32.borrowEnd = borrowEnd;

    ready = true;
    _cleanupOldLogs();
    _log('[APP] 启动');
    _scheduleBorrowExpiry();
    if (borrowEnd != null && !DateTime.now().isBefore(borrowEnd!)) {
      await _clearBorrow(logExpiry: true);
    }

    if (mounted) setState(() {});
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => splashDone = true);

    if (simulationMode && autoConnect && adminDevice != null && adminDevice == installId) {
      _log('[APP] 自动连接：检测到已授权管理员设备');
      await _autoConnectSimulation();
    }

    if (mounted) setState(() {});
  }

  Future<void> _autoConnectSimulation() async {
    if (!simulationMode || connected || connecting) return;
    setState(() {
      connecting = true;
      status = '正在自动连接...';
    });
    _log('[APP] 自动连接开始');
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final simDevice = BleScanItem(name: esp32.deviceName, remoteId: 'SIM-ESP32-TIANKY');
    foundDevice = simDevice;
    savedRemoteId = simDevice.remoteId;
    adminSession = true;
    mode = AccessMode.admin;
    await prefs?.setBool('authorized', true);
    authorized = true;
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _log('[ESP32] 管理员授权验证通过');
    setState(() {
      connected = true;
      connecting = false;
      timeSynced = false;
      status = '自动连接成功，正在同步时间...';
    });
    _log('[APP] BLE自动连接成功');
    await syncTime();
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
      status = simulationMode ? '模拟扫描中...' : '正在扫描 BLE 设备...';
    });
    _log('[APP] ${simulationMode ? "模拟扫描开始" : "BLE真实扫描开始"}');
    try {
      if (simulationMode) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        final simDevice = BleScanItem(name: '陕A0P92Y', remoteId: 'SIM-ESP32-TIANKY');
        foundDevice = simDevice;
        savedRemoteId = simDevice.remoteId;
        setState(() => status = '发现设备：${simDevice.name}');
        _log('[APP] 模拟发现设备：${simDevice.name} / ${simDevice.remoteId}');
        _message('发现 ${simDevice.name}');
      } else {
        if (!await ble.isSupported()) {
          throw StateError('当前手机不支持 BLE');
        }
        final devices = await ble.scan();
        if (!mounted) return;
        if (devices.isEmpty) {
          setState(() => status = 'BLE扫描结束：未发现设备');
          _log('[APP] BLE扫描结束：未发现设备');
          _message('未发现 BLE 设备，请确认 ESP32 正在广播');
          return;
        }
        final selected = devices.length == 1 ? devices.first : await _chooseBleDevice(devices);
        if (selected == null || !mounted) return;
        foundDevice = selected;
        savedRemoteId = selected.remoteId;
        await prefs?.setString('ble_remote_id', selected.remoteId);
        setState(() => status = '发现设备：${selected.name}');
        _log('[APP] 发现 BLE：${selected.name} / ${selected.remoteId}');
        _message('发现 ${selected.name}');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => status = '${simulationMode ? "模拟" : "BLE"}扫描失败：$error');
      _log('[APP] 扫描失败：$error');
      _message('扫描失败：$error');
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
      _log('[APP] 管理员席位拒绝：${adminDevice!}');
      return;
    }
    setState(() {
      connecting = true;
      status = simulationMode ? '模拟连接中...' : '认证成功，正在建立真实 BLE 连接...';
    });
    _log('[APP] 开始建立${simulationMode ? "模拟" : "真实"}BLE连接');
    try {
      if (!simulationMode) {
        if (target.device == null) throw StateError('BLE设备对象无效');
        await ble.connect(target.device!);
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        _log('[ESP32] BLE连接建立');
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
      setState(() {
        connected = true;
        connecting = false;
        mode = selected;
        timeSynced = false;
        status = simulationMode ? '连接成功，正在同步时间...' : 'BLE真实连接成功，正在同步时间...';
      });
      _log('[APP] ${simulationMode ? "模拟" : "BLE真实"}连接成功：${target.name}');
      await syncTime();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        connecting = false;
        connected = false;
        status = '连接失败：$error';
      });
      _log('[APP] 连接失败：$error');
      _message('连接失败：$error');
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
                bool ok;
                if (selected == AccessMode.admin) {
                  final seatBlocked = adminDevice != null && adminDevice != installId && adminDevice != legacyPhoneId;
                  if (seatBlocked) {
                    _log('[ESP32] 管理员席位已被占用：$adminDevice');
                    _message('管理员席位已被其他设备占用');
                    return;
                  }
                  ok = esp32.verifyAdminPassword(value, installId ?? '');
                  if (ok) {
                    _log('[ESP32] 管理员密码验证通过');
                    Navigator.pop(context, true);
                  } else {
                    _log('[ESP32] 管理员密码验证失败');
                    _message('密码错误');
                  }
                } else {
                  ok = esp32.verifyBorrowPassword(value);
                  if (ok) {
                    _log('[ESP32] 临时密码验证通过');
                    Navigator.pop(context, true);
                  } else {
                    _log('[ESP32] 临时密码验证失败');
                    _message('密码错误或临时密码已过期');
                  }
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
    _log('[APP] 自动同步时间...');
    _log('[ESP32] 收到时间同步请求');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    if (timeFail) {
      setState(() {
        timeSynced = false;
        espTime = null;
        status = mode == AccessMode.admin ? '时间同步失败：管理员仍可使用' : '时间同步失败：无法确认临时授权有效期';
      });
      _log('[ESP32] 时间同步失败');
      _log('[APP] 时间同步失败');
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
    _log('[ESP32] 时间同步成功：$espTime');
    _log('[APP] 时间同步成功');
  }

  Future<void> disconnect() async {
    commandTimer?.cancel();
    if (!simulationMode) {
      await ble.disconnect();
    } else {
      esp32.disconnect();
    }
    if (!mounted) return;
    setState(() {
      connected = false;
      mode = null;
      adminSession = false;
      timeSynced = false;
      espTime = null;
      commandSeconds = 0;
      activeCommand = '';
      status = '已断开：车辆功能重新锁定';
    });
    _log('[APP] 已断开连接');
    _log('[ESP32] BLE连接断开，执行安全保护');
    _message('已断开，车辆功能已锁定');
  }

  void vehicleCommand(String command) {
    if (!vehicleEnabled) {
      _message('当前没有车辆控制权限');
      _log('[APP] 拒绝车辆指令 $command');
      return;
    }
    late final String protocol;
    late final String detail;
    late final int gpio;
    final timed = command == '车窗升' || command == '车窗降' || command == '后备箱';
    switch (command) {
      case '锁车':
        protocol = 'suoche'; gpio = 12; detail = 'GPIO12 锁车脉冲'; locked = true;
      case '解锁':
        protocol = 'jiesuo'; gpio = 13; detail = 'GPIO13 解锁脉冲'; locked = false;
      case '寻车':
        protocol = 'xunche'; gpio = 12; detail = 'GPIO12 连续两次锁车脉冲';
      case '车窗升':
        protocol = 'chuangsheng'; gpio = 12; detail = 'GPIO12 保持7秒';
      case '车窗降':
        protocol = 'chuangjiang'; gpio = 13; detail = 'GPIO13 保持7秒';
      default:
        protocol = 'houbeixiang'; gpio = 14; detail = 'GPIO14 保持7秒';
    }
    _log('[APP] 发送指令：$protocol');
    final espDetail = esp32.executeCommand(protocol);
    _log('[ESP32] $espDetail');
    commandTimer?.cancel();
    if (timed) {
      commandSeconds = 7;
      activeCommand = command;
      commandTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) { timer.cancel(); return; }
        if (commandSeconds <= 1) {
          timer.cancel();
          setState(() { commandSeconds = 0; activeCommand = ''; status = '✅ $command 完成：$espDetail'; });
          _log('[ESP32] $protocol 执行成功');
          _message('$command\n✅ 执行成功');
          return;
        }
        setState(() => commandSeconds -= 1);
      });
    } else {
      _log('[ESP32] $protocol 执行成功');
    }
    lastCommand = '$protocol → GPIO$gpio → $detail';
    setState(() => status = timed ? '⏳ $command 7秒保持中（$commandSeconds）' : '✅ $command 成功：$lastCommand');
    _message(timed ? '$command\n⏳ 7秒保持中' : '$command\n✅ 执行成功\n$detail');
  }

  Future<void> generateBorrowCode() async {
    if (!adminEnabled) { _message('请先完成管理员认证'); return; }
    final hours = (int.tryParse(hoursController.text.trim()) ?? 2).clamp(1, 24).toInt();
    _log('[APP] 生成临时借车密码，有效期 $hours 小时');
    final code = esp32.generateBorrowCode(hours);
    borrowCode = esp32.borrowCode;
    borrowStart = esp32.borrowStart;
    borrowEnd = esp32.borrowEnd;
    await prefs?.setString('borrow_code', code);
    await prefs?.setInt('borrow_start', borrowStart!.millisecondsSinceEpoch);
    await prefs?.setInt('borrow_end', borrowEnd!.millisecondsSinceEpoch);
    _scheduleBorrowExpiry();
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
    if (logExpiry && hadCode) _log('[APP] 临时借车密码已到期并清除');
    if (mounted) {
      if (mode == AccessMode.borrower) {
        if (!simulationMode) {
          await ble.disconnect();
        } else {
          esp32.disconnect();
        }
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
    _log(authorized ? '[APP] 恢复设备授权' : '[APP] 关闭设备授权');
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
                Expanded(child: TKNeonButton(label: '取消', icon: Icons.cancel, neonColor: TKColors.textMuted, onTap: () => Navigator.pop(context), isEnabled: true)),
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
    esp32.changePassword(value);
    await prefs?.setString('admin_password', value);
    _log('[APP] 管理员密码已保存');
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
                Expanded(child: TKNeonButton(label: '取消', icon: Icons.cancel, neonColor: TKColors.textMuted, onTap: () => Navigator.pop(context), isEnabled: true)),
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
    esp32.changeDeviceName(value);
    await prefs?.setString('device_name', value);
    _log('[APP] 设备名称已保存');
    setState(() {});
    _message('设备名称已更新');
  }

  Future<void> factoryReset() async {
    if (!adminEnabled) { _message('请先完成管理员认证'); return; }
    final ctrl = TextEditingController();
    final passOk = await showDialog<bool>(
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
    if (passOk != true) { _message('密码错误或已取消'); return; }
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
                Expanded(child: TKNeonButton(label: '取消', icon: Icons.cancel, neonColor: TKColors.textMuted, onTap: () => Navigator.pop(context), isEnabled: true)),
                const SizedBox(width: 12),
                Expanded(child: TKNeonButton(label: '确认恢复出厂', icon: Icons.delete_forever, neonColor: TKColors.neonRed, onTap: () => Navigator.pop(context, true), isEnabled: true)),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (!simulationMode) {
      await ble.disconnect();
    }
    esp32.factoryReset();
    await prefs?.clear();
    adminPassword = defaultPassword;
    adminDevice = null; savedRemoteId = null; authorized = true; autoConnect = true; sound = true; simulationMode = true;
    deviceName = defaultName; borrowCode = null; borrowStart = null; borrowEnd = null;
    connected = false; foundDevice = null; mode = null; adminSession = false; timeSynced = false;
    final newId = 'TK-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1000000)}';
    installId = newId;
    await prefs?.setString('install_id', newId);
    _log('[APP] 恢复出厂');
    if (mounted) setState(() { status = '已恢复未绑定初始状态'; tab = PageTab.vehicle; });
    _message('恢复出厂完成，管理员初始密码恢复为13092991951');
  }

  void _toggleAutoConnect(bool _) async { autoConnect = !autoConnect; await prefs?.setBool('auto_connect', autoConnect); _log(autoConnect ? '[APP] 自动连接开启' : '[APP] 自动连接关闭'); setState(() {}); }

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
                        Expanded(child: TKNeonButton(label: '连接设备', icon: Icons.bluetooth, neonColor: TKColors.neonBlue, onTap: connected ? () => disconnect() : () => connect(), isEnabled: true)),
                        const SizedBox(width: 12),
                        Expanded(child: TKNeonButton(label: '管理员授权', icon: Icons.shield, neonColor: TKColors.neonOrange, onTap: adminEnabled ? () => toggleAuthorization() : () => _showAdminAuthDialog(), isEnabled: true)),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TKNeonButton(label: '管理员', icon: Icons.admin_panel_settings, neonColor: TKColors.neonOrange, onTap: () => setState(() => tab = PageTab.admin), isEnabled: true)),
                        const SizedBox(width: 12),
                        Expanded(child: TKNeonButton(label: '系统日志', icon: Icons.receipt_long, neonColor: TKColors.neonBlue, onTap: () => showLogs(), isEnabled: true)),
                      ],
                    ),
                  ],
                ),
              ),

              // ESP32模拟状态
              if (simulationMode)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TKColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: TKColors.neonBlue.withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.science, color: TKColors.neonBlue, size: 16),
                          const SizedBox(width: 8),
                          const Text('模拟ESP32', style: TextStyle(color: TKColors.neonBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text(lastCommand.isEmpty ? '待机' : lastCommand, style: const TextStyle(color: TKColors.textSecondary, fontSize: 11)),
                        ]),
                      ],
                    ),
                  ),
                ),

              // 底部导航栏
              TKBottomNav(currentTab: tab, onTabChanged: (t) => setState(() => tab = t)),
            ],
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
                      if (borrowValid && borrowCode != null) ...[
                        const SizedBox(height: 12),
                        TKNeonButton(
                          label: '复制密码',
                          icon: Icons.content_copy,
                          neonColor: TKColors.neonBlue,
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: borrowCode!));
                            _message('密码已复制到剪贴板');
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
                        _buildTimeSelectButton('1小时', 1),
                        _buildTimeSelectButton('2小时', 2),
                        _buildTimeSelectButton('4小时', 4),
                        _buildTimeSelectButton('8小时', 8),
                        _buildTimeSelectButton('12小时', 12),
                        _buildTimeSelectButton('16小时', 16),
                        _buildTimeSelectButton('20小时', 20),
                        _buildTimeSelectButton('24小时', 24),
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
                        onTap: adminEnabled ? () => generateBorrowCode() : () => _message('请先完成管理员认证'),
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
                      title: '修改蓝牙密码',
                      leadingIcon: Icons.lock,
                      trailingText: '>',
                      onTap: adminEnabled ? () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => Builder(builder: (_) => _changePasswordPage(ctx)))) : () => _showAdminAuthDialog(),
                    ),
                    TKSettingTile(
                      title: '修改管理员密码',
                      leadingIcon: Icons.admin_panel_settings,
                      trailingText: '>',
                      onTap: adminEnabled ? () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => Builder(builder: (_) => _changeAdminPasswordPage(ctx)))) : () => _showAdminAuthDialog(),
                    ),
                    TKSettingTile(
                      title: '恢复默认蓝牙密码',
                      leadingIcon: Icons.restore,
                      trailingText: '>',
                      onTap: adminEnabled ? () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => Builder(builder: (_) => _resetPasswordPage(ctx)))) : () => _showAdminAuthDialog(),
                    ),
                    TKSettingTile(
                      title: '设备名称',
                      leadingIcon: Icons.device_hub,
                      trailingText: deviceName,
                      onTap: adminEnabled ? () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => Builder(builder: (_) => _deviceNamePage(ctx)))) : () => _showAdminAuthDialog(),
                    ),
                    TKSettingTile(
                      title: '时间同步设置',
                      leadingIcon: Icons.access_time,
                      trailingText: '>',
                      onTap: adminEnabled ? () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => Builder(builder: (_) => _timeSyncPage(ctx)))) : () => _showAdminAuthDialog(),
                    ),
                    TKSettingTile(
                      title: '自动连接设置',
                      leadingIcon: Icons.bluetooth_connected,
                      trailingText: autoConnect ? '已开启' : '已关闭',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => Builder(builder: (_) => _autoConnectPage(ctx)))),
                    ),
                    TKSettingTile(
                      title: '提示音设置',
                      leadingIcon: Icons.volume_up,
                      trailingText: sound ? '已开启' : '已关闭',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => Builder(builder: (_) => _soundPage(ctx)))),
                    ),
                    TKSettingTile(
                      title: '模拟模式',
                      leadingIcon: Icons.science,
                      trailingText: simulationMode ? '已开启' : '已关闭',
                      onTap: () {
                        setState(() => simulationMode = !simulationMode);
                        prefs?.setBool('simulation_mode', simulationMode);
                        _message('模拟模式已${simulationMode ? "开启" : "关闭"}');
                      },
                    ),
                    TKSettingTile(
                      title: '自动落锁',
                      leadingIcon: Icons.lock_outline,
                      trailingText: esp32.autoLockEnabled ? '已开启' : '已关闭',
                      onTap: adminEnabled ? () {
                        setState(() => esp32.autoLockEnabled = !esp32.autoLockEnabled);
                        prefs?.setBool('auto_lock', esp32.autoLockEnabled);
                        _message('自动落锁已${esp32.autoLockEnabled ? "开启" : "关闭"}');
                      } : () => _showAdminAuthDialog(),
                    ),
                    TKSettingTile(
                      title: '恢复出厂',
                      leadingIcon: Icons.delete_forever,
                      trailingText: '>',
                      onTap: adminEnabled ? () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => Builder(builder: (_) => _factoryResetPage(ctx)))) : () => _showAdminAuthDialog(),
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
                    _AdminActionTile(title: '修改管理员/蓝牙密码', icon: Icons.password, onTap: adminEnabled ? () => changePassword() : () => _message('请先完成管理员认证')),
                    _AdminActionTile(title: '修改设备名称', icon: Icons.edit, onTap: adminEnabled ? () => changeDeviceName() : () => _message('请先完成管理员认证')),
                    _AdminActionTile(title: '生成临时借车密码', icon: Icons.key, onTap: adminEnabled ? () => generateBorrowCode() : () => _message('请先完成管理员认证')),
                    _AdminActionTile(title: authorized ? '关闭授权' : '恢复授权', icon: Icons.verified_user, onTap: adminEnabled ? () => toggleAuthorization() : () => _message('请先完成管理员认证')),
                    _AdminActionTile(title: '重新同步时间', icon: Icons.sync, onTap: adminEnabled ? () => syncTime() : () => _message('请先完成管理员认证')),
                    _AdminActionTile(title: '统一日志', icon: Icons.receipt_long, onTap: () => showLogs()),
                    _AdminActionTile(title: '自动连接：${autoConnect ? '开启' : '关闭'}', icon: Icons.bluetooth, onTap: () { _toggleAutoConnect(autoConnect); }),
                    _AdminActionTile(title: '恢复出厂', icon: Icons.delete_forever, onTap: adminEnabled ? () => factoryReset() : () => _message('请先完成管理员认证'), isDanger: true),
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

  // ==================== 管理员授权弹窗 ====================
  void _showAdminAuthDialog() {
    final ctrl = TextEditingController();
    bool obscure = true;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => TKDialog(
          borderColor: TKColors.neonOrange,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: TKColors.neonOrange.withOpacity(0.4), blurRadius: 20, spreadRadius: 3)],
                ),
                child: const Icon(Icons.shield, color: TKColors.neonOrange, size: 60),
              ),
              const SizedBox(height: 16),
              const Text('请输入管理员密码进行授权', style: TextStyle(color: TKColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                obscureText: obscure,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: TKColors.textPrimary, fontSize: 18),
                decoration: InputDecoration(
                  hintText: '请输入管理员密码',
                  hintStyle: const TextStyle(color: TKColors.textMuted),
                  filled: true, fillColor: TKColors.bgCard,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TKColors.borderSubtle, width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TKColors.neonOrange, width: 2)),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: TKColors.textSecondary, size: 20),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TKNeonButton(label: '确认授权', icon: Icons.verified_user, neonColor: TKColors.neonOrange, onTap: () {
                if (ctrl.text.trim() == adminPassword) {
                  Navigator.pop(context);
                  setState(() { adminSession = true; adminDevice = installId; });
                  prefs?.setString('admin_device_id', installId!);
                  _log('[APP] 管理员认证成功');
                  _message('管理员授权成功');
                } else {
                  _log('[APP] 管理员认证失败：密码错误');
                  _message('密码错误');
                }
              }, isEnabled: true),
              const SizedBox(height: 12),
              const Text('授权后可使用全部管理功能', style: TextStyle(color: TKColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 设置二级子页面 ====================

  // 1. 修改蓝牙密码
  Widget _changePasswordPage(BuildContext pageCtx) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    return Scaffold(
      backgroundColor: TKColors.bgPrimary,
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TKIconButton(icon: Icons.arrow_back, color: TKColors.neonBlue, onTap: () => Navigator.pop(pageCtx)),
          const TKPageTitle(title: '修改蓝牙密码'),
          const SizedBox(width: 48),
        ])),
        Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          const SizedBox(height: 24),
          TKBigIcon(icon: Icons.lock_reset, color: TKColors.neonBlue, size: 80),
          const SizedBox(height: 24),
          TKTextField(controller: currentCtrl, label: '当前蓝牙密码', hint: '请输入当前蓝牙密码', obscureText: true, keyboardType: TextInputType.number, showToggle: true),
          const SizedBox(height: 16),
          TKTextField(controller: newCtrl, label: '新蓝牙密码', hint: '请输入新蓝牙密码', obscureText: true, keyboardType: TextInputType.number, showToggle: true),
          const SizedBox(height: 16),
          TKTextField(controller: confirmCtrl, label: '确认新密码', hint: '请再次输入新密码', obscureText: true, keyboardType: TextInputType.number, showToggle: true),
          const SizedBox(height: 32),
          TKNeonButton(label: '保存新密码', icon: Icons.check, neonColor: TKColors.neonBlue, onTap: () {
            if (currentCtrl.text.trim() != adminPassword) { _message('当前密码错误'); return; }
            if (newCtrl.text.trim().length < 6) { _message('新密码至少6位'); return; }
            if (newCtrl.text.trim() != confirmCtrl.text.trim()) { _message('两次输入不一致'); return; }
            adminPassword = newCtrl.text.trim();
            esp32.changePassword(adminPassword);
            prefs?.setString('admin_password', adminPassword);
            _log('[ESP32] 蓝牙密码已更新'); _log('[APP] 管理员密码已修改'); _message('密码已更新'); Navigator.pop(pageCtx);
          }, isEnabled: true),
        ])),
      ])),
    );
  }

  Widget _changeAdminPasswordPage(BuildContext pageCtx) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    return Scaffold(
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
          TKTextField(controller: currentCtrl, label: '当前管理员密码', hint: '请输入当前管理员密码', obscureText: true, keyboardType: TextInputType.number, showToggle: true),
          const SizedBox(height: 16),
          TKTextField(controller: newCtrl, label: '新管理员密码', hint: '请输入新管理员密码', obscureText: true, keyboardType: TextInputType.number, showToggle: true),
          const SizedBox(height: 16),
          TKTextField(controller: confirmCtrl, label: '确认新密码', hint: '请再次输入新密码', obscureText: true, keyboardType: TextInputType.number, showToggle: true),
          const SizedBox(height: 32),
          TKNeonButton(label: '保存新密码', icon: Icons.check, neonColor: TKColors.neonOrange, onTap: () {
            if (currentCtrl.text.trim() != adminPassword) { _message('当前密码错误'); return; }
            if (newCtrl.text.trim().length < 6) { _message('新密码至少6位'); return; }
            if (newCtrl.text.trim() != confirmCtrl.text.trim()) { _message('两次输入不一致'); return; }
            adminPassword = newCtrl.text.trim();
            esp32.changePassword(adminPassword);
            prefs?.setString('admin_password', adminPassword);
            _log('[ESP32] 管理员密码已更新'); _log('[APP] 管理员密码已修改'); _message('管理员密码已更新'); Navigator.pop(pageCtx);
          }, isEnabled: true),
        ])),
      ])),
    );
  }

  // 2. 恢复默认蓝牙密码
  Widget _resetPasswordPage(BuildContext pageCtx) {
    return Scaffold(
      backgroundColor: TKColors.bgPrimary,
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TKIconButton(icon: Icons.arrow_back, color: TKColors.neonBlue, onTap: () => Navigator.pop(pageCtx)),
          const TKPageTitle(title: '恢复默认蓝牙密码'),
          const SizedBox(width: 48),
        ])),
        Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.restart_alt, color: TKColors.neonRed, size: 80),
          const SizedBox(height: 24),
          const Text('恢复后蓝牙密码将重置为出厂默认值', style: TextStyle(color: TKColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: TKNeonButton(label: '恢复默认蓝牙密码', icon: Icons.restore, neonColor: TKColors.neonRed, onTap: () async {
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
              adminPassword = defaultPassword;
              esp32.resetPassword();
              prefs?.setString('admin_password', defaultPassword);
              _log('[ESP32] 蓝牙密码已恢复默认'); _log('[APP] 恢复默认蓝牙密码'); _message('已恢复默认密码'); Navigator.pop(pageCtx);
            } else {
              _message('密码错误或已取消');
            }
          }, isEnabled: true)),
        ]))),
      ])),
    );
  }

  // 3. 设备名称
  Widget _deviceNamePage(BuildContext pageCtx) {
    final ctrl = TextEditingController(text: deviceName);
    return Scaffold(
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
          TKNeonButton(label: '保存', icon: Icons.check, neonColor: TKColors.neonBlue, onTap: () {
            final v = ctrl.text.trim();
            if (v.isEmpty) { _message('名称不能为空'); return; }
            deviceName = v;
            prefs?.setString('device_name', v);
            _log('[APP] 设备名称已修改为 $v'); _message('设备名称已更新'); Navigator.pop(pageCtx);
          }, isEnabled: true),
        ])),
      ])),
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
            onChanged: (v) { setLocalState(() {}); setState(() { autoConnect = v; }); prefs?.setBool('auto_connect', v); _log(v ? '[APP] 自动连接开启' : '[APP] 自动连接关闭'); },
            leadingIcon: Icons.bluetooth,
          ),
        ])))),
      ])),
    );
  }

  // 6. 提示音设置
  Widget _soundPage(BuildContext pageCtx) {
    return Scaffold(
      backgroundColor: TKColors.bgPrimary,
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TKIconButton(icon: Icons.arrow_back, color: TKColors.neonBlue, onTap: () => Navigator.pop(pageCtx)),
          const TKPageTitle(title: '提示音设置'),
          const SizedBox(width: 48),
        ])),
        Expanded(child: StatefulBuilder(builder: (context, setLocalState) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TKBigIcon(icon: Icons.volume_up, color: TKColors.neonBlue, size: 80),
          const SizedBox(height: 24),
          TKSwitchTile(
            title: '提示音',
            subtitle: '开启后，操作时播放提示音',
            value: sound,
            onChanged: (v) { setLocalState(() {}); setState(() { sound = v; }); prefs?.setBool('sound', v); _log(v ? '[APP] 声音反馈开启' : '[APP] 声音反馈关闭'); },
            leadingIcon: Icons.volume_up,
          ),
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
              if (!simulationMode) await ble.disconnect();
              esp32.factoryReset();
              await prefs?.clear();
              adminPassword = defaultPassword;
              adminDevice = null; savedRemoteId = null; authorized = false; autoConnect = true; sound = true; simulationMode = true;
              deviceName = defaultName; borrowCode = null; borrowStart = null; borrowEnd = null;
              connected = false; foundDevice = null; mode = null; adminSession = false; timeSynced = false;
              final newId = 'TK-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1000000)}';
              installId = newId;
              await prefs?.setString('install_id', newId);
              _log('[APP] 恢复出厂'); _message('恢复出厂完成'); Navigator.pop(pageCtx);
            } else {
              _message('密码错误或已取消');
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
              _infoRow('自动落锁', esp32.autoLockEnabled ? '已开启' : '已关闭'),
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

  // 管理员操作列表项
  Widget _AdminActionTile({
    required String title,
    required IconData icon,
    required VoidCallback? onTap,
    bool isDanger = false,
  }) {
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
      ),
    );
  }

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
      case PageTab.admin: return adminPage();
    }
  }
}
