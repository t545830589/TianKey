import 'package:flutter/material.dart';

class V11StatusChip extends StatelessWidget {
  final String title;
  final String value;
  final bool active;

  const V11StatusChip({
    super.key,
    required this.title,
    required this.value,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF101820),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? const Color(0xFF19D36B) : const Color(0xFF33404A),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$title: ', style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: TextStyle(
              color: active ? const Color(0xFF19D36B) : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
