import 'package:flutter/material.dart';

/// V11 home HUD overlay prepared for main.dart integration.
class V11HomeOverlay extends StatelessWidget {
  final String status;
  final VoidCallback? onLock;
  final VoidCallback? onUnlock;
  final VoidCallback? onFind;
  final VoidCallback? onTrunk;

  const V11HomeOverlay({
    super.key,
    required this.status,
    this.onLock,
    this.onUnlock,
    this.onFind,
    this.onTrunk,
  });

  Widget _key(String text, IconData icon, VoidCallback? tap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: OutlinedButton(
          onPressed: tap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(icon), Text(text)],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF19D3FF)),
          ),
          child: Text(status),
        ),
        Row(children: [
          _key('锁车', Icons.lock, onLock),
          _key('解锁', Icons.lock_open, onUnlock),
        ]),
        Row(children: [
          _key('寻车', Icons.search, onFind),
          _key('后备箱', Icons.directions_car, onTrunk),
        ]),
      ],
    );
  }
}
