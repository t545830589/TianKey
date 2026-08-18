import 'package:flutter/material.dart';

class TianKeyControlButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final bool warning;

  const TianKeyControlButton({super.key, required this.title, required this.icon, this.onTap, this.warning = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: warning ? const Color(0xffff8a1c) : const Color(0xff1595ff)),
          color: const Color(0xff06111d),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: warning ? const Color(0xffff8a1c) : const Color(0xff1595ff)),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
