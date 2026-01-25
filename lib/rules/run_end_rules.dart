/// Run End Rules
/// -------------
/// This file defines the ONLY conditions that can end a run.
/// These rules are IMMUTABLE once locked.
///
/// Sparkles Rule Lock:
/// - 3 escapes  → GAME OVER
/// - 10 misses  → GAME OVER
library run_end_rules;

enum RunEndReason {
  escape,
  missStreak,
}

class RunEndRules {
  static const int maxEscapes = 3;
  static const int maxMisses = 10;

  /// Returns a RunEndReason if the run should end, otherwise null.
  static RunEndReason? evaluate({
    required int escapes,
    required int misses,
  }) {
    if (escapes >= maxEscapes) {
      return RunEndReason.escape;
    }

    if (misses >= maxMisses) {
      return RunEndReason.missStreak;
    }

    return null;
  }
}
