enum RunEndReason {
  miss,
  escape,
}

class RunEndState {
  final RunEndReason reason;
  final int misses;
  final int escapes;

  const RunEndState({
  factory RunEndState.fromController(GameController c) {
    return RunEndState(
      ended: c.isEnded,
      reason: c.endReason,
      escapes: c.escapeCount,
      misses: c.missCount,
    );
  }
    required this.reason,
    required this.misses,
    required this.escapes,
  });
}
