enum HudStatus {
  normal,
  warning,
  error,
}

class HudState {
  final HudStatus status;
  final String message;

  const HudState({
    required this.status,
    required this.message,
  });

  factory HudState.normal() {
    return const HudState(
      status: HudStatus.normal,
      message: 'Ready',
    );
  }
}
