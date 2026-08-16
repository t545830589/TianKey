import 'package:flutter/material.dart';

import '../services/mock_esp32.dart';

class BluetoothPage extends StatefulWidget {
  final MockESP32 esp32;

  const BluetoothPage({
    super.key,
    required this.esp32,
  });

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  List<String> devices = const [];
  String? selectedDevice;
  String message = '点击扫描附近设备';
  bool busy = false;

  void scan() {
    setState(() {
      busy = true;
      message = '正在扫描……';
    });

    final result = widget.esp32.scanDevices();

    setState(() {
      devices = result;
      selectedDevice = result.isEmpty ? null : result.first;
      message = result.isEmpty ? '未发现车辆' : '发现 ${result.first}';
      busy = false;
    });
  }

  Future<void> chooseIdentity() async {
    if (selectedDevice == null) {
      setState(() => message = '请先扫描并选择车辆');
      return;
    }

    final role = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF081019),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '选择连接身份',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _roleButton(
                  context,
                  title: '管理员连接',
                  subtitle: '输入管理员密码并验证',
                  icon: Icons.admin_panel_settings_outlined,
                  value: 'admin',
                ),
                const SizedBox(height: 10),
                _roleButton(
                  context,
                  title: '临时借车连接',
                  subtitle: '输入临时借车密码',
                  icon: Icons.key_outlined,
                  value: 'temporary',
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || role == null) return;

    if (role == 'admin') {
      await _adminLogin();
    } else {
      await _temporaryLogin();
    }
  }

  Widget _roleButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pop(context, value),
        icon: Icon(icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16)),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _adminLogin() async {
    final controller = TextEditingController();
    final password = await _passwordDialog(
      title: '管理员连接',
      hint: '输入管理员密码',
      controller: controller,
    );
    controller.dispose();
    if (!mounted || password == null) return;

    var authorized = widget.esp32.adminLogin(password);
    if (!authorized && widget.esp32.adminSeatOccupied) {
      final migrate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('管理员席位已占用'),
          content: const Text('这辆车已有其他手机占用管理员席位。继续将立即迁移管理员权限，旧管理员授权失效。是否继续？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认迁移'),
            ),
          ],
        ),
      );
      if (migrate == true) {
        authorized = widget.esp32.migrateAdmin(password);
      }
    }

    if (!authorized) {
      setState(() => message = '管理员认证失败，不能建立正式连接');
      return;
    }

    final connected = widget.esp32.connectBLE();
    setState(() => message = connected ? '管理员 BLE 正式连接成功' : 'BLE 正式连接失败');
    if (connected && mounted) Navigator.pop(context, true);
  }

  Future<void> _temporaryLogin() async {
    final controller = TextEditingController();
    final password = await _passwordDialog(
      title: '临时借车连接',
      hint: '输入临时借车密码',
      controller: controller,
    );
    controller.dispose();
    if (!mounted || password == null) return;

    final authorized = widget.esp32.temporaryLogin(password);
    if (!authorized) {
      setState(() => message = '临时密码错误、未到开始时间或已过期');
      return;
    }

    final connected = widget.esp32.connectBLE();
    setState(() => message = connected ? '临时借车 BLE 正式连接成功' : 'BLE 正式连接失败');
    if (connected && mounted) Navigator.pop(context, true);
  }

  Future<String?> _passwordDialog({
    required String title,
    required String hint,
    required TextEditingController controller,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            decoration: InputDecoration(hintText: hint),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('验证'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final connected = widget.esp32.isConnected();

    return Scaffold(
      appBar: AppBar(title: const Text('蓝牙连接')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前状态：${connected ? '已连接' : '未连接'}'),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Colors.cyanAccent)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: busy ? null : scan,
                icon: const Icon(Icons.bluetooth_searching),
                label: Text(busy ? '扫描中……' : '扫描设备'),
              ),
            ),
            const SizedBox(height: 12),
            ...devices.map(
              (device) => Card(
                child: RadioListTile<String>(
                  value: device,
                  groupValue: selectedDevice,
                  onChanged: (value) => setState(() => selectedDevice = value),
                  title: Text(device),
                  subtitle: const Text('可用车辆设备'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: selectedDevice == null || connected ? null : chooseIdentity,
                icon: const Icon(Icons.link),
                label: const Text('连接'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
