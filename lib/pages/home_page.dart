import 'package:flutter/material.dart';

import '../services/mock_esp32.dart';
import '../services/mock_vehicle.dart';
import 'bluetooth_page.dart';
import 'permission_page.dart';
import 'control_page.dart';
import 'log_page.dart';

class HomePage extends StatefulWidget {
  final MockESP32 esp32;
  final MockVehicle vehicle;

  const HomePage({
    super.key,
    required this.esp32,
    required this.vehicle,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> openBluetooth() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BluetoothPage(esp32: widget.esp32),
      ),
    );
    if (mounted) setState(() {});
  }

  void disconnect() {
    widget.esp32.disconnectBLE();
    setState(() {});
  }

  void openPermission() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PermissionPage(esp32: widget.esp32),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void openControl() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ControlPage(
          esp32: widget.esp32,
          vehicle: widget.vehicle,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void openLog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogPage(esp32: widget.esp32),
      ),
    );
  }

  Widget glassButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.55)),
          color: Colors.black.withOpacity(0.48),
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
          ),
          icon: Icon(icon),
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget statusChip(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.48),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connected = widget.esp32.isConnected();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/home_car_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            Container(color: Colors.black.withOpacity(0.28)),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'TIAN KEY V11',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: connected ? Colors.greenAccent.withOpacity(0.18) : Colors.redAccent.withOpacity(0.18),
                          border: Border.all(color: connected ? Colors.greenAccent : Colors.redAccent),
                        ),
                        child: Text(
                          connected ? 'BLE 已连接' : 'BLE 未连接',
                          style: TextStyle(
                            color: connected ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    MockESP32.vehicleName,
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 190),
                  Row(
                    children: [
                      statusChip('电量', widget.vehicle.getBattery()),
                      statusChip('车锁', widget.vehicle.getLockStatus()),
                      statusChip('温度', widget.vehicle.getTemperature()),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      statusChip('当前身份', widget.esp32.getCurrentUser()),
                      statusChip('设备', widget.esp32.deviceId),
                    ],
                  ),
                  const SizedBox(height: 18),
                  glassButton(
                    label: connected ? '断开车辆' : '连接车辆',
                    icon: connected ? Icons.bluetooth_disabled : Icons.bluetooth,
                    onPressed: connected ? disconnect : openBluetooth,
                  ),
                  const SizedBox(height: 10),
                  glassButton(
                    label: '车辆控制',
                    icon: Icons.directions_car_filled,
                    onPressed: connected ? openControl : null,
                  ),
                  const SizedBox(height: 10),
                  glassButton(
                    label: '权限管理',
                    icon: Icons.admin_panel_settings_outlined,
                    onPressed: openPermission,
                  ),
                  const SizedBox(height: 10),
                  glassButton(
                    label: '车辆日志',
                    icon: Icons.history,
                    onPressed: openLog,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
