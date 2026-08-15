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
  bool _loadingAuthorization = true;

  String _deviceStatus = '未连接';
  String _adminStatus = '未授权';
  String _timeStatus = '未同步';

  bool _canControl = false;

  @override
  void initState() {
    super.initState();
    _restoreAuthorization();
  }

  Future<void> _restoreAuthorization() async {
    await _esp32.loadSavedAuthorization();

    if (_esp32.sessionRole == 'admin') {
      await _esp32.autoReconnect();

      if (!mounted) return;

      setState(() {
        _deviceStatus = '已连接';
        _adminStatus = '已授权';
        _timeStatus = '已同步';
        _canControl = true;
        _vehicleFound = true;
        _loadingAuthorization = false;
      });

      return;
    }

    if (_esp32.sessionRole == 'temporary' &&
        _esp32.temporaryAuthorizationValid) {
      await _esp32.autoReconnect();

      if (!mounted) return;

      setState(() {
        _deviceStatus = '已连接';
        _adminStatus = '临时授权';
        _timeStatus = '已同步';
        _canControl = true;
        _vehicleFound = true;
        _loadingAuthorization = false;
      });

      return;
    }

    if (!mounted) return;

    setState(() {
      _loadingAuthorization = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        _esp32.sessionRole == 'admin';

    final isTemporary =
        _esp32.sessionRole == 'temporary';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tian Key V11'),
        centerTitle: true,
        actions: [
          if (_esp32.connected)
            IconButton(
              tooltip: '断开蓝牙',
              onPressed: _disconnectNormally,
              icon: const Icon(
                Icons.bluetooth_disabled,
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              if (_loadingAuthorization)
                const LinearProgressIndicator(),

              const SizedBox(height: 8),

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

              const SizedBox(height: 25),

              const Text(
                '当前状态',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              _buildStatusRow(
                '设备',
                _deviceStatus,
              ),

              _buildStatusRow(
                '管理员',
                _adminStatus,
              ),

              _buildStatusRow(
                '时间',
                _timeStatus,
              ),

              _buildStatusRow(
                '当前身份',
                isAdmin
                    ? '管理员'
                    : isTemporary
                        ? '临时借车'
                        : '未认证',
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _isScanning
                          ? null
                          : _startBluetoothScan,
                  icon: const Icon(
                    Icons.bluetooth,
                  ),
                  label: Text(
                    _isScanning
                        ? '正在扫描……'
                        : '蓝牙连接',
                  ),
                ),
              ),

              const SizedBox(height: 12),

              if (_vehicleFound)
                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                '发现车辆',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                height: 6,
                              ),
                              Text(
                                '陕A0P92Y',
                                style: TextStyle(
                                  color:
                                      Colors.cyan,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed:
                              _connecting
                                  ? null
                                  : _showConnectionMode,
                          child: Text(
                            _connecting
                                ? '连接中'
                                : '连接',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (isAdmin) ...[
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _showTemporaryAuthorization,
                    icon: const Icon(
                      Icons.key,
                    ),
                    label: const Text(
                      '临时借车管理',
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              Text(
                _canControl
                    ? '控制操作'
                    : '控制操作（暂不可用）',
                style: TextStyle(
                  fontSize: 18,
                  color: _canControl
                      ? Colors.white
                      : Colors.grey,
                  fontWeight:
                      FontWeight.bold,
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
                    padding:
                        const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        const Text(
                          '最近系统日志',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        ..._esp32.logs
                            .reversed
                            .take(8)
                            .map(
                          (log) => Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              bottom: 6,
                            ),
                            child: Text(
                              log,
                              style:
                                  const TextStyle(
                                color:
                                    Colors.grey,
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

  Widget _buildStatusRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          Text(
            '$label：',
            style:
                const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style:
                const TextStyle(
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
        onPressed:
            _canControl
                ? () =>
                    _executeVehicleCommand(
                      command,
                    )
                : null,
        child: Text(text),
      ),
    );
  }

  Future<void>
      _startBluetoothScan() async {
    setState(() {
      _isScanning = true;
      _vehicleFound = false;
    });

    _esp32.addLog(
      'APP开始扫描BLE设备',
    );

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    _esp32.addLog(
      'APP扫描完成，发现陕A0P92Y',
    );

    setState(() {
      _isScanning = false;
      _vehicleFound = true;
    });
  }

  Future<void>
      _showConnectionMode() async {
    final result =
        await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(20),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Text(
                  '请选择连接方式',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        'admin',
                      );
                    },
                    child: const Text(
                      '管理员连接',
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        'temporary',
                      );
                    },
                    child: const Text(
                      '临时借车连接',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    if (result == 'admin') {
      await _adminLogin();
    } else {
      await _temporaryLogin();
    }
  }

  Future<void> _adminLogin() async {
    final controller =
        TextEditingController();

    final password =
        await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text('管理员连接'),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            keyboardType:
                TextInputType.number,
            decoration:
                const InputDecoration(
              labelText: '管理员密码',
              hintText:
                  '请输入管理员密码',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
                  const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  controller.text,
                );
              },
              child:
                  const Text('验证'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted || password == null) {
      return;
    }

    setState(() {
      _connecting = true;
    });

    _esp32.addLog(
      'APP发起管理员连接',
    );

    await Future.delayed(
      const Duration(
        milliseconds: 800,
      ),
    );

    _esp32.connect();

    final success =
        await _esp32.verifyAdmin(
      password,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _deviceStatus = '已连接';
        _adminStatus = '已授权';
        _timeStatus = '已同步';
        _canControl = true;
        _connecting = false;
        _vehicleFound = true;
      });

      _showMessage(
        '管理员认证成功',
      );
    } else {
      setState(() {
        _deviceStatus = '已连接';
        _adminStatus = '认证失败';
        _timeStatus = '未同步';
        _canControl = false;
        _connecting = false;
      });

      _showMessage(
        '管理员密码错误',
      );
    }
  }

  Future<void> _temporaryLogin() async {
    final controller =
        TextEditingController();

    final password =
        await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text('临时借车连接'),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            keyboardType:
                TextInputType.number,
            maxLength: 6,
            decoration:
                const InputDecoration(
              labelText:
                  '临时借车密码',
              hintText:
                  '请输入6位密码',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
                  const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  controller.text,
                );
              },
              child:
                  const Text('验证'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted || password == null) {
      return;
    }

    setState(() {
      _connecting = true;
    });

    _esp32.addLog(
      'APP发起临时借车连接',
    );

    await Future.delayed(
      const Duration(
        milliseconds: 800,
      ),
    );

    _esp32.connect();

    final success =
        await _esp32
            .verifyTemporaryUser(
      password,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _deviceStatus = '已连接';
        _adminStatus = '临时授权';
        _timeStatus = '已同步';
        _canControl = true;
        _connecting = false;
        _vehicleFound = true;
      });

      _showMessage(
        '临时借车认证成功',
      );
    } else {
      setState(() {
        _deviceStatus = '已连接';
        _adminStatus =
            '临时授权失败';
        _timeStatus = '未同步';
        _canControl = false;
        _connecting = false;
      });

      _showMessage(
        '临时借车密码错误或已过期',
      );
    }
  }

  Future<void>
      _showTemporaryAuthorization()
          async {
    final password =
        await _esp32
            .generateTemporaryPassword(
      validity:
          const Duration(hours: 24),
    );

    final end =
        _esp32.temporaryEnd;

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            '临时借车授权',
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              const Text(
                '临时密码',
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                password,
                style:
                    const TextStyle(
                  fontSize: 28,
                  color:
                      Colors.cyan,
                  fontWeight:
                      FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                '有效期至：\n'
                '${end?.toString() ?? ''}',
              ),
              const SizedBox(
                height: 10,
              ),
              const Text(
                '当前模拟有效期：24小时',
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
                  const Text('完成'),
            ),
          ],
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _disconnectNormally() {
    _esp32.disconnect();

    setState(() {
      _deviceStatus = '未连接';
      _adminStatus = '未授权';
      _timeStatus = '未同步';
      _canControl = false;
      _connecting = false;
      _vehicleFound = false;
    });

    _showMessage(
      '蓝牙已断开',
    );
  }

  void _executeVehicleCommand(
    String command,
  ) {
    final result =
        _esp32.executeCommand(
      command,
    );

    _showMessage(result);

    setState(() {});
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),
      ),
    );
  }
}
