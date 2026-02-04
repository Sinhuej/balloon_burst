import 'dart:collection';
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
  // 🔑 DEBUG LOG FORWARDING
  // -------------------------------

  /// Expose debug logs
  List<String> get debugLogs => DebugLog.instance.logs;

  /// Expose freeze state
  bool get debugFrozen => DebugLog.instance.debugFrozen;

  /// Expose enabled filters
  Set<DebugEventType> get enabledFilters =>
      DebugLog.instance.enabledFilters;

  /// Forward log call
  void log(
    String message, {
    DebugEventType type = DebugEventType.system,
  }) {
    DebugLog.instance.log(message, type: type);
  }

  void clearLogs() {
    DebugLog.instance.clear();
  }

  void toggleFreeze() {
    DebugLog.instance.toggleFreeze();
  }
}
