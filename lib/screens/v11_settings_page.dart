import 'package:flutter/material.dart';

class V11SettingsPage extends StatelessWidget {
  const V11SettingsPage({super.key});

  Widget card(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF081321),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1976D2)),
        boxShadow: const [
          BoxShadow(color: Color(0x554DA3FF), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4DA3FF), size: 32),
          const SizedBox(width: 16),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02060D),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const Text('TIANKEY SETTINGS', style: TextStyle(color: Colors.white, fontSize: 26)),
            const SizedBox(height: 20),
            card('BLE CONNECTION', 'READY', Icons.bluetooth),
            card('ESP32 DEVICE', 'CONNECTED', Icons.memory),
            card('TIME SYNC', 'AUTO', Icons.access_time),
            card('SOUND', 'ENABLED', Icons.volume_up),
            card('SYSTEM INFO', 'V11 SMART CONTROL', Icons.info),
          ],
        ),
      ),
    );
  }
}
