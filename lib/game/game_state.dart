class GameState {
  int framesSinceStart = 0;
  bool tapPulse = false;

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
