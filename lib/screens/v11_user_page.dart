import 'package:flutter/material.dart';

class V11UserPage extends StatelessWidget {
  const V11UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF02060D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, color: Color(0xFF4DA3FF), size: 64),
            SizedBox(height: 20),
            Text('TIANKEY USER CONTROL', style: TextStyle(color: Colors.white, fontSize: 22)),
            SizedBox(height: 12),
            Text('ADMIN / GUEST / AUTH STATUS', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
