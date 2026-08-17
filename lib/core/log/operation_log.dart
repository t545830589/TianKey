class OperationLog {
  final DateTime time;
  final String user;
  final String action;
  final String result;

  OperationLog({
    required this.time,
    required this.user,
    required this.action,
    required this.result,
  });

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'user': user,
        'action': action,
        'result': result,
      };
}
