class DeviceFeedback {
  final bool locked;
  final int batteryLevel;
  final String doorState;
  final String windowState;

  const DeviceFeedback({
    required this.locked,
    required this.batteryLevel,
    required this.doorState,
    required this.windowState,
  });

  factory DeviceFeedback.fromMap(Map<String, dynamic> data) {
    return DeviceFeedback(
      locked: data['locked'] ?? false,
      batteryLevel: data['batteryLevel'] ?? 0,
      doorState: data['doorState'] ?? 'unknown',
      windowState: data['windowState'] ?? 'unknown',
    );
  }
}
