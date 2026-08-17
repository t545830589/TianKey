import 'package:flutter/material.dart';

class V11StatusPanel extends StatelessWidget {
  final String bluetooth;
  final String auth;
  final String time;

  const V11StatusPanel({
    super.key,
    required this.bluetooth,
    required this.auth,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF071018),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF159CFF), width: 1.5),
      ),
      child: Column(
        children: [
          _row('BLE', bluetooth),
          _row('AUTH', auth),
          _row('TIME', time),
        ],
      ),
    );
  }

  Widget _row(String a, String b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(a, style: const TextStyle(color: Colors.grey)),
          Text(b, style: const TextStyle(color: Color(0xFF19D36B))),
        ],
      ),
    );
  }
}
