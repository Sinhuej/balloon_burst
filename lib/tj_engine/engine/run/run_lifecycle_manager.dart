// lib/tj_engine/engine/run/run_lifecycle_manager.dart

import 'models/run_state.dart';
import 'models/run_event.dart';
import 'models/run_status_snapshot.dart';
import 'models/run_summary.dart';

class RunLifecycleManager {
  RunState _state = RunState.idle;

  String _runId = '';
  DateTime? _startTime;
  DateTime? _endTime;

  int _score = 0;
  int _pops = 0;
  int _misses = 0;
  int _escapes = 0;

  int _currentWorldLevel = 1;
  int _maxWorldLevelReached = 1;

  double _accuracy01 = 1.0;

  EndReason? _endReason;
  RunSummary? _latestSummary;

  RunState get state => _state;
  RunSummary? get latestSummary => _latestSummary;

  void startRun({required String runId}) {
    if (_state == RunState.running) return;

    _runId = runId;
    _state = RunState.running;

    _startTime = DateTime.now();
    _endTime = null;

    _score = 0;
    _pops = 0;
    _misses = 0;
    _escapes = 0;

    _currentWorldLevel = 1;
    _maxWorldLevelReached = 1;

    _accuracy01 = 1.0;
    _endReason = null;
    _latestSummary = null;
  }

  /// ============================================================
  /// Report gameplay event.
  /// Engine now enforces fail limits.
  /// ============================================================
  void report(RunEvent event) {
    if (_state != RunState.running) return;

    if (event is PopEvent) {
      _pops++;
      _score += event.points;
    }

    else if (event is MissEvent) {
      _misses++;

      // 🔹 Miss fail rule
      if (_misses >= 10) {
        endRun(EndReason.missLimit);
        return;
      }
    }

    else if (event is EscapeEvent) {
      _escapes += event.count;

      // 🔹 Escape fail rule
      if (_escapes >= 3) {
        endRun(EndReason.escapeLimit);
        return;
      }
    }

    else if (event is WorldTransitionEvent) {
      _currentWorldLevel = event.newWorldLevel;
      if (_currentWorldLevel > _maxWorldLevelReached) {
        _maxWorldLevelReached = _currentWorldLevel;
      }
    }

    else if (event is ScoreDeltaEvent) {
      _score += event.delta;
      if (_score < 0) _score = 0;
    }
  }

  void endRun(EndReason reason) {
    if (_state != RunState.running) return;

    _state = RunState.ended;
    _endReason = reason;
    _endTime = DateTime.now();

    final start = _startTime ?? _endTime!;
    final end = _endTime!;
    final duration = end.difference(start);

    _latestSummary = RunSummary(
      runId: _runId,
      startTime: start,
      endTime: end,
      duration: duration,
      score: _score,
      pops: _pops,
      misses: _misses,
      escapes: _escapes,
      accuracy01: _accuracy01,
      worldReached: _maxWorldLevelReached,
      endReason: reason,
    );
  }

  RunStatusSnapshot getSnapshot() {
    final now = DateTime.now();
    final start = _startTime ?? now;
    final elapsed = now.difference(start);

    return RunStatusSnapshot(
      runId: _runId,
      state: _state,
      score: _score,
      pops: _pops,
      misses: _misses,
      escapes: _escapes,
      accuracy01: _accuracy01,
      currentWorldLevel: _currentWorldLevel,
      maxWorldLevelReached: _maxWorldLevelReached,
      elapsed: elapsed,
      endReason: _endReason,
    );
  }
}
