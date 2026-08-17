import 'package:flutter/material.dart';

/// Tian Key V11 dashboard integration scaffold.
/// This widget is prepared for wiring the HUD components into the main screen.
class V11DashboardBridge extends StatelessWidget {
  final Widget child;

  const V11DashboardBridge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E88FF), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x551E88FF),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: child,
    );
  }
}
