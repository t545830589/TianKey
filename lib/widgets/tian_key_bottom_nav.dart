import 'package:flutter/material.dart';

class TianKeyBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const TianKeyBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      backgroundColor: const Color(0xFF061321),
      selectedIndex: currentIndex,
      onDestinationSelected: onChanged,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: '首页'),
        NavigationDestination(icon: Icon(Icons.people), label: '临时借车'),
        NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
      ],
    );
  }
}
