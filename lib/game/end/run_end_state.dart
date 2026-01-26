import 'package:balloon_burst/game/game_controller.dart';

enum RunEndReason {
  miss,
  escape,
}

class RunEndState {
  final RunEndReason reason;
  final int misses;
  final int escapes;

  const RunEndState({
    required this.reason,
    required this.misses,
    required this.escapes,
  });

  factory RunEndState.fromController(GameController c) {
    return RunEndState(
      reason: c.endReason == 'escape'
          ? RunEndReason.escape
          : RunEndReason.miss,
      misses: c.missCount,
      escapes: c.escapeCount,
    );
  }
}
