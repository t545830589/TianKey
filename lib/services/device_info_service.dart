class DeviceInfoService {
  String deviceName = 'TianKey-ESP32-V11';
  String firmware = 'V11-SIM';
  String status = 'READY';

  Map<String, String> info() {
    return {
      'device': deviceName,
      'firmware': firmware,
      'status': status,
    };
  }
}
