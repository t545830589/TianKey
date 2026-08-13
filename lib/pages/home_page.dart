
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tian Key V11'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('车辆信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // 车牌号
            const Text('陕A0P92Y', style: TextStyle(fontSize: 22, color: Colors.cyan)),
            const SizedBox(height: 20),
            
            const Text('当前状态', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // 四个状态信息，符合计划书要求
            _buildStatusRow('设备', '未连接'),
            _buildStatusRow('管理员', '未授权'),
            _buildStatusRow('时间', '未同步'),
            const SizedBox(height: 30),
            
            const Text('控制操作（暂不可用）', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 15),
            // 计划书要求按钮暂时为灰色
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDisabledButton('锁车'),
                _buildDisabledButton('解锁'),
                _buildDisabledButton('寻车'),
                _buildDisabledButton('后备箱'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 辅助组件：显示单行状态
  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label：', style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  // 辅助组件：灰色不可用按钮
  Widget _buildDisabledButton(String text) {
    return ElevatedButton(
      onPressed: null, // 设为 null 即灰色不可点击
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.grey[400],
      ),
      child: Text(text),
    );
  }
}
