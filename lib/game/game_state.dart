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
  // TJ Debug Log Buffer (Tap Rush parity)
  // -------------------------------
  static const int maxLogs = 120;
  final List<String> _debugLogs = [];

  List<String> get debugLogs => List.unmodifiable(_debugLogs);

  void log(String message) {
    _debugLogs.insert(0, message);
    if (_debugLogs.length > maxLogs) {
      _debugLogs.removeLast();
    }
  }
}

/// App-level screen modes
enum ScreenMode {
  game,
  debug,
  blank,
}
