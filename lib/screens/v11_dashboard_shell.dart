import 'package:flutter/material.dart';
import '../widgets/v11_vehicle_panel.dart';

class V11DashboardShell extends StatelessWidget {
  const V11DashboardShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF02060D), Color(0xFF071426)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Text(
            'TIANKEY V11',
            style: TextStyle(
              color: Color(0xFF4DA3FF),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: V11VehiclePanel(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              children: const [
                _HudTile(icon: Icons.bluetooth, title: 'BLE'),
                _HudTile(icon: Icons.lock, title: 'LOCK'),
                _HudTile(icon: Icons.lock_open, title: 'UNLOCK'),
                _HudTile(icon: Icons.directions_car, title: 'CAR'),
                _HudTile(icon: Icons.sensors, title: 'RADAR'),
                _HudTile(icon: Icons.settings, title: 'SETUP'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HudTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const _HudTile({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF091827),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Color(0xFF1595FF), size: 34),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
