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
///
/// NOTE:
/// GameState does NOT own debug state.
/// It forwards all debug behavior to DebugLog.
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
  // Debug API (FORWARDERS ONLY)
  // -------------------------------

  /// Write a debug log entry
  void log(
    String message, {
    DebugEventType type = DebugEventType.system,
  }) {
    DebugLog.instance.log(message, type: type);
  }

  /// Read-only debug log lines
  List<String> get debugLogs =>
      DebugLog.instance.debugLogs;

  /// Whether debug logging is frozen
  bool get debugFrozen =>
      DebugLog.instance.debugFrozen;

  /// Enabled debug filters
  Set<DebugEventType> get enabledFilters =>
      DebugLog.instance.enabledFilters;

  /// Clear all debug logs
  void clearLogs() {
    DebugLog.instance.clear();
  }

  /// Toggle debug freeze state
  void toggleFreeze() {
    DebugLog.instance.toggleFreeze();
  }
}
