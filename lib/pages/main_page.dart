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

  // One shared simulated ESP32 and one shared vehicle model for the whole APP.
  final MockESP32 esp32 = MockESP32();
  final MockVehicle vehicle = MockVehicle();

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(esp32: esp32, vehicle: vehicle),
      PermissionPage(esp32: esp32),
      const SettingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (i) {
          setState(() {
            index = i;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: '权限',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
