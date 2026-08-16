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
      widget.esp32.recordVehicleEvent('$command失败：设备未连接');
      setState(() => status = '设备未连接，拒绝执行');
      return;
    }

    final accepted = widget.esp32.executeCommand(command);
    if (accepted == '设备未连接' ||
        accepted == '无有效授权' ||
        accepted == '临时授权已失效') {
      setState(() => status = accepted);
      return;
    }

    setState(() {
      busy = command == '升窗' || command == '降窗' || command == '后备箱';
      status = accepted;
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

    final hardwareTrace = widget.vehicle.lastHardwareTrace;
    widget.esp32.recordVehicleEvent('$command执行完成：$hardwareTrace');

    if (!mounted) return;
    setState(() {
      busy = false;
      status = '$command执行成功\n$hardwareTrace';
    });
  }

  Widget actionButton(String label, IconData icon) {
    final isLong = label == '升窗' || label == '降窗' || label == '后备箱';
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: InkWell(
          onTap: busy ? null : () => execute(label),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(minHeight: 96),
            decoration: BoxDecoration(
              color: const Color(0xCC07131F),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.45), width: 1.2),
              boxShadow: const [
                BoxShadow(color: Color(0x5500E5FF), blurRadius: 12, spreadRadius: 1),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30, color: isLong ? Colors.orangeAccent : Colors.cyanAccent),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                if (isLong)
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Text('7秒动作', style: TextStyle(fontSize: 11, color: Colors.white54)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('车辆控制中心'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/home_controls_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xCC020B12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('陕A0P92Y', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.cyanAccent)),
                    const SizedBox(height: 5),
                    Text('身份：${widget.esp32.getCurrentUser()}'),
                    Text('BLE：${widget.esp32.isConnected() ? '已连接' : '未连接'}'),
                    const SizedBox(height: 8),
                    Text(status, style: const TextStyle(color: Colors.greenAccent, height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(children: [actionButton('锁车', Icons.lock), actionButton('解锁', Icons.lock_open)]),
              Row(children: [actionButton('寻车', Icons.directions_car), actionButton('后备箱', Icons.inventory_2_outlined)]),
              Row(children: [actionButton('升窗', Icons.keyboard_arrow_up), actionButton('降窗', Icons.keyboard_arrow_down)]),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xCC020B12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('车辆状态', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    const SizedBox(height: 10),
                    Text('车锁：${widget.vehicle.getLockStatus()}'),
                    Text('车门：${widget.vehicle.getDoorStatus()}'),
                    Text('电量：${widget.vehicle.getBattery()}'),
                    Text('温度：${widget.vehicle.getTemperature()}'),
                    Text('硬件映射：${widget.vehicle.lastHardwareTrace}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
