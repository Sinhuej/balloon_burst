import 'package:balloon_burst/debug/debug_log.dart';

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
  // Debug API (FORWARDER ONLY)
  // -------------------------------
  void log(
    String message, {
    DebugEventType type = DebugEventType.system,
  }) {
    DebugLog.instance.log(message, type: type);
  }

  List<String> get debugLogs =>
      DebugLog.instance.debugLogs;

  void clearLogs() {
    DebugLog.instance.clear();
  }

  void toggleFreeze() {
    DebugLog.instance.toggleFreeze();
  }
}
