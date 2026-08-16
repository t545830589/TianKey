import 'package:flutter_test/flutter_test.dart';

import 'package:tiankey/services/mock_esp32.dart';

void main() {
  test('BLE scan discovers the frozen demo vehicle', () {
    final esp32 = MockESP32();

    expect(esp32.scanDevices(), contains(MockESP32.vehicleName));
    expect(esp32.scanned, isTrue);
  });

  test('vehicle commands are denied before authorization and connection', () {
    final esp32 = MockESP32();

    expect(esp32.executeCommand('锁车'), '设备未连接');
    expect(esp32.getLogs().last, contains('命令拒绝：设备未连接'));
  });

  test('log retention caps the in-memory log list at 200 entries', () {
    final esp32 = MockESP32();
    for (var i = 0; i < 230; i++) {
      esp32.scanDevices();
    }

    expect(esp32.getLogs().length, lessThanOrEqualTo(MockESP32.maxLogCount));
  });
}
