import 'package:flutter/material.dart';

import '../services/mock_esp32.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage> {
  final MockESP32 _esp32 =
      MockESP32();

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
      final success =
          await _esp32.autoReconnect();

      if (!mounted) return;

      if (success) {
        setState(() {
          _deviceStatus = '已连接';
          _adminStatus = '已授权';
          _timeStatus = '已同步';
          _canControl = true;
          _vehicleFound = true;
          _loadingAuthorization = false;
        });
      } else {
        setState(() {
          _deviceStatus = '未连接';
          _adminStatus = '授权失效';
          _timeStatus = '未同步';
          _canControl = false;
          _loadingAuthorization = false;
        });
      }

      return;
    }

    if (_esp32.sessionRole == 'temporary') {
      final success =
          await _esp32.autoReconnect();

      if (!mounted) return;

      if (success) {
        setState(() {
          _deviceStatus = '已连接';
          _adminStatus = '临时授权';
          _timeStatus = '已同步';
          _canControl = true;
          _vehicleFound = true;
          _loadingAuthorization = false;
        });
      } else {
        setState(() {
          _deviceStatus = '未连接';
          _adminStatus = '临时授权失效';
          _timeStatus = '未同步';
          _canControl = false;
          _loadingAuthorization = false;
        });
      }

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
                  onPressed: _isScanning
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
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '发现车辆',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold,
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
                          onPressed: _connecting
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
                    icon: const Icon(Icons.key),
                    label: const Text(
                      '临时借车管理',
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                _buildTemporaryAuthorizationCard(),

                const SizedBox(height: 15),

                _buildAdminSeatPanel(),
              ],

              if (isTemporary) ...[
                const SizedBox(height: 15),
                _buildTemporaryUserCard(),
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
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildControlButton('锁车', 'suoche'),
                  _buildControlButton('解锁', 'jiesuo'),
                  _buildControlButton('寻车', 'xunche'),
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

              _buildSimulationTestPanel(),

              const SizedBox(height: 30),

              if (_esp32.logs.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '最近系统日志',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._esp32.logs.reversed
                            .take(12)
                            .map(
                              (log) => Padding(
                                padding:
                                    const EdgeInsets.only(
                                  bottom: 6,
                                ),
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

  Widget _buildStatusRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          Text(
            '$label：',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
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

  Widget _buildTemporaryAuthorizationCard() {
    final configured =
        _esp32.temporaryAuthorizationConfigured;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              '临时借车授权状态',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              configured
                  ? '状态：${_esp32.temporaryAuthorizationStatus}'
                  : '状态：未设置',
            ),
            if (configured) ...[
              const SizedBox(height: 8),
              Text(
                '密码：${_esp32.temporaryPassword}',
                style: const TextStyle(
                  color: Colors.cyan,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '开始：${_esp32.temporaryStart}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '结束：${_esp32.temporaryEnd}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed:
                      _revokeTemporaryAuthorization,
                  child: const Text(
                    '撤销临时借车授权',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTemporaryUserCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              '临时借车状态',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '授权状态：'
              '${_esp32.temporaryAuthorizationStatus}',
            ),
            const SizedBox(height: 6),
            Text(
              '有效期至：'
              '${_esp32.temporaryEnd ?? '未知'}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '当前身份只有六项车辆控制权限。',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSeatPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              '管理员设备席位',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '当前设备：\n${_esp32.deviceId}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '当前管理员设备：\n'
              '${_esp32.adminOwnerDeviceId ?? '尚未绑定'}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '当前系统只允许一个管理员设备席位。',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationTestPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              '模拟测试工具',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '仅用于开发阶段测试最终场景。',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _simulateNewPhone,
                child: const Text(
                  '模拟切换到新手机',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed:
                    _simulateOriginalPhone,
                child: const Text(
                  '模拟切回原手机并测试自动连接',
                ),
              ),
            ),
            if (_esp32
                .temporaryAuthorizationConfigured) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed:
                      _simulateTemporaryExpired,
                  child: const Text(
                    '模拟临时借车立即过期',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startBluetoothScan() async {
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

  Future<void> _showConnectionMode() async {
    final result =
        await showModalBottomSheet<String>(
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
                const SizedBox(height: 10),
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
          title: const Text(
            '管理员连接',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            keyboardType:
                TextInputType.number,
            decoration: const InputDecoration(
              labelText: '管理员密码',
              hintText: '请输入管理员密码',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  controller.text,
                );
              },
              child: const Text('验证'),
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
      const Duration(milliseconds: 800),
    );

    _esp32.connect();

    final success =
        await _esp32.verifyAdmin(password);

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
          title: const Text(
            '临时借车连接',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            keyboardType:
                TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: '临时借车密码',
              hintText: '请输入6位密码',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  controller.text,
                );
              },
              child: const Text('验证'),
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
      const Duration(milliseconds: 800),
    );

    _esp32.connect();

    final success =
        await _esp32.verifyTemporaryUser(
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
        _adminStatus = '临时授权失败';
        _timeStatus = '未同步';
        _canControl = false;
        _connecting = false;
      });

      _showMessage(
        '临时借车密码错误、尚未开始或已经过期',
      );
    }
  }

  Future<void>
      _showTemporaryAuthorization() async {
    DateTime start = DateTime.now();

    DateTime end = start.add(
      const Duration(hours: 24),
    );

    final configured =
        await showDialog<
            _TemporaryAuthorizationInput>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                '设置临时借车授权',
              ),
              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    '默认有效期为24小时，可以分别修改开始时间和结束时间。',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    leading: const Icon(
                      Icons.play_arrow,
                    ),
                    title: const Text(
                      '开始时间',
                    ),
                    subtitle: Text(
                      _formatDateTime(start),
                    ),
                    onTap: () async {
                      final picked =
                          await _pickDateTime(
                        context,
                        start,
                      );

                      if (picked != null) {
                        setDialogState(() {
                          start = picked;

                          if (!end.isAfter(
                            start,
                          )) {
                            end = start.add(
                              const Duration(
                                hours: 24,
                              ),
                            );
                          }
                        });
                      }
                    },
                  ),
                  ListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    leading: const Icon(
                      Icons.stop,
                    ),
                    title: const Text(
                      '结束时间',
                    ),
                    subtitle: Text(
                      _formatDateTime(end),
                    ),
                    onTap: () async {
                      final picked =
                          await _pickDateTime(
                        context,
                        end,
                      );

                      if (picked != null) {
                        setDialogState(() {
                          end = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '当前有效时长：'
                    '${end.difference(start).inHours}小时 '
                    '${end.difference(start).inMinutes % 60}分钟',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },
                  child: const Text(
                    '取消',
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!end.isAfter(start)) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '结束时间必须晚于开始时间',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(
                      context,
                      _TemporaryAuthorizationInput(
                        start: start,
                        end: end,
                      ),
                    );
                  },
                  child: const Text(
                    '生成密码',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || configured == null) {
      return;
    }

    try {
      final password =
          await _esp32.generateTemporaryPassword(
        start: configured.start,
        end: configured.end,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              '临时借车密码已生成',
            ),
            content: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  '临时密码',
                ),
                const SizedBox(height: 8),
                Text(
                  password,
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.cyan,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '开始：\n'
                  '${_formatDateTime(configured.start)}',
                ),
                const SizedBox(height: 8),
                Text(
                  '结束：\n'
                  '${_formatDateTime(configured.end)}',
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
                child: const Text(
                  '完成',
                ),
              ),
            ],
          );
        },
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        '生成临时授权失败：$e',
      );
    }
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context,
    DateTime initial,
  ) async {
    final date =
        await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate:
          DateTime.now().subtract(
        const Duration(days: 1),
      ),
      lastDate:
          DateTime.now().add(
        const Duration(days: 3650),
      ),
    );

    if (date == null || !context.mounted) {
      return null;
    }

    final time = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay.fromDateTime(initial),
    );

    if (time == null) {
      return null;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  String _formatDateTime(
    DateTime value,
  ) {
    String two(int value) {
      return value
          .toString()
          .padLeft(2, '0');
    }

    return '${value.year}-'
        '${two(value.month)}-'
        '${two(value.day)} '
        '${two(value.hour)}:'
        '${two(value.minute)}';
  }

  Future<void>
      _revokeTemporaryAuthorization() async {
    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            '撤销临时借车授权',
          ),
          content: const Text(
            '撤销后，这个临时密码将立即失效。',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                '取消',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                '确认撤销',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await _esp32
        .clearTemporaryAuthorization();

    if (!mounted) return;

    setState(() {});

    _showMessage(
      '临时借车授权已撤销',
    );
  }

  Future<void>
      _simulateTemporaryExpired() async {
    await _esp32.simulateTemporaryExpired();

    if (!mounted) return;

    setState(() {
      _deviceStatus =
          _esp32.sessionRole == 'temporary'
              ? '未连接'
              : _deviceStatus;

      _adminStatus =
          _esp32.sessionRole == 'temporary'
              ? '临时授权过期'
              : _adminStatus;

      _timeStatus =
          _esp32.sessionRole == 'temporary'
              ? '未同步'
              : _timeStatus;

      _canControl =
          _esp32.sessionRole == 'temporary'
              ? false
              : _canControl;

      _vehicleFound =
          _esp32.sessionRole == 'temporary'
              ? false
              : _vehicleFound;
    });

    _showMessage(
      '已经模拟临时授权过期',
    );
  }

  Future<void> _simulateNewPhone() async {
    await _esp32.simulateNewPhone();

    if (!mounted) return;

    setState(() {
      _deviceStatus = '未连接';
      _adminStatus = '未授权';
      _timeStatus = '未同步';
      _canControl = false;
      _connecting = false;
      _vehicleFound = false;
    });

    _showMessage(
      '已经模拟切换到新手机。',
    );
  }

  Future<void>
      _simulateOriginalPhone() async {
    final success =
        await _esp32
            .simulateOriginalPhoneAndAutoReconnect();

    if (!mounted) return;

    if (success) {
      setState(() {
        _deviceStatus = '已连接';
        _adminStatus = '已授权';
        _timeStatus = '已同步';
        _canControl = true;
        _vehicleFound = true;
      });

      _showMessage(
        '原手机自动连接成功。',
      );
    } else {
      setState(() {
        _deviceStatus = '未连接';
        _adminStatus = '授权失效';
        _timeStatus = '未同步';
        _canControl = false;
        _vehicleFound = false;
      });

      _showMessage(
        '原手机自动连接被拒绝：管理员席位已属于其他手机。',
      );
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
        _esp32.executeCommand(command);

    _showMessage(result);

    setState(() {});
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

class _TemporaryAuthorizationInput {
  final DateTime start;
  final DateTime end;

  const _TemporaryAuthorizationInput({
    required this.start,
    required this.end,
  });
}
