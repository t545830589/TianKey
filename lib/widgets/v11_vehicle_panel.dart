import 'package:flutter/material.dart';

class V11VehiclePanel extends StatelessWidget {
  final bool locked;
  final String power;
  final String connection;

  const V11VehiclePanel({
    super.key,
    this.locked = true,
    this.power = '100%',
    this.connection = 'ONLINE',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          const Text(
            'TIANKEY V11',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Icon(Icons.directions_car, size: 90, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text('LOCK: ${locked ? 'LOCKED' : 'UNLOCKED'}',
              style: const TextStyle(color: Colors.white)),
          Text('POWER: $power',
              style: const TextStyle(color: Colors.white)),
          Text('BLE: $connection',
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
