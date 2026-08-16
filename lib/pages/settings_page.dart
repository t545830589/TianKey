import 'package:flutter/material.dart';

import '../services/mock_esp32.dart';

class SettingsPage extends StatefulWidget {
  final MockESP32 esp32;

  const SettingsPage({
    super.key,
    required this.esp32,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController deviceNameController = TextEditingController();
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();

  String message = '设置状态：等待操作';

  @override
  void dispose() {
    deviceNameController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  void saveDeviceName() {
    widget.esp32.setDeviceName(deviceNameController.text);
    setState(() => message = '设备名称已保存');
  }

  void savePassword() {
    final ok = widget.esp32.changeAdminPassword(
      currentPasswordController.text,
      newPasswordController.text,
    );
    setState(() => message = ok ? '管理员密码修改成功' : '密码修改失败，请确认当前密码、身份和长度');
  }

  void factoryReset() {
    widget.esp32.factoryReset();
    deviceNameController.clear();
    currentPasswordController.clear();
    newPasswordController.clear();
    setState(() => message = '已恢复出厂设置');
  }

  @override
  Widget build(BuildContext context) {
    final authorized = widget.esp32.adminAuthorized;

    return Scaffold(
      appBar: AppBar(
        title: const Text('车辆设置'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(message, style: const TextStyle(color: Colors.cyanAccent)),
          const SizedBox(height: 18),
          const Text('车辆信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('车辆名称'),
            subtitle: Text(MockESP32.vehicleName),
          ),
          const Divider(),
          const SizedBox(height: 12),
          const Text('安全设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: currentPasswordController,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '当前管理员密码'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: newPasswordController,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '新管理员密码（至少8位）'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: authorized ? savePassword : null,
            child: const Text('保存密码'),
          ),
          const SizedBox(height: 24),
          const Text('ESP32设备信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('设备ID：${widget.esp32.deviceId}'),
          const Text('蓝牙名称：TianKey BLE'),
          const SizedBox(height: 10),
          TextField(
            controller: deviceNameController,
            decoration: const InputDecoration(labelText: '修改设备ID/名称'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: authorized ? saveDeviceName : null,
            child: const Text('保存设备名称'),
          ),
          const SizedBox(height: 24),
          const Text('临时借车', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: authorized
                ? () {
                    final password = widget.esp32.generateTemporaryPassword(const Duration(hours: 8));
                    showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('临时借车密码'),
                        content: Text('密码：$password\n有效期：8小时'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('确定')),
                        ],
                      ),
                    );
                    setState(() {});
                  }
                : null,
            child: const Text('生成临时借车密码'),
          ),
          Text('当前临时密码：${widget.esp32.temporaryPassword.isEmpty ? '无' : widget.esp32.temporaryPassword}'),
          Text('开始：${widget.esp32.temporaryStart ?? '无'}'),
          Text('结束：${widget.esp32.temporaryEnd ?? '无'}'),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: authorized ? () { widget.esp32.cancelTemporaryLoan(); setState(() {}); } : null,
            child: const Text('取消临时借车'),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('恢复出厂设置'),
                  content: const Text('将清除模拟ESP32权限、临时密码、连接状态和设备名称。'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('确认恢复')),
                  ],
                ),
              );
              if (confirmed == true) factoryReset();
            },
            child: const Text('恢复出厂设置'),
          ),
        ],
      ),
    );
  }
}
