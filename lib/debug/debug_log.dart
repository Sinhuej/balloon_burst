import 'dart:collection';

enum DebugEventType {
  tap,
  miss,
  world,
  speed,
  system,
}

class DebugLog {
  DebugLog._();
  static final DebugLog instance = DebugLog._();

  static const int maxLogs = 300;

  final ListQueue<String> _logs = ListQueue();
  bool _debugFrozen = false;

  final Set<DebugEventType> enabledFilters = {
    DebugEventType.tap,
    DebugEventType.miss,
    DebugEventType.world,
    DebugEventType.speed,
    DebugEventType.system,
  };

  // ✅ CI EXPECTS THIS
  bool get debugFrozen => _debugFrozen;

  List<String> get logs => _logs.toList();

  void log(
    String message, {
    DebugEventType type = DebugEventType.system,
  }) {
    if (_debugFrozen) return;
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
    _debugFrozen = !_debugFrozen;
    log(
      _debugFrozen
          ? 'SYSTEM: logging frozen'
          : 'SYSTEM: logging resumed',
      type: DebugEventType.system,
    );
  }
}
