import 'package:flutter/material.dart';

import '../services/mock_esp32.dart';
import '../services/mock_vehicle.dart';

class ControlPage extends StatelessWidget {
  final MockESP32 esp32;
  final MockVehicle vehicle;

  const ControlPage({
    super.key,
    required this.esp32,
    required this.vehicle,
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
            const SizedBox(height: 16),
            Text('电量: ${vehicle.getBattery()}'),
            Text('车锁: ${vehicle.getLockStatus()}'),
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
