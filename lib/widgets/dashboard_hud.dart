import 'package:flutter/material.dart';

class DashboardHud extends StatelessWidget {
  final String title;
  final String status;
  const DashboardHud({super.key, required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF081018),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF168CFF), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x55168CFF), blurRadius: 18),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF19D36B), fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(status, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
