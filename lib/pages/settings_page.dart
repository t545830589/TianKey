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

  Future<void> generateTemporaryPassword() async {
    if (!widget.esp32.adminAuthorized) return;
    final duration = await showDialog<Duration>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择借车时长'),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(context, const Duration(hours: 1)), child: const Text('1小时')),
          SimpleDialogOption(onPressed: () => Navigator.pop(context, const Duration(hours: 4)), child: const Text('4小时')),
          SimpleDialogOption(onPressed: () => Navigator.pop(context, const Duration(hours: 8)), child: const Text('8小时')),
          SimpleDialogOption(onPressed: () => Navigator.pop(context, const Duration(days: 1)), child: const Text('24小时')),
        ],
      ),
    );
    if (!mounted || duration == null) return;

    final password = widget.esp32.generateTemporaryPassword(duration);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('临时借车密码'),
        content: Text('密码：$password\n有效期至：${widget.esp32.temporaryEnd}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('确定')),
        ],
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authorized = widget.esp32.adminAuthorized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/settings_page_bg.png', fit: BoxFit.cover),
            Container(color: Colors.black.withOpacity(0.4)),
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                const Text(
                  '车辆设置',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                Text(message, style: const TextStyle(color: Colors.cyanAccent)),
                const SizedBox(height: 16),
                _panel(
                  title: '车辆信息',
                  child: const ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('车辆名称', style: TextStyle(color: Colors.white60)),
                    subtitle: Text(MockESP32.vehicleName, style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 12),
                _panel(
                  title: '安全设置',
                  child: Column(
                    children: [
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
                      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: authorized ? savePassword : null, child: const Text('保存密码'))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _panel(
                  title: 'ESP32设备信息',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('设备ID：${widget.esp32.deviceId}'),
                      const SizedBox(height: 4),
                      const Text('蓝牙名称：TianKey BLE'),
                      const SizedBox(height: 10),
                      TextField(controller: deviceNameController, decoration: const InputDecoration(labelText: '修改设备ID/名称')),
                      const SizedBox(height: 10),
                      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: authorized ? saveDeviceName : null, child: const Text('保存设备名称'))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _panel(
                  title: '临时借车',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: authorized ? generateTemporaryPassword : null, child: const Text('生成临时借车密码'))),
                      Text('当前临时密码：${widget.esp32.temporaryPassword.isEmpty ? '无' : widget.esp32.temporaryPassword}'),
                      Text('开始：${widget.esp32.temporaryStart ?? '无'}'),
                      Text('结束：${widget.esp32.temporaryEnd ?? '无'}'),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: authorized ? () { widget.esp32.cancelTemporaryLoan(); setState(() {}); } : null, child: const Text('取消临时借车'))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _panel(
                  title: '恢复出厂',
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
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
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
