import 'package:flutter/material.dart';

import '../services/mock_esp32.dart';

class ControlPage extends StatelessWidget {
  final MockESP32 esp32;

  const ControlPage({
    super.key,
    required this.esp32,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('车辆控制')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('设备: ${esp32.deviceId}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text('锁车'),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('解锁'),
            ),
          ],
        ),
      ),
    );
  }
}
