import 'package:flutter/material.dart';

import '../services/mock_esp32.dart';
import '../services/mock_vehicle.dart';

class ControlPage extends StatefulWidget {
  final MockESP32 esp32;
  final MockVehicle vehicle;

  const ControlPage({
    super.key,
    required this.esp32,
    required this.vehicle,
  });

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  String status = '等待操作';
  bool busy = false;

  Future<void> execute(String command) async {
    if (!widget.esp32.isConnected()) {
      setState(() => status = '设备未连接，拒绝执行');
      return;
    }

    final accepted = widget.esp32.executeCommand(command);
    if (accepted == '设备未连接' || accepted == '无有效授权') {
      setState(() => status = accepted);
      return;
    }

    setState(() {
      busy = command == '升窗' || command == '降窗' || command == '后备箱';
      status = '$accepted';
    });

    switch (command) {
      case '锁车':
        widget.vehicle.lock();
        break;
      case '解锁':
        widget.vehicle.unlock();
        break;
      case '寻车':
        widget.vehicle.search();
        break;
      case '升窗':
        await widget.vehicle.raiseWindow();
        break;
      case '降窗':
        await widget.vehicle.lowerWindow();
        break;
      case '后备箱':
        await widget.vehicle.openTrunk();
        break;
    }

    if (!mounted) return;
    setState(() {
      busy = false;
      status = '$command执行成功\n${widget.vehicle.lastHardwareTrace}';
    });
  }

  Widget actionButton(String label, IconData icon) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: busy ? null : () => execute(label),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('车辆控制')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.cyan,
              fontSize: 18,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          actionButton('锁车', Icons.lock),
          actionButton('解锁', Icons.lock_open),
          actionButton('寻车', Icons.directions_car),
          actionButton('升窗', Icons.keyboard_arrow_up),
          actionButton('降窗', Icons.keyboard_arrow_down),
          actionButton('后备箱', Icons.inventory_2),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('车辆状态', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('车锁：${widget.vehicle.getLockStatus()}'),
                  Text('车门：${widget.vehicle.getDoorStatus()}'),
                  Text('电量：${widget.vehicle.getBattery()}'),
                  Text('温度：${widget.vehicle.getTemperature()}'),
                  Text('硬件映射：${widget.vehicle.lastHardwareTrace}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
