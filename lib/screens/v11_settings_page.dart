import 'package:flutter/material.dart';

class V11SettingsPage extends StatelessWidget {
  const V11SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF02060D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, color: Color(0xFF4DA3FF), size: 64),
            SizedBox(height: 20),
            Text('TIANKEY SETTINGS', style: TextStyle(color: Colors.white, fontSize: 22)),
            SizedBox(height: 12),
            Text('BLE / DEVICE / TIME / SOUND / INFO', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
