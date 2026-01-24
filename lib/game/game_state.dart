enum DebugEventType {
  hit,
  miss,
}

/// Central mutable game state shared across systems.
/// This file is intentionally "fat" because many systems depend on it.
class GameState {
  // -----------------------------
  // VIEWPORT / FRAME STATE
  // -----------------------------
  double viewportHeight = 0.0;
  int framesSinceStart = 0;

  // -----------------------------
  // INPUT / FEEDBACK
  // -----------------------------
  bool tapPulse = false;

  // -----------------------------
  // DEBUG / DEV CONTROLS
  // -----------------------------
  bool debugFrozen = false;

  /// Which debug event types are currently visible
  final Set<DebugEventType> enabledFilters = {
    DebugEventType.hit,
    DebugEventType.miss,
  };

  void toggleFreeze() {
    debugFrozen = !debugFrozen;
    log('DEBUG freeze=${debugFrozen ? "ON" : "OFF"}');
  }

  void clearLogs() {
    log('DEBUG logs cleared');
  }

  // -----------------------------
  // RUN END STATE (NEW)
  // -----------------------------
  bool isGameOver = false;
  String? endReason;

  void resetRun() {
    isGameOver = false;
    endReason = null;
    framesSinceStart = 0;
  }

  // -----------------------------
  // LOGGING
  // -----------------------------
  void log(String message) {
    // ignore: avoid_print
    print(message);
  }
}
