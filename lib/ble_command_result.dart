/// Result wrapper for BLE command pipeline.
///
/// This class intentionally contains no TianKey vehicle command definitions.
/// Protocol frames must be provided by the real device specification.
class BleCommandResult {
  const BleCommandResult({
    required this.success,
    this.payload = const <int>[],
    this.error,
  });

  final bool success;
  final List<int> payload;
  final String? error;

  factory BleCommandResult.ok(List<int> payload) {
    return BleCommandResult(
      success: true,
      payload: List<int>.unmodifiable(payload),
    );
  }

  factory BleCommandResult.failed(String message) {
    return BleCommandResult(
      success: false,
      error: message,
    );
  }
}
