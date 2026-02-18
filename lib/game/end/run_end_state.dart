import 'package:balloon_burst/game/game_controller.dart';
import 'package:balloon_burst/tj_engine/engine/run/models/run_summary.dart';
import 'package:balloon_burst/tj_engine/engine/run/models/run_state.dart';

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

  /// ===============================================================
  /// Legacy Constructor (Controller-based)
  /// ===============================================================
  factory RunEndState.fromController(GameController c) {
    return RunEndState(
      reason: c.endReason == 'escape'
          ? RunEndReason.escape
          : RunEndReason.miss,
      misses: c.missCount,
      escapes: c.escapeCount,
    );
  }

  /// ===============================================================
  /// New Engine-Based Constructor
  /// ===============================================================
  factory RunEndState.fromSummary(RunSummary summary) {
    RunEndReason mappedReason;

    switch (summary.endReason) {
      case EndReason.escapeLimit:
        mappedReason = RunEndReason.escape;
        break;

      case EndReason.missLimit:
        mappedReason = RunEndReason.miss;
        break;

      default:
        // Fallback for now to preserve current UI behavior
        mappedReason = RunEndReason.miss;
    }

    return RunEndState(
      reason: mappedReason,
      misses: summary.misses,
      escapes: summary.escapes,
    );
  }
}
