import 'package:flutter/material.dart';
import 'v11_dashboard_shell.dart';
import 'v11_user_page.dart';
import 'v11_settings_page.dart';

class V11AppNavigation extends StatefulWidget {
  const V11AppNavigation({super.key});

  @override
  State<V11AppNavigation> createState() => _V11AppNavigationState();
}

class _V11AppNavigationState extends State<V11AppNavigation> {
  int index = 0;

  final pages = const [
    V11DashboardShell(),
    V11UserPage(),
    V11SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02060D),
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        backgroundColor: const Color(0xFF071426),
        selectedItemColor: const Color(0xFF4DA3FF),
        unselectedItemColor: Colors.white54,
        onTap: (value) => setState(() => index = value),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'USER'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'SETUP'),
        ],
      ),
    );
  }
}
