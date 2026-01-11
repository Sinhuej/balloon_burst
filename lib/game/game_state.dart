import 'dart:collection';

/// App-level screen modes
enum ScreenMode {
  game,
  debug,
  blank,
}

/// Debug event categories
enum DebugEventType {
  tap,
  miss,
  world,
  speed,
  system,
}

/// Global game state shared across screens and systems
class GameState {
  // -------------------------------
  // Core runtime state
  // -------------------------------
  int framesSinceStart = 0;
  bool tapPulse = false;

  /// Updated by BalloonPainter every frame
  double viewportHeight = 0.0;

  // -------------------------------
  // App / screen routing state
  // -------------------------------
  ScreenMode screenMode = ScreenMode.game;

  // -------------------------------
  // TJ Debug Log System (TapRush-grade)
  // -------------------------------
  static const int maxLogs = 300;

  final ListQueue<String> _debugLogs = ListQueue();
  bool debugFrozen = false;

  final Set<DebugEventType> enabledFilters = {
    DebugEventType.tap,
    DebugEventType.miss,
    DebugEventType.world,
    DebugEventType.speed,
    DebugEventType.system,
  };

  List<String> get debugLogs => _debugLogs.toList();

  void log(
    String message, {
    DebugEventType type = DebugEventType.system,
  }) {
    if (debugFrozen) return;
    if (!enabledFilters.contains(type)) return;

    if (_debugLogs.length >= maxLogs) {
      _debugLogs.removeFirst();
    }

    _debugLogs.add(message);
  }

  void clearLogs() {
    _debugLogs.clear();
  }

  void toggleFreeze() {
    debugFrozen = !debugFrozen;
    log(
      debugFrozen ? 'SYSTEM: logging frozen' : 'SYSTEM: logging resumed',
      type: DebugEventType.system,
    );
  }
}
