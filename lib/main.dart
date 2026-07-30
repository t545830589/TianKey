import 'package:flutter/material.dart';

void main() {
  runApp(const TianKeyApp());
}

class TianKeyApp extends StatelessWidget {
  const TianKeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tian Key',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF060810),
        primaryColor: const Color(0xFF00E5FF),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  bool isConnected = false;
  bool isAuthorized = false;
  bool autoConnect = false;
  bool soundEffect = false;
  String selectedDuration = '5分钟';
  String tempPassword = '尚未生成';

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      buildHomePage(context),
      buildTempBorrowPage(context),
      buildSettingsPage(context),
    ];

    return Scaffold(
      body: SafeArea(
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0C101D),
          border: Border(top: BorderSide(color: Color(0xFF1E2D4A), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF00E5FF),
          unselectedItemColor: Colors.grey,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '首页'),
            BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: '临时借车'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: '设置'),
          ],
        ),
      ),
    );
  }

  // 安全图片加载组件
  Widget buildAssetImage(String fileName, {double? height, double? width, Widget? fallbackIcon}) {
    return Image.asset(
      fileName,
      height: height,
      width: width,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return fallbackIcon ?? const Icon(Icons.directions_car, size: 80, color: Colors.cyanAccent);
      },
    );
  }

  // ================= 1. 首页 =================
  Widget buildHomePage(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.cyanAccent),
                onPressed: () => setState(() => _currentIndex = 2),
              ),
              const Text(
                'Tian Key',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.cyan, blurRadius: 10)],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.cyanAccent),
                onPressed: () => openPage(context, buildAboutPage(context)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 汽车展示卡片
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const RadialGradient(
                colors: [Color(0xFF152A4A), Color(0xFF080C16)],
                radius: 0.85,
              ),
              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3), width: 1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 25,
                  child: Container(
                    width: 260,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.elliptical(260, 70)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.35),
                          blurRadius: 35,
                          spreadRadius: 8,
                        )
                      ],
                    ),
                  ),
                ),

                // 渲染上传的车辆图片 1.png
                Positioned(
                  top: 10,
                  bottom: 35,
                  child: buildAssetImage('1.png', height: 140),
                ),

                Positioned(
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003399),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Text(
                      '陕A0P92Y',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1424),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                buildStatusItem('设备状态', isConnected ? '已连接' : '未连接', Icons.bluetooth_disabled),
                buildStatusItem('管理员状态', isAuthorized ? '已授权' : '未授权', Icons.cancel_outlined),
                buildStatusItem('供电状态', '未知', Icons.flash_on),
                buildStatusItem('时间同步', '未同步', Icons.access_time),
                buildStatusItem('临时借车', '无有效密码', Icons.key_off),
              ],
            ),
          ),
          const SizedBox(height: 15),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              buildCyberButton('连接设备', Icons.bluetooth, const Color(0xFF00E5FF), () {
                showToast(context, '正在搜索设备 陕A0P92Y...');
              }),
              buildCyberButton('管理员授权', Icons.verified_user, const Color(0xFFFF9100), () {
                openPage(context, buildAdminAuthPage(context));
              }),
              buildCyberButton('锁车', Icons.lock, const Color(0xFF0088FF), () {
                showToast(context, '发送指令: suoche');
              }),
              buildCyberButton('解锁', Icons.lock_open, const Color(0xFF0088FF), () {
                showToast(context, '发送指令: jiesuo');
              }),
              buildCyberButton('车窗升', Icons.keyboard_double_arrow_up, const Color(0xFFFF9100), () {
                showToast(context, '发送指令: chuangsheng');
              }),
              buildCyberButton('车窗降', Icons.keyboard_double_arrow_down, const Color(0xFFFF9100), () {
                showToast(context, '发送指令: chuangjiang');
              }),
              buildCyberButton('寻车', Icons.cell_tower, const Color(0xFF0088FF), () {
                showToast(context, '发送指令: xunche');
              }),
              buildCyberButton('后备箱', Icons.minor_crash, const Color(0xFF0088FF), () {
                showToast(context, '发送指令: houbeixiang');
              }),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 2. 临时借车页 =================
  Widget buildTempBorrowPage(BuildContext context) {
    final durations = ['5分钟', '1天', '2天', '3天', '4天', '5天', '6天', '7天'];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('临时借车', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          buildCardBox(
            child: Row(
              children: const [
                Icon(Icons.vpn_key_outlined, color: Colors.grey),
                SizedBox(width: 10),
                Text('当前状态：无有效临时密码', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('选择有效时间', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: durations.map((d) {
              final isSel = selectedDuration == d;
              return GestureDetector(
                onTap: () => setState(() => selectedDuration = d),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF005588) : const Color(0xFF0E1424),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSel ? Colors.cyanAccent : Colors.white10),
                  ),
                  child: Text(d, style: TextStyle(color: isSel ? Colors.cyanAccent : Colors.white)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          buildCardBox(
            child: Column(
              children: [
                const Icon(Icons.lock_outline, size: 30, color: Colors.grey),
                const SizedBox(height: 5),
                Text(tempPassword, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => showToast(context, '未生成密码'),
                  icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                  label: const Text('复制密码', style: TextStyle(color: Colors.grey)),
                )
              ],
            ),
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077FF),
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () {
              setState(() {
                tempPassword = '临时密码: A8F2K7 ($selectedDuration)';
              });
              showToast(context, '临时密码生成成功！');
            },
            child: const Text('生成临时密码', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () {
              setState(() {
                tempPassword = '尚未生成';
              });
              showToast(context, '已取消借车');
            },
            child: const Text('取消借车', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // ================= 3. 设置页 =================
  Widget buildSettingsPage(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 15),
        buildSettingTile('修改蓝牙密码', Icons.bluetooth, () {
          openPage(context, buildChangeBlePasswordPage(context));
        }),
        buildSettingTile('恢复默认蓝牙密码', Icons.refresh, () {
          openPage(context, buildResetBlePasswordPage(context));
        }),
        buildSettingTile('设备名称', Icons.phone_android, () {
          openPage(context, buildDeviceNamePage(context));
        }, trailingText: '陕A0P92Y'),
        buildSettingTile('时间同步设置', Icons.access_time, () {
          openPage(context, buildTimeSyncPage(context));
        }),
        SwitchListTile(
          title: const Text('自动连接设置', style: TextStyle(color: Colors.white)),
          subtitle: const Text('开启后，APP启动时自动连接已配对设备', style: TextStyle(color: Colors.grey, fontSize: 12)),
          value: autoConnect,
          activeColor: Colors.cyanAccent,
          onChanged: (v) => setState(() => autoConnect = v),
        ),
        SwitchListTile(
          title: const Text('提示音设置', style: TextStyle(color: Colors.white)),
          subtitle: const Text('开启后，操作时将播放提示音', style: TextStyle(color: Colors.grey, fontSize: 12)),
          value: soundEffect,
          activeColor: Colors.cyanAccent,
          onChanged: (v) => setState(() => soundEffect = v),
        ),
        buildSettingTile('关于系统', Icons.info_outline, () {
          openPage(context, buildAboutPage(context));
        }),
      ],
    );
  }

  Widget buildAdminAuthPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('管理员授权'), backgroundColor: const Color(0xFF060810)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.shield, size: 80, color: Colors.amber),
            const SizedBox(height: 15),
            const Text('请输入管理员密码进行授权', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: '管理员密码',
                hintText: '请输入管理员密码',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[800],
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                setState(() => isAuthorized = true);
                Navigator.pop(context);
                showToast(context, '授权成功！');
              },
              child: const Text('确认授权', style: TextStyle(color: Colors.white, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  Widget buildChangeBlePasswordPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('修改蓝牙密码'), backgroundColor: const Color(0xFF060810)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const TextField(obscureText: true, decoration: InputDecoration(labelText: '当前蓝牙密码', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            const TextField(obscureText: true, decoration: InputDecoration(labelText: '新蓝牙密码', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            const TextField(obscureText: true, decoration: InputDecoration(labelText: '确认新密码', border: OutlineInputBorder())),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077FF),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                Navigator.pop(context);
                showToast(context, '新蓝牙密码保存成功！');
              },
              child: const Text('保存新密码', style: TextStyle(color: Colors.white, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  Widget buildResetBlePasswordPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('恢复默认蓝牙密码'), backgroundColor: const Color(0xFF060810)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.refresh, size: 80, color: Colors.cyanAccent),
            const SizedBox(height: 20),
            const Text('恢复后蓝牙密码将重置为出厂默认值', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                Navigator.pop(context);
                showToast(context, '已恢复默认蓝牙密码');
              },
              child: const Text('恢复默认蓝牙密码', style: TextStyle(color: Colors.white, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  Widget buildDeviceNamePage(BuildContext context) {
    final controller = TextEditingController(text: '陕A0P92Y');
    return Scaffold(
      appBar: AppBar(title: const Text('设备名称'), backgroundColor: const Color(0xFF060810)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: '设备名称', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('设备名称用于蓝牙搜索和设备识别', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077FF),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                Navigator.pop(context);
                showToast(context, '修改保存成功');
              },
              child: const Text('保存', style: TextStyle(color: Colors.white, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  Widget buildTimeSyncPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('时间同步设置'), backgroundColor: const Color(0xFF060810)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text('当前状态：未同步', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077FF),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                Navigator.pop(context);
                showToast(context, '时间同步成功！');
              },
              child: const Text('立即同步', style: TextStyle(color: Colors.white, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  // 关于页面（使用 2.png）
  Widget buildAboutPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于系统'), backgroundColor: const Color(0xFF060810)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            buildAssetImage('2.png', height: 90),
            const SizedBox(height: 10),
            const Text('Tian Key', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 30),
            buildInfoRow('车型', '马自达昂克赛拉'),
            buildInfoRow('车牌', '陕A0P92Y'),
            buildInfoRow('设备', 'ESP32'),
            buildInfoRow('设备状态', '未连接设备'),
            const Spacer(),
            const Text('Tian Key 智能车钥匙控制系统', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildStatusItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }

  Widget buildCyberButton(String title, IconData icon, Color glowColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1526),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: glowColor.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(color: glowColor.withOpacity(0.15), blurRadius: 8, spreadRadius: 1),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: glowColor, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget buildSettingTile(String title, IconData icon, VoidCallback onTap, {String? trailingText}) {
    return ListTile(
      leading: Icon(icon, color: Colors.cyanAccent),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) Text(trailingText, style: const TextStyle(color: Colors.grey)),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget buildCardBox({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1424),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget buildInfoRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void openPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void showToast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }
}
