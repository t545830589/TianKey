import 'package:flutter/material.dart';

class TianKeyControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color glowColor;
  final VoidCallback? onPressed;

  const TianKeyControlButton({
    super.key,
    required this.label,
    required this.icon,
    required this.glowColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: const Color(0xFF061321),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: glowColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.35),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: glowColor),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: glowColor, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
