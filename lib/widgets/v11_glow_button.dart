import 'package:flutter/material.dart';

class V11GlowButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color glowColor;
  final VoidCallback? onTap;

  const V11GlowButton({
    super.key,
    required this.title,
    required this.icon,
    required this.glowColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFF07111D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: glowColor.withOpacity(0.9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.45),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: glowColor),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: glowColor)),
          ],
        ),
      ),
    );
  }
}
