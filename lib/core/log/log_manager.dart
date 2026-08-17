class LogManager {
  final List<String> _logs = [];

  void add(String message) {
    _logs.add(message);
  }

  List<String> get logs => List.unmodifiable(_logs);
}
