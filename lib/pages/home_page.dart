import 'package:flutter/material.dart';
import '../services/mock_esp32.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MockESP32 _esp32 = MockESP32();

  bool _isScanning = false;
  bool _vehicleFound = false;
  bool _connecting = false;

  String _deviceStatus = '未连接';
  String _adminStatus = '未授权';
  String _timeStatus = '未同步';

  bool _canControl = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tian Key V11'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '车辆信息',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                '陕A0P92Y',
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                '当前状态',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _buildStatusRow('设备', _deviceStatus),
              _buildStatusRow('管理员', _adminStatus),
              _buildStatusRow('时间', _timeStatus),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isScanning ? null : _startBluetoothScan,
                  child: Text(
                    _isScanning ? '正在扫描……' : '蓝牙连接',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              if (_vehicleFound)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '发现车辆',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                '陕A0P92Y',
                                style: TextStyle(
                                  color: Colors.cyan,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed:
                              _connecting ? null : _showConnectionMode,
                          child: Text(
                            _connecting ? '连接中' : '连接',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 28),

              Text(
                _canControl ? '控制操作' : '控制操作（暂不可用）',
                style: TextStyle(
                  fontSize: 18,
                  color: _canControl ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildControlButton(
                    '锁车',
                    'suoche',
                  ),
                  _buildControlButton(
                    '解锁',
                    'jiesuo',
                  ),
                  _buildControlButton(
                    '寻车',
                    'xunche',
                  ),
                  _buildControlButton(
                    '升窗',
                    'chuangsheng',
                  ),
                  _buildControlButton(
                    '降窗',
                    'chuangjiang',
                  ),
                  _buildControlButton(
                    '后备箱',
                    'houbeixiang',
                  ),
                ],
              ),

              const SizedBox(height: 30),

              if (_esp32.logs.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '最近系统日志',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._esp32.logs.reversed.take(5).map(
                          (log) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              log,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label：',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    String text,
    String command,
  ) {
    return SizedBox(
      width: 150,
      child: ElevatedButton(
        onPressed: _canControl
            ? () => _executeVehicleCommand(command)
            : null,
        child: Text(text),
      ),
    );
  }

  Future<void> _startBluetoothScan() async {
    setState(() {
      _isScanning = true;
      _vehicleFound = false;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isScanning = false;
      _vehicleFound = true;
    });

    _esp32.addLog('APP扫描完成，发现陕A0P92Y');

    setState(() {});
  }

  Future<void> _showConnectionMode() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '请选择连接方式',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, 'admin');
                    },
                    child: const Text('管理员连接'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, 'temporary');
                    },
                    child: const Text('临时借车连接'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) return;

    if (result == 'admin') {
      await _adminLogin();
    } else {
      await _temporaryLogin();
    }
  }

  Future<void> _adminLogin() async {
    final controller = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('管理员连接'),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '管理员密码',
              hintText: '请输入管理员密码',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: const Text('验证'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted || password == null) return;

    setState(() {
      _connecting = true;
    });

    _esp32.addLog('APP发起管理员连接');

    await Future.delayed(const Duration(milliseconds: 800));

    final connected = _esp32.connect();

    if (!connected) {
      _showMessage('模拟 BLE 连接失败');
      setState(() {
        _connecting = false;
      });
      return;
    }

    final success = _esp32.verifyAdmin(password);

    if (!mounted) return;

    if (success) {
      setState(() {
        _deviceStatus = '已连接';
        _adminStatus = '已授权';
        _timeStatus = '已同步';
        _canControl = true;
        _connecting = false;
      });

      _showMessage('管理员认证成功');
    } else {
      setState(() {
        _deviceStatus = '连接失败';
        _adminStatus = '认证失败';
        _timeStatus = '未同步';
        _canControl = false;
        _connecting = false;
      });

      _showMessage('管理员密码错误');
    }
  }

  Future<void> _temporaryLogin() async {
    final controller = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('临时借车连接'),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: '临时借车密码',
              hintText: '请输入6位密码',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: const Text('验证'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted || password == null) return;

    _showMessage(
      '当前临时借车功能正在搭建完整授权流程，暂不直接放行。',
    );
  }

  void _executeVehicleCommand(String command) {
    final result = _esp32.executeCommand(command);

    _showMessage(result);

    setState(() {});
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
