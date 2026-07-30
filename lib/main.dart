import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        scaffoldBackgroundColor: const Color(0xFF030712),
        primaryColor: const Color(0xFF00E5FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF0066CC),
          surface: Color(0xFF080F1D),
        ),
      ),
      home: const AppSliderMainScreen(),
    );
  }
}

// ==========================================
// 全局状态单例（支持9个滑动页面实时联动）
// ==========================================
class AppState extends ChangeNotifier {
  static final AppState instance = AppState._internal();
  factory AppState() => instance;
  AppState._internal();

  bool isConnected = false;
  bool isAuthorized = false;
  bool isTimeSynced = false;
  bool autoConnect = true;
  bool soundEffects = true;
  String deviceName = '陕A0P92Y';
  String blePassword = '******';
  
  // 临时密码状态
  String tempPassword = '尚未生成';
  bool hasTempPassword = false;
  String selectedDuration = '5分钟';

  void toggleConnection() {
    isConnected = !isConnected;
    notifyListeners();
  }

  void setAuthorized(bool val) {
    isAuthorized = val;
    notifyListeners();
  }

  void setTimeSynced(bool val) {
    isTimeSynced = val;
    notifyListeners();
  }

  void setDeviceName(String name) {
    deviceName = name;
    notifyListeners();
  }

  void setBlePassword(String pass) {
    blePassword = pass;
    notifyListeners();
  }

  void generateNewTempPassword(String duration) {
    selectedDuration = duration;
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = math.Random();
    tempPassword = List.generate(6, (index) => chars[rnd.nextInt(chars.length)]).join();
    hasTempPassword = true;
    notifyListeners();
  }

  void cancelTempPassword() {
    tempPassword = '尚未生成';
    hasTempPassword = false;
    notifyListeners();
  }
}

// ==========================================
// 核心9页滑动主容器 (PageView + 底部/顶部控制器)
// ==========================================
class AppSliderMainScreen extends StatefulWidget {
  const AppSliderMainScreen({super.key});

  @override
  State<AppSliderMainScreen> createState() => _AppSliderMainScreenState();
}

class _AppSliderMainScreenState extends State<AppSliderMainScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _pageTitles = [
    '1. 主控制台',
    '2. 临时借车密码',
    '3. 设置主页',
    '4. 管理员授权',
    '5. 修改蓝牙密码',
    '6. 恢复默认密码',
    '7. 修改设备名称',
    '8. 时间同步校准',
    '9. 关于系统硬件',
  ];

  void _animateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部滑动提示与页面快速切换指示器
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF080F1D),
                border: Border(bottom: BorderSide(color: Color(0xFF16253B), width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.swipe_outlined, color: Color(0xFF00E5FF), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _pageTitles[_currentPage],
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00E5FF), width: 1),
                    ),
                    child: Text(
                      '${_currentPage + 1} / 9 页 (可左右滑动)',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // 9页连续滑动 PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  Page1Home(onNavigate: _animateToPage),
                  Page2TempBorrow(onNavigate: _animateToPage),
                  Page3SettingsList(onNavigate: _animateToPage),
                  Page4AdminAuth(onNavigate: _animateToPage),
                  Page5ChangeBlePass(onNavigate: _animateToPage),
                  Page6ResetBlePass(onNavigate: _animateToPage),
                  Page7DeviceName(onNavigate: _animateToPage),
                  Page8TimeSync(onNavigate: _animateToPage),
                  Page9AboutSystem(onNavigate: _animateToPage),
                ],
              ),
            ),
          ],
        ),
      ),

      // 底部常驻导航栏（点击自动滑动到对应页面）
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF070D18),
          border: Border(top: BorderSide(color: Color(0xFF16253B), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentPage > 2 ? 2 : _currentPage,
          onTap: (index) {
            _animateToPage(index);
          },
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF00E5FF),
          unselectedItemColor: const Color(0xFF5A6E85),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '首页(1)'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: '临时借车(2)'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: '设置(3-9)'),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 通用弹窗与 Toast 提示
// ==========================================
void showAppToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF0A182E),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF00E5FF), width: 1),
      ),
    ),
  );
}

// ==========================================
// 页面 1：首页（控制台与8个切片按键）
// ==========================================
class Page1Home extends StatelessWidget {
  final Function(int) onNavigate;
  const Page1Home({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            children: [
              // 顶部 App 标题栏
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Color(0xFF00E5FF), size: 22),
                    onPressed: () => onNavigate(2), // 跳转设置
                  ),
                  const Text(
                    'Tian Key',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Color(0xFF00E5FF), blurRadius: 12),
                        Shadow(color: Colors.blueAccent, blurRadius: 6),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF00E5FF), size: 22),
                    onPressed: () => onNavigate(8), // 跳转关于
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // 车图区域 (调用切片 1.png)
              Container(
                height: 185,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5), width: 1.2),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.15), blurRadius: 10)
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        '1.png',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              colors: [Color(0xFF0A2240), Color(0xFF030712)],
                              radius: 0.9,
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.directions_car_filled, size: 90, color: Colors.redAccent),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0033A0),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Text(
                            state.deviceName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 5 项状态栏
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF080F1D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF182840), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatusItem('设备状态', state.isConnected ? '已连接' : '未连接', Icons.bluetooth),
                    _buildStatusItem('管理员状态', state.isAuthorized ? '已授权' : '未授权', Icons.shield_outlined),
                    _buildStatusItem('供电状态', '正常', Icons.flash_on),
                    _buildStatusItem('时间同步', state.isTimeSynced ? '已同步' : '未同步', Icons.access_time),
                    _buildStatusItem('临时借车', state.hasTempPassword ? '已生效' : '无有效密码', Icons.key_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 8 个赛博朋克控制按钮 (支持 GitHub 切片 2.png ~ 10.png)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.35,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildCyberButton(
                    '连接设备',
                    Icons.bluetooth,
                    const Color(0xFF00E5FF),
                    '2.png',
                    () {
                      state.toggleConnection();
                      showAppToast(context, state.isConnected ? '蓝牙设备连接成功！' : '蓝牙设备已断开连接');
                    },
                  ),
                  _buildCyberButton(
                    '管理员授权',
                    Icons.verified_user,
                    const Color(0xFFFF9100),
                    '3.png',
                    () => onNavigate(3), // 滑动到第4页授权页
                  ),
                  _buildCyberButton('锁车', Icons.lock, const Color(0xFF0088FF), '4.png', () {
                    showAppToast(context, '指令已下发：车辆已加锁');
                  }),
                  _buildCyberButton('解锁', Icons.lock_open, const Color(0xFF0088FF), '5.png', () {
                    showAppToast(context, '指令已下发：车辆已解锁');
                  }),
                  _buildCyberButton('车窗升', Icons.keyboard_double_arrow_up, const Color(0xFFFF9100), '7.png', () {
                    showAppToast(context, '指令已下发：四门车窗升起');
                  }),
                  _buildCyberButton('车窗降', Icons.keyboard_double_arrow_down, const Color(0xFFFF9100), '8.png', () {
                    showAppToast(context, '指令已下发：四门车窗下降');
                  }),
                  _buildCyberButton('寻车', Icons.cell_tower, const Color(0xFF0088FF), '9.png', () {
                    showAppToast(context, '寻车指令发送：车辆蜂鸣闪烁');
                  }),
                  _buildCyberButton('后备箱', Icons.minor_crash, const Color(0xFF0088FF), '10.png', () {
                    showAppToast(context, '指令已下发：后备箱开启');
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusItem(String label, String val, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF00E5FF)),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCyberButton(String title, IconData icon, Color themeColor, String sliceImg, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: themeColor.withOpacity(0.4),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF070F1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: themeColor.withOpacity(0.85), width: 1.2),
            boxShadow: [
              BoxShadow(color: themeColor.withOpacity(0.2), blurRadius: 6),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    sliceImg,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: themeColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 页面 2：临时借车（真实动态随机密码）
// ==========================================
class Page2TempBorrow extends StatefulWidget {
  final Function(int) onNavigate;
  const Page2TempBorrow({super.key, required this.onNavigate});

  @override
  State<Page2TempBorrow> createState() => _Page2TempBorrowState();
}

class _Page2TempBorrowState extends State<Page2TempBorrow> {
  String _selectedDuration = '5分钟';
  final List<String> _durations = ['5分钟', '1天', '2天', '3天', '4天', '5天', '6天', '7天'];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('临时借车授权', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Color(0xFF00E5FF), size: 18),
                    onPressed: () => widget.onNavigate(2),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 当前状态提示
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF080F1D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF182840)),
                ),
                child: Row(
                  children: [
                    Icon(
                      state.hasTempPassword ? Icons.vpn_key : Icons.vpn_key_outlined,
                      color: state.hasTempPassword ? const Color(0xFF00E5FF) : Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.hasTempPassword ? '当前状态：临时密码生效中 (${state.selectedDuration})' : '当前状态：无有效临时密码',
                        style: TextStyle(color: state.hasTempPassword ? const Color(0xFF00E5FF) : Colors.grey, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text('选择有效时间范围', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 10),

              // 8个不同有效时长的可按选项
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _durations.map((d) {
                  final isSel = _selectedDuration == d;
                  return InkWell(
                    onTap: () => setState(() => _selectedDuration = d),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: (MediaQuery.of(context).size.width - 32 - 24) / 4,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF0A3054) : const Color(0xFF080F1D),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isSel ? const Color(0xFF00E5FF) : const Color(0xFF182840)),
                      ),
                      child: Text(d, style: TextStyle(color: isSel ? const Color(0xFF00E5FF) : Colors.white, fontSize: 13)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 动态生成密码展示框
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF080F1D),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: state.hasTempPassword ? const Color(0xFF00E5FF) : const Color(0xFF182840)),
                  boxShadow: state.hasTempPassword ? [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.15), blurRadius: 10)] : [],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock_clock_outlined, size: 36, color: Color(0xFF00E5FF)),
                    const SizedBox(height: 8),
                    Text(
                      state.tempPassword,
                      style: TextStyle(
                        color: state.hasTempPassword ? const Color(0xFF00E5FF) : Colors.white60,
                        fontSize: state.hasTempPassword ? 28 : 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: state.hasTempPassword ? 5 : 0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: state.hasTempPassword
                          ? () {
                              Clipboard.setData(ClipboardData(text: state.tempPassword));
                              showAppToast(context, '密码 [${state.tempPassword}] 已复制到剪贴板！');
                            }
                          : null,
                      icon: const Icon(Icons.copy, size: 15),
                      label: const Text('一键复制密码'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: state.hasTempPassword ? const Color(0xFF00E5FF) : Colors.grey,
                        side: BorderSide(color: state.hasTempPassword ? const Color(0xFF00E5FF) : Colors.grey.shade800),
                      ),
                    )
                  ],
                ),
              ),
              const Spacer(),

              // 生成与取消按钮
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  state.generateNewTempPassword(_selectedDuration);
                  showAppToast(context, '已生成全新随机密码：${state.tempPassword}');
                },
                child: const Text('生成随机临时密码', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  state.cancelTempPassword();
                  showAppToast(context, '临时借车授权已重置取消');
                },
                child: const Text('取消授权', style: TextStyle(color: Colors.redAccent, fontSize: 15)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// 页面 3：设置主列表（平滑跳转到子页面）
// ==========================================
class Page3SettingsList extends StatelessWidget {
  final Function(int) onNavigate;
  const Page3SettingsList({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('系统设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 15),
            _buildTile('修改蓝牙密码', Icons.bluetooth, () => onNavigate(4)),
            _buildTile('恢复默认蓝牙密码', Icons.refresh, () => onNavigate(5)),
            _buildTile('设备名称', Icons.phone_android, () => onNavigate(6), trailingText: state.deviceName),
            _buildTile('时间同步设置', Icons.access_time, () => onNavigate(7), trailingText: state.isTimeSynced ? '已同步' : '未同步'),
            _buildTile('自动连接设置', Icons.link, () {
              state.autoConnect = !state.autoConnect;
              state.notifyListeners();
              showAppToast(context, state.autoConnect ? '自动连接已开启' : '自动连接已关闭');
            }, trailingText: state.autoConnect ? '开启' : '关闭'),
            _buildTile('提示音设置', Icons.volume_up, () {
              state.soundEffects = !state.soundEffects;
              state.notifyListeners();
              showAppToast(context, state.soundEffects ? '按键提示音已开启' : '按键提示音已关闭');
            }, trailingText: state.soundEffects ? '开启' : '关闭'),
            _buildTile('关于系统', Icons.info_outline, () => onNavigate(8)),
          ],
        );
      },
    );
  }

  Widget _buildTile(String title, IconData icon, VoidCallback onTap, {String? trailingText}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF080F1D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF142236)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00E5FF), size: 20),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null) Text(trailingText, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

// ==========================================
// 页面 4：管理员授权
// ==========================================
class Page4AdminAuth extends StatefulWidget {
  final Function(int) onNavigate;
  const Page4AdminAuth({super.key, required this.onNavigate});

  @override
  State<Page4AdminAuth> createState() => _Page4AdminAuthState();
}

class _Page4AdminAuthState extends State<Page4AdminAuth> {
  final _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return _SubPageWrapper(
      title: '管理员授权',
      onBack: () => widget.onNavigate(0), // 返回首页
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.shield, size: 80, color: Colors.amber),
          const SizedBox(height: 15),
          const Text('请输入管理员专属密码解锁高阶功能', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 25),
          TextField(
            controller: _passController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: '管理员密码',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline, color: Colors.amber),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[800],
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () {
              if (_passController.text.isNotEmpty) {
                AppState.instance.setAuthorized(true);
                showAppToast(context, '管理员授权校验成功！');
                widget.onNavigate(0);
              } else {
                showAppToast(context, '请输入授权密码');
              }
            },
            child: const Text('确认授权', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 页面 5：修改蓝牙密码
// ==========================================
class Page5ChangeBlePass extends StatefulWidget {
  final Function(int) onNavigate;
  const Page5ChangeBlePass({super.key, required this.onNavigate});

  @override
  State<Page5ChangeBlePass> createState() => _Page5ChangeBlePassState();
}

class _Page5ChangeBlePassState extends State<Page5ChangeBlePass> {
  final _oldPass = TextEditingController();
  final _newPass = TextEditingController();
  final _confirmPass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return _SubPageWrapper(
      title: '修改蓝牙密码',
      onBack: () => widget.onNavigate(2), // 返回设置
      child: Column(
        children: [
          TextField(controller: _oldPass, obscureText: true, decoration: const InputDecoration(labelText: '当前蓝牙密码', border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _newPass, obscureText: true, decoration: const InputDecoration(labelText: '新蓝牙密码', border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _confirmPass, obscureText: true, decoration: const InputDecoration(labelText: '确认新密码', border: OutlineInputBorder())),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066CC), minimumSize: const Size(double.infinity, 48)),
            onPressed: () {
              if (_newPass.text == _confirmPass.text && _newPass.text.isNotEmpty) {
                AppState.instance.setBlePassword(_newPass.text);
                showAppToast(context, '新蓝牙密码保存成功！');
                widget.onNavigate(2);
              } else {
                showAppToast(context, '两次输入的新密码不一致或为空');
              }
            },
            child: const Text('保存新密码', style: TextStyle(color: Colors.white, fontSize: 15)),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 页面 6：恢复默认蓝牙密码
// ==========================================
class Page6ResetBlePass extends StatelessWidget {
  final Function(int) onNavigate;
  const Page6ResetBlePass({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return _SubPageWrapper(
      title: '恢复默认蓝牙密码',
      onBack: () => onNavigate(2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.refresh_rounded, size: 80, color: Color(0xFF00E5FF)),
          const SizedBox(height: 20),
          const Text('恢复后蓝牙密码将重置为出厂默认值 [123456]', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 48)),
            onPressed: () {
              AppState.instance.setBlePassword('123456');
              showAppToast(context, '已恢复出厂默认蓝牙密码');
              onNavigate(2);
            },
            child: const Text('确认恢复默认密码', style: TextStyle(color: Colors.white, fontSize: 15)),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 页面 7：设备名称设置
// ==========================================
class Page7DeviceName extends StatefulWidget {
  final Function(int) onNavigate;
  const Page7DeviceName({super.key, required this.onNavigate});

  @override
  State<Page7DeviceName> createState() => _Page7DeviceNameState();
}

class _Page7DeviceNameState extends State<Page7DeviceName> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: AppState.instance.deviceName);
  }

  @override
  Widget build(BuildContext context) {
    return _SubPageWrapper(
      title: '设备名称',
      onBack: () => widget.onNavigate(2),
      child: Column(
        children: [
          TextField(controller: _controller, decoration: const InputDecoration(labelText: '设备名称', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('此名称将显示在主界面卡片及蓝牙识别名称中', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066CC), minimumSize: const Size(double.infinity, 48)),
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                AppState.instance.setDeviceName(_controller.text);
                showAppToast(context, '设备名称更新成功');
                widget.onNavigate(2);
              }
            },
            child: const Text('保存', style: TextStyle(color: Colors.white, fontSize: 15)),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 页面 8：时间同步设置
// ==========================================
class Page8TimeSync extends StatelessWidget {
  final Function(int) onNavigate;
  const Page8TimeSync({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        return _SubPageWrapper(
          title: '时间同步设置',
          onBack: () => onNavigate(2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.access_time_filled, size: 80, color: Color(0xFF00E5FF)),
              const SizedBox(height: 20),
              Text(
                state.isTimeSynced ? '当前状态：已与系统时间同步' : '当前状态：未同步',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('点击下方按钮同步当前手机系统时间至 ESP32 钥匙设备', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066CC), minimumSize: const Size(double.infinity, 48)),
                onPressed: () {
                  state.setTimeSynced(true);
                  showAppToast(context, '时间与设备精准校准成功！');
                },
                child: const Text('立即同步时间', style: TextStyle(color: Colors.white, fontSize: 15)),
              )
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// 页面 9：关于系统
// ==========================================
class Page9AboutSystem extends StatelessWidget {
  final Function(int) onNavigate;
  const Page9AboutSystem({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        return _SubPageWrapper(
          title: '关于系统',
          onBack: () => onNavigate(2),
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Icon(Icons.shield_moon_outlined, size: 70, color: Color(0xFF00E5FF)),
              const SizedBox(height: 10),
              const Text(
                'Tian Key',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
              ),
              const SizedBox(height: 25),
              _buildRow('车型', '马自达昂克赛拉'),
              _buildRow('车牌', state.deviceName),
              _buildRow('硬件芯片', 'ESP32_BLE_KEY'),
              _buildRow('蓝牙状态', state.isConnected ? '已连接' : '未连接'),
              _buildRow('系统版本', 'v1.0.0 Cyberpunk Edition'),
              const Spacer(),
              const Text('Tian Key 智能数字钥匙系统 © 2026', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF142236))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ==========================================
// 通用子页面外壳组件（带返回按钮）
// ==========================================
class _SubPageWrapper extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget child;

  const _SubPageWrapper({
    required this.title,
    required this.onBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF00E5FF), size: 20),
                onPressed: onBack,
              ),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}
