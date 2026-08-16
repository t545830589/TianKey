import 'package:flutter/material.dart';

import '../services/mock_esp32.dart';

class BorrowPage extends StatefulWidget {
  final MockESP32 esp32;

  const BorrowPage({super.key, required this.esp32});

  @override
  State<BorrowPage> createState() => _BorrowPageState();
}

class _BorrowPageState extends State<BorrowPage> {
  String status = '等待管理员生成临时借车授权';

  Future<void> generate() async {
    if (!widget.esp32.adminAuthorized) {
      setState(() => status = '请先完成管理员授权');
      return;
    }

    final duration = await showDialog<Duration>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择临时借车时长'),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(context, const Duration(hours: 1)), child: const Text('1小时')),
          SimpleDialogOption(onPressed: () => Navigator.pop(context, const Duration(hours: 4)), child: const Text('4小时')),
          SimpleDialogOption(onPressed: () => Navigator.pop(context, const Duration(hours: 8)), child: const Text('8小时')),
          SimpleDialogOption(onPressed: () => Navigator.pop(context, const Duration(hours: 24)), child: const Text('24小时')),
        ],
      ),
    );
    if (!mounted || duration == null) return;

    final password = widget.esp32.generateTemporaryPassword(duration);
    setState(() => status = '临时密码已生成：$password\n有效期至：${widget.esp32.temporaryEnd}');
  }

  void cancel() {
    widget.esp32.cancelTemporaryLoan();
    setState(() => status = '临时借车授权已取消');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('临时借车')), 
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/borrow_page_bg.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.38)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const Text('临时借车授权', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                _panel('管理员状态', '当前身份：${widget.esp32.getCurrentUser()}\n管理员席位：${widget.esp32.adminSeatOccupied ? '已占用' : '空闲'}'),
                const SizedBox(height: 12),
                _panel('当前临时授权', '密码：${widget.esp32.temporaryPassword.isEmpty ? '无' : widget.esp32.temporaryPassword}\n开始：${widget.esp32.temporaryStart ?? '无'}\n结束：${widget.esp32.temporaryEnd ?? '无'}'),
                const SizedBox(height: 12),
                Text(status, style: const TextStyle(color: Colors.cyanAccent, height: 1.4)),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: generate, icon: const Icon(Icons.vpn_key), label: const Text('生成临时密码'))),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: widget.esp32.temporaryPassword.isEmpty ? null : cancel, icon: const Icon(Icons.cancel_outlined), label: const Text('取消临时借车'))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel(String title, String body) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xCC020B12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.cyanAccent, fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(height: 1.45)),
      ]),
    );
  }
}
