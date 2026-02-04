import 'dart:collection';
import 'package:balloon_burst/game/game_state.dart';

/// Centralized, persistent debug log system.
/// Lives outside GameState so logs survive run resets.
class DebugLog {
  static final DebugLog instance = DebugLog._internal();
  DebugLog._internal();

  static const int maxLogs = 500;

  final ListQueue<String> _logs = ListQueue();
  bool frozen = false;

  final Set<DebugEventType> enabledFilters = {
    DebugEventType.tap,
    DebugEventType.miss,
    DebugEventType.world,
    DebugEventType.speed,
    DebugEventType.system,
  };

  List<String> get debugLogs => _logs.toList();

  void log(
    String message, {
    DebugEventType type = DebugEventType.system,
  }) {
    if (frozen) return;
    if (!enabledFilters.contains(type)) return;

    if (_logs.length >= maxLogs) {
      _logs.removeFirst();
    }
    _logs.add(message);
  }

  void clear() {
    _logs.clear();
  }

  void toggleFreeze() {
    frozen = !frozen;
    log(
      frozen
          ? 'SYSTEM: logging frozen'
          : 'SYSTEM: logging resumed',
      type: DebugEventType.system,
    );
  }
}
