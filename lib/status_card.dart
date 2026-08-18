import 'package:flutter/material.dart';

class TianKeyStatusCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const TianKeyStatusCard({super.key, required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xff07131f),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xff243849)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xff1595ff)),
          Text(title, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
