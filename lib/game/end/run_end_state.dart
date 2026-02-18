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

  /// Engine-owned summary conversion
  factory RunEndState.fromSummary(RunSummary summary) {
    RunEndReason mappedReason;

    switch (summary.endReason) {
      case EndReason.escapeLimit:
        mappedReason = RunEndReason.escape;
        break;

      case EndReason.missLimit:
        mappedReason = RunEndReason.miss;
        break;

      // All other engine reasons map to "miss"
      default:
        mappedReason = RunEndReason.miss;
    }

    return RunEndState(
      reason: mappedReason,
      misses: summary.misses,
      escapes: summary.escapes,
    );
  }
}
