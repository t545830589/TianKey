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
/// Real device frames must be supplied by the device protocol specification.
class BleCommandDispatcher {
  final Future<BleCommandResult> Function(BleCommand command) sender;

  const BleCommandDispatcher({required this.sender});

  Future<BleCommandResult> execute(BleCommand command) {
    return sender(command);
  }
}
