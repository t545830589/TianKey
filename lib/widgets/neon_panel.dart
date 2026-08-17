import 'package:flutter/material.dart';

class NeonPanel extends StatelessWidget {
  final Widget child;
  final Color glow;
  const NeonPanel({super.key, required this.child, this.glow = const Color(0xFF008CFF)});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF050B14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: glow.withOpacity(.8), width: 1.2),
        boxShadow: [BoxShadow(color: glow.withOpacity(.35), blurRadius: 18)],
      ),
      child: child,
    );
  }
}

class HudButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  const HudButton({super.key, required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: InkWell(
          onTap: onTap,
          child: NeonPanel(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: onTap == null ? Colors.grey : const Color(0xFF39A8FF)),
                const SizedBox(height: 6),
                Text(title, style: const TextStyle(color: Colors.white))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
