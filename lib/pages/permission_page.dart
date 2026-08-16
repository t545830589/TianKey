import 'package:flutter/material.dart';
import '../services/mock_esp32.dart';

class PermissionPage extends StatefulWidget {
  final MockESP32 esp32;

  const PermissionPage({
    super.key,
    required this.esp32,
  });

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  final TextEditingController passwordController = TextEditingController();
  String message = '等待授权操作';

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  Future<void> adminLogin() async {
    final password = passwordController.text.trim();
    var ok = widget.esp32.adminLogin(password);

    if (!ok && widget.esp32.adminSeatOccupied) {
      final migrate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('管理员席位已占用'),
          content: const Text('继续操作将迁移管理员席位，原管理员授权立即失效。确认继续？'),
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
        ok = widget.esp32.migrateAdmin(password);
      }
    }

    setState(() {
      message = ok ? '管理员授权成功' : '管理员密码错误或迁移未确认';
    });
  }

  void temporaryLogin() {
    final ok = widget.esp32.temporaryLogin(passwordController.text.trim());
    setState(() {
      message = ok ? '临时借车授权成功' : '临时密码错误、未到开始时间或已过期';
    });
  }

  String formatDate(DateTime? time) {
    if (time == null) return '无';
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-'
        '${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final temporaryStatus = widget.esp32.temporaryAuthorizationStatus;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('权限管理'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '当前身份：${widget.esp32.getCurrentUser()}',
            style: const TextStyle(color: Colors.cyan, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text('权限类型：${widget.esp32.sessionRole}'),
          Text('管理员席位：${widget.esp32.adminSeatOccupied ? '已占用' : '空闲'}'),
          Text('临时状态：$temporaryStatus'),
          const SizedBox(height: 20),
          TextField(
            controller: passwordController,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '输入管理员/临时借车密码'),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: adminLogin,
                  child: const Text('管理员授权'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: temporaryLogin,
                  child: const Text('临时借车授权'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(message, style: const TextStyle(color: Colors.greenAccent)),
          const SizedBox(height: 24),
          const Text('临时借车时间', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('开始：${formatDate(widget.esp32.temporaryStart)}'),
          Text('结束：${formatDate(widget.esp32.temporaryEnd)}'),
          const SizedBox(height: 16),
          Text('设备状态：${widget.esp32.isConnected() ? 'BLE已连接' : 'BLE未连接'}'),
        ],
      ),
    );
  }
}
