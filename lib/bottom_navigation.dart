import 'package:flutter/material.dart';

class TianKeyBottomNavigation extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;

  const TianKeyBottomNavigation({super.key, required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: current,
      onDestinationSelected: onChanged,
      backgroundColor: const Color(0xff02060d),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: '首页'),
        NavigationDestination(icon: Icon(Icons.people), label: '临时借车'),
        NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
      ],
    );
  }
}
