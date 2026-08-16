import 'package:flutter/material.dart';

import '../services/mock_esp32.dart';

class LogPage extends StatefulWidget {
  final MockESP32 esp32;

  const LogPage({
    super.key,
    required this.esp32,
  });

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  late List<String> logs;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    logs = widget.esp32.getLogs();
  }

  void _clear() {
    widget.esp32.clearLogs();
    setState(_refresh);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('车辆日志'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: () => setState(_refresh),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '清空',
            onPressed: logs.isEmpty ? null : _clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(child: Text('暂无日志'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.history),
                    title: Text(logs[index]),
                  ),
                );
              },
            ),
    );
  }
}
