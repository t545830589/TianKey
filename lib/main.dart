import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 强制锁定竖屏，防止在模拟器上拉伸变形
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const TianKeyApp());
  });
}

class TianKeyApp extends StatelessWidget {
  const TianKeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tian Key',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0E1E),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const HomePage(),
    const BorrowPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF151A2E),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.vpn_key), label: '临时借车'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}

// ================= 1. 首页界面 =================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        Positioned.fill(child: Image.asset('assets/home_car_bg.png', fit: BoxFit.fill)),
        Positioned(
          bottom: 0, left: 0, right: 0,
          height: screenH * 0.45,
          child: Image.asset('assets/home_controls_bg.png', fit: BoxFit.fill),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 10, left: screenW * 0.05, right: screenW * 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Tian Key', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    Row(children: [Icon(Icons.settings, color: Colors.white70), SizedBox(width: 15), Icon(Icons.help, color: Colors.white70)])
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: screenH * 0.12, left: 10, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    _StatusItem(label: '设备状态', sub: '未连接', icon: Icons.bluetooth),
                    _StatusItem(label: '管理员状态', sub: '未授权', icon: Icons.security),
                    _StatusItem(label: '供电状态', sub: '未知', icon: Icons.flash_on),
                    _StatusItem(label: '时间同步', sub: '未同步', icon: Icons.access_time),
                    _StatusItem(label: '临时借车', sub: '无有效密码', icon: Icons.vpn_key),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                height: screenH * 0.42,
                child: Stack(
                  children: [
                    _buildBtn('连接设备', screenW * 0.09, 35),
                    _buildBtn('管理员授权', screenW * 0.57, 35),
                    _buildBtn('锁车', screenW * 0.09, 145),
                    _buildBtn('解锁', screenW * 0.57, 145),
                    _buildBtn('车窗升', screenW * 0.09, 255),
                    _buildBtn('车窗降', screenW * 0.57, 255),
                    _buildBtn('寻车', screenW * 0.09, 365),
                    _buildBtn('后备箱', screenW * 0.57, 365),
                  ],
                ),
              ),
              SizedBox(height: screenH * 0.02),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBtn(String label, double left, double top) {
    return Positioned(
      left: left,
      top: top,
      width: 160,
      height: 60,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          print("执行点击命令: $label");
        },
        onLongPress: () {
          if (label == '车窗升' || label == '车窗降' || label == '后备箱') {
            print("执行长按指令(车窗/后备箱持续执行): $label");
          }
        },
        child: Container(
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String sub;
  final IconData icon;
  const _StatusItem({required this.label, required this.sub, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: Colors.white38),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ================= 2. 临时借车界面 =================
class BorrowPage extends StatelessWidget {
  const BorrowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text('临时借车', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('当前状态', style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 8),
            Row(children: const [
              Icon(Icons.vpn_key, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text('无有效临时密码', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))
            ]),
            const SizedBox(height: 30),
            const Text('选择有效时间', style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: ['5分钟','1天','2天','3天','4天','5天','6天','7天'].map((e) {
                return Container(
                  width: 70, padding: const EdgeInsets.symmetric(vertical: 12), alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: e == '5分钟' ? Colors.blue : const Color(0xFF1A203B),
                    borderRadius: BorderRadius.circular(8),
                    border: e == '5分钟' ? null : Border.all(color: Colors.white12),
                  ),
                  child: Text(e, style: TextStyle(color: e == '5分钟' ? Colors.white : Colors.white70, fontSize: 13)),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            Container(
              width: double.infinity, height: 140,
              decoration: BoxDecoration(color: const Color(0xFF1A203B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, color: Colors.white30, size: 40),
                  SizedBox(height: 8),
                  Text('尚未生成', style: TextStyle(color: Colors.white60)),
                  SizedBox(height: 16),
                  SizedBox(width: 150, height: 30, child: Center(child: Text('复制密码', style: TextStyle(color: Colors.white38, fontSize: 13))))
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B4BDB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: const Text('生成临时密码', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))), child: const Text('取消借车', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

// ================= 3. 设置页面 + 弹窗 (修复语法通配符错误) =================
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showPanelDialog(BuildContext context, ImageProvider bgImage, Widget content) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: Image(image: bgImage, fit: BoxFit.contain)),
              Padding(padding: const EdgeInsets.all(20.0), child: content),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text('设置', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Container(decoration: BoxDecoration(color: const Color(0xFF151A2E), borderRadius: BorderRadius.circular(12)), child: Column(
              children: [
                ListTile(leading: const Icon(Icons.bluetooth, color: Colors.white70), title: const Text('修改蓝牙密码', style: TextStyle(color: Colors.white)), trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14), onTap: () {
                  _showPanelDialog(context, const AssetImage('assets/popup_edit_pwd.png'),
                    Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white12)), child: const TextField(style: TextStyle(color: Colors.white), decoration: InputDecoration(border: InputBorder.none, hintText: '当前密码', hintStyle: TextStyle(color: Colors.white38)))),
                      Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white12)), child: const TextField(style: TextStyle(color: Colors.white), decoration: InputDecoration(border: InputBorder.none, hintText: '新密码', hintStyle: TextStyle(color: Colors.white38)))),
                      Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white12)), child: const TextField(style: TextStyle(color: Colors.white), decoration: InputDecoration(border: InputBorder.none, hintText: '确认新密码', hintStyle: TextStyle(color: Colors.white38)))),
                      Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10), alignment: Alignment.center, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(6)), child: const Text('保存新密码', style: TextStyle(color: Colors.white))),
                    ])
                  );
                }),
                const Divider(color: Colors.white10, height: 1),
                ListTile(leading: const Icon(Icons.autorenew, color: Colors.white70), title: const Text('恢复默认蓝牙密码', style: TextStyle(color: Colors.white)), trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14), onTap: () {
                  _showPanelDialog(context, const AssetImage('assets/popup_reset_pwd.png'),
                    Column(children: [
                      Spacer(),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('恢复后蓝牙密码将重置为出厂默认值', style: TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center)),
                      Spacer(),
                      Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10), alignment: Alignment.center, decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)), child: const Text('恢复默认蓝牙密码', style: TextStyle(color: Colors.white))),
                    ])
                  );
                }),
              ],
            )),
            const SizedBox(height: 16),
            Container(decoration: BoxDecoration(color: const Color(0xFF151A2E), borderRadius: BorderRadius.circular(12)), child: Column(
              children: [
                ListTile(leading: const Icon(Icons.sim_card, color: Colors.white70), title: const Text('设备名称', style: TextStyle(color: Colors.white)), trailing: Row(mainAxisSize: MainAxisSize.min, children: const [Text('陕A0P92Y', style: TextStyle(color: Colors.white38)), SizedBox(width: 8), Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14)]), onTap: () {
                  _showPanelDialog(context, const AssetImage('assets/popup_device_name.png'), Column(children: [
                    Spacer(),
                    const Padding(padding: EdgeInsets.all(8), child: Text('陕A0P92Y', style: TextStyle(color: Colors.white))),
                    Spacer(),
                    Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10), alignment: Alignment.center, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(6)), child: const Text('保存', style: TextStyle(color: Colors.white))),
                  ]));
                }),
                const Divider(color: Colors.white10, height: 1),
                ListTile(leading: const Icon(Icons.access_time, color: Colors.white70), title: const Text('时间同步设置', style: TextStyle(color: Colors.white)), trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14), onTap: () {
                  _showPanelDialog(context, const AssetImage('assets/popup_time_sync.png'), Column(children: [
                    Spacer(),
                    Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10), alignment: Alignment.center, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(6)), child: const Text('立即同步', style: TextStyle(color: Colors.white))),
                  ]));
                }),
                const Divider(color: Colors.white10, height: 1),
                ListTile(leading: const Icon(Icons.link, color: Colors.white70), title: const Text('自动连接设置', style: TextStyle(color: Colors.white)), trailing: Row(mainAxisSize: MainAxisSize.min, children: const [Text('关闭', style: TextStyle(color: Colors.white38)), SizedBox(width: 8), Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14)]), onTap: () {
                  _showPanelDialog(context, const AssetImage('assets/settings_auto_connect.png'), Column(children: [
                    Spacer(),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [Switch(value: true, onChanged: (v){}, activeColor: Colors.white)]),
                    Spacer(),
                  ]));
                }),
                const Divider(color: Colors.white10, height: 1),
                ListTile(leading: const Icon(Icons.volume_up, color: Colors.white70), title: const Text('提示音设置', style: TextStyle(color: Colors.white)), trailing: Row(mainAxisSize: MainAxisSize.min, children: const [Text('关闭', style: TextStyle(color: Colors.white38)), SizedBox(width: 8), Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14)]), onTap: () {
                  _showPanelDialog(context, const AssetImage('assets/popup_sound.png'), Column(children: [
                    Spacer(),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [Switch(value: false, onChanged: (v){}, activeColor: Colors.white)]),
                    Spacer(),
                  ]));
                }),
                const Divider(color: Colors.white10, height: 1),
                ListTile(leading: const Icon(Icons.info, color: Colors.white70), title: const Text('关于系统', style: TextStyle(color: Colors.white)), trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14), onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF151A2E),
                      title: const Center(child: Text('Tian Key', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('车型：马自达昂克赛拉', style: TextStyle(color: Colors.white70)),
                          SizedBox(height: 8),
                          Text('车牌：陕A0P92Y', style: TextStyle(color: Colors.white70)),
                          SizedBox(height: 8),
                          Text('设备：ESP32', style: TextStyle(color: Colors.white70)),
                          SizedBox(height: 8),
                          Text('状态：未连接设备', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭', style: TextStyle(color: Colors.blue)))],
                    ),
                  );
                }),
              ],
            )),
            const SizedBox(height: 40),
            Container(margin: const EdgeInsets.only(bottom: 20), width: 280, height: 70, child: Image.asset('assets/silver_wings.png', fit: BoxFit.contain)),
          ],
        ),
      ),
    );
  }
}
