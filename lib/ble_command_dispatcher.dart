class BleCommand {
  final String name;
  final List<int> payload;

  const BleCommand({required this.name, required this.payload});
}

class BleCommandResult {
  final bool success;
  final List<int> response;

  const BleCommandResult({required this.success, required this.response});
}

/// Command routing layer between UI/business logic and BLE protocol layer.
///
/// Validation is intentionally injected so authentication, permission,
/// vehicle state and simulator checks can be added without coupling the BLE
/// transport layer to business logic.
class BleCommandDispatcher {
  final Future<BleCommandResult> Function(BleCommand command) sender;
  final Future<bool> Function(BleCommand command)? validator;

  const BleCommandDispatcher({
    required this.sender,
    this.validator,
  });

  Future<BleCommandResult> execute(BleCommand command) async {
    if (validator != null) {
      final allowed = await validator!(command);
      if (!allowed) {
        return const BleCommandResult(
          success: false,
          response: <int>[],
        );
      }
    }

    return sender(command);
  }
}
