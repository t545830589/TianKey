import 'package:flutter/material.dart';

import '../services/mock_esp32.dart';
import '../services/mock_vehicle.dart';
import 'home_page.dart';
import 'permission_page.dart';
import 'settings_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int index = 0;
  bool restoring = true;

  late final MockESP32 esp32;
  late final MockVehicle vehicle;

  @override
  void initState() {
    super.initState();
    esp32 = MockESP32();
    vehicle = MockVehicle();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    await esp32.restoreState();
    if (!mounted) return;
    setState(() => restoring = false);
  }

  @override
  Widget build(BuildContext context) {
    if (restoring) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = <Widget>[
      HomePage(esp32: esp32, vehicle: vehicle),
      PermissionPage(esp32: esp32),
      SettingsPage(esp32: esp32),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.grey,
        onTap: (value) => setState(() => index = value),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: '权限'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
