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
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('确认迁移')),
          ],
        ),
      );
      if (migrate == true) ok = widget.esp32.migrateAdmin(password);
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
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget infoTile(String title, String value, {Color color = Colors.white}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xB807131D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: Colors.white60)),
          const Spacer(),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temporaryStatus = widget.esp32.temporaryAuthorizationStatus;
    final connected = widget.esp32.isConnected();

    return Scaffold(
      appBar: AppBar(
        title: const Text('权限管理'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/borrow_page_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xD9020A11),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TIAN KEY AUTH', style: TextStyle(letterSpacing: 2, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('当前身份：${widget.esp32.getCurrentUser()}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    infoTile('权限类型', widget.esp32.sessionRole),
                    infoTile('管理员席位', widget.esp32.adminSeatOccupied ? '已占用' : '空闲', color: widget.esp32.adminSeatOccupied ? Colors.orangeAccent : Colors.greenAccent),
                    infoTile('临时授权', temporaryStatus, color: temporaryStatus.contains('有效') ? Colors.greenAccent : Colors.white),
                    infoTile('BLE状态', connected ? '已连接' : '未连接', color: connected ? Colors.greenAccent : Colors.orangeAccent),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '输入管理员 / 临时借车密码',
                  filled: true,
                  fillColor: const Color(0xCC06121C),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: adminLogin,
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('管理员授权'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: temporaryLogin,
                      icon: const Icon(Icons.key_outlined),
                      label: const Text('临时借车'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xB807131D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(message, style: const TextStyle(color: Colors.greenAccent, height: 1.35)),
              ),
              const SizedBox(height: 18),
              const Text('临时借车时间', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              infoTile('开始', formatDate(widget.esp32.temporaryStart)),
              infoTile('结束', formatDate(widget.esp32.temporaryEnd)),
            ],
          ),
        ),
      ),
    );
  }
}
