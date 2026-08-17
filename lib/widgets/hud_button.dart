import 'package:flutter/material.dart';

class HudButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const HudButton({super.key, required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF102B22) : const Color(0xFF22252A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled ? const Color(0xFF19D36B) : Colors.grey,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: enabled ? const Color(0xFF19D36B) : Colors.grey),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      ),
    );
  }
}
