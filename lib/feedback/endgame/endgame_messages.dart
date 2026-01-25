/// Endgame Messages
/// ----------------
/// Messages selected based on the authoritative RunEndReason.
/// This file contains NO logic that can end a run.
library endgame_messages;

import '../../rules/run_end_rules.dart';

class EndgameMessages {
  static const Map<RunEndReason, List<String>> messages = {
    RunEndReason.escape: [
      "Three got past you. That’s the run.",
      "You lost control of the field.",
      "Too many escapes — tighten it up.",
    ],
    RunEndReason.missStreak: [
      "Ten misses broke your rhythm.",
      "Accuracy slipped too far.",
      "You lost your timing — reset and go again.",
    ],
  };

  static String pick(RunEndReason reason) {
    final list = messages[reason] ?? const ["Run ended."];
    final idx = DateTime.now().millisecond % list.length;
    return list[idx];
  }
}
