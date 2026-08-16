import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff050912),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tian Key V11', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  title: const Text('陕A0P92Y'),
                  subtitle: const Text('车辆状态：未连接'),
                  leading: const Icon(Icons.directions_car),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  '锁车','解锁','寻车','升窗','降窗','后备箱'
                ].map((e) => ElevatedButton(onPressed: () {}, child: Text(e))).toList(),
              )
            ],
          ),
        ),
      ),
    );
  }
}
