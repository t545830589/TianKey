import 'package:flutter/material.dart';

class V11UserPage extends StatelessWidget {
  const V11UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02060D),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.person, color: Color(0xFF4DA3FF), size: 72),
            const SizedBox(height: 12),
            const Text(
              'TIANKEY USER CONTROL',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _card('ADMIN', 'Full vehicle control permission', Icons.admin_panel_settings),
            _card('GUEST', 'Temporary access mode', Icons.person_outline),
            _card('AUTH STATUS', 'Bluetooth authentication ready', Icons.verified_user),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF091827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1595FF)),
        boxShadow: const [BoxShadow(color: Color(0x331595FF), blurRadius: 12)],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4DA3FF)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
              Text(value, style: const TextStyle(color: Colors.white54)),
            ],
          )
        ],
      ),
    );
  }
}
