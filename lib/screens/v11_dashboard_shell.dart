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
          const SizedBox(height: 20),
          const Text('TIANKEY V11', style: TextStyle(color: Color(0xFF4DA3FF), fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1595FF)),
              color: const Color(0x220095FF),
            ),
            child: const Center(
              child: Text('VEHICLE HUD AREA', style: TextStyle(color: Color(0xFF8BC7FF), fontSize: 18)),
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: V11VehiclePanel(),
          ),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
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
          const Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: _BottomNav(),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF091827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1595FF), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x331595FF), blurRadius: 12)],
      ),
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

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Icon(Icons.home, color: Color(0xFF4DA3FF)),
        Icon(Icons.people, color: Colors.white54),
        Icon(Icons.settings, color: Colors.white54),
      ],
    );
  }
}
