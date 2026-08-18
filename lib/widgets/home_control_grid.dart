import 'package:flutter/material.dart';

class HomeControlGrid extends StatelessWidget {
  final List<Widget> children;
  const HomeControlGrid({super.key, this.children = const []});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: children,
    );
  }
}
