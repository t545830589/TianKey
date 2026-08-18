import 'package:flutter/material.dart';

class VehicleStatusCard extends StatelessWidget {
  const VehicleStatusCard({
    super.key,
    required this.title,
    required this.value,
    this.icon = Icons.info_outline,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF07121F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF173A5A)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF1595FF)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
