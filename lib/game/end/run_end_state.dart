import 'package:balloon_burst/tj_engine/engine/run/models/run_summary.dart';
import 'package:balloon_burst/tj_engine/engine/run/models/run_state.dart';

enum RunEndReason {
  miss,
  escape,
  unknown,
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

  /// 🔹 Engine-owned summary conversion
  factory RunEndState.fromSummary(RunSummary summary) {
    RunEndReason mappedReason;

    switch (summary.endReason) {
      case EndReason.miss:
        mappedReason = RunEndReason.miss;
        break;
      case EndReason.escape:
        mappedReason = RunEndReason.escape;
        break;
      default:
        mappedReason = RunEndReason.unknown;
    }

    return RunEndState(
      reason: mappedReason,
      misses: summary.misses,
      escapes: summary.escapes,
    );
  }
}
