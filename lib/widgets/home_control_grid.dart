import 'package:flutter/material.dart';

class HomeControlGrid extends StatelessWidget {
  final List<Widget> children;
  const HomeControlGrid({super.key, this.children = const []});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}
