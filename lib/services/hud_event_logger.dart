class HudEvent {
  final DateTime time;
  final String action;
  final String result;

  HudEvent({
    required this.time,
    required this.action,
    required this.result,
  });
}

class HudEventLogger {
  final List<HudEvent> _events = [];

  List<HudEvent> get events => List.unmodifiable(_events);

  void add(String action, String result) {
    _events.add(HudEvent(
      time: DateTime.now(),
      action: action,
      result: result,
    ));
  }

  void clear() {
    _events.clear();
  }
}
