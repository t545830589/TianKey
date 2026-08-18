import 'package:flutter/material.dart';

class TemporaryBorrowCard extends StatelessWidget {
  const TemporaryBorrowCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('临时借车'),
        subtitle: const Text('无有效密码'),
      ),
    );
  }
}
