enum ScreenMode {
  game,
  debug,
  blank,
}

/// Debug event classification for filtering + telemetry readability.
/// Keep this enum "wide" so we can grow observability without refactors.
enum DebugEventType {
  tap,
  hit,
  miss,
  world,
  speed,
  system,
  run,
}

/// Central mutable game state shared across systems.
/// This file is intentionally "fat" because many systems depend on it.
class GameState {
  // -----------------------------
  // APP ROUTING
  // -----------------------------
  ScreenMode screenMode = ScreenMode.game;

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

  /// Raw debug log buffer (used by DebugScreen)
  final List<String> debugLogs = [];

  /// Which debug event types are currently visible
  final Set<DebugEventType> enabledFilters = {
    DebugEventType.tap,
    DebugEventType.hit,
    DebugEventType.miss,
    DebugEventType.world,
    DebugEventType.speed,
    DebugEventType.system,
    DebugEventType.run,
  };

  void toggleFreeze() {
    debugFrozen = !debugFrozen;
    logEvent(DebugEventType.system, 'DEBUG freeze=${debugFrozen ? "ON" : "OFF"}');
  }

  void clearLogs() {
    debugLogs.clear();
    logEvent(DebugEventType.system, 'DEBUG logs cleared');
  }

  // -----------------------------
  // RUN END STATE
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

  /// Legacy log API (kept to avoid breaking any existing call sites).
  /// Prefer logEvent() going forward.
  void log(String message) {
    debugLogs.add(message);
    // ignore: avoid_print
    print(message);
  }

  /// Typed + filter-aware logger.
  /// This restores the "telemetry channels" we had before (TAP/MISS/WORLD/SPEED/SYSTEM...).
  void logEvent(DebugEventType type, String message) {
    if (debugFrozen) return;
    if (!enabledFilters.contains(type)) return;

    final line = '${type.name.toUpperCase()} $message';
    debugLogs.add(line);
    // ignore: avoid_print
    print(line);
  }
}
