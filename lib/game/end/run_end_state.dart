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
}
