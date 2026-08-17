import 'package:flutter/material.dart';

class V11HudTheme {
  static const background = Color(0xFF05070A);
  static const cyan = Color(0xFF00D9FF);
  static const green = Color(0xFF19D36B);
  static const orange = Color(0xFFFF9800);

  static BoxDecoration panel() {
    return BoxDecoration(
      color: const Color(0xCC101820),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: cyan.withValues(alpha: 0.35)),
      boxShadow: [
        BoxShadow(
          color: cyan.withValues(alpha: 0.15),
          blurRadius: 18,
        ),
      ],
    );
  }
}
