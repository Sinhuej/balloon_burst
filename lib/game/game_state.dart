import 'package:balloon_burst/debug/debug_log.dart';

/// App-level screen modes
enum ScreenMode {
  game,
  debug,
  blank,
}

/// Global game state shared across screens and systems
class GameState {
  // -------------------------------
  // Core runtime state
  // -------------------------------
  int framesSinceStart = 0;
  bool tapPulse = false;

  /// Updated by renderer every frame
  double viewportHeight = 0.0;

  // -------------------------------
  // App / screen routing state
  // -------------------------------
  ScreenMode screenMode = ScreenMode.game;

  // -------------------------------
  // Debug Log (delegated)
  // -------------------------------
  DebugLog get _log => DebugLog.instance;

  bool get debugFrozen => _log.debugFrozen;
  List<String> get debugLogs => _log.logs;

  void log(
    String message, {
    DebugEventType type = DebugEventType.system,
  }) {
    _log.log(message, type: type);
  }

  void clearLogs() {
    _log.clear();
  }

  void toggleFreeze() {
    _log.toggleFreeze();
  }
}
