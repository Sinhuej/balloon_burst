// lib/tj_engine/engine/run/run_lifecycle_manager.dart

import 'models/run_state.dart';
import 'models/run_event.dart';
import 'models/run_status_snapshot.dart';
import 'models/run_summary.dart';

/// ===============================================================
/// SYSTEM: RunLifecycleManager
/// ===============================================================
///
/// PURPOSE:
/// Authoritative engine-owned controller for a single gameplay run.
///
/// RESPONSIBILITIES:
/// - Start a run
/// - End a run
/// - Track run statistics
/// - Generate RunSummary
/// - Provide live RunStatusSnapshot
///
/// IMPORTANT:
/// This file must remain pure Dart.
/// No Flutter imports.
/// No game-specific imports.
/// ===============================================================
class RunLifecycleManager {
  RunState _state = RunState.idle;

  String _runId = '';
  DateTime? _startTime;
  DateTime? _endTime;

  int _score = 0;
  int _pops = 0;
  int _misses = 0;
  int _escapes = 0;

  // ------------------------------------------------------------
  // STREAK (competitive precision arcade)
  // ------------------------------------------------------------
  int _streak = 0;
  int _bestStreak = 0;

  int _currentWorldLevel = 1;
  int _maxWorldLevelReached = 1;

  double _accuracy01 = 1.0;

  EndReason? _endReason;
  RunSummary? _latestSummary;

  RunState get state => _state;
  RunSummary? get latestSummary => _latestSummary;

  /// ============================================================
  /// Start a new run.
  /// ============================================================
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

    _streak = 0;
    _bestStreak = 0;

    _currentWorldLevel = 1;
    _maxWorldLevelReached = 1;

    _accuracy01 = 1.0;
    _endReason = null;
    _latestSummary = null;
  }

  /// ============================================================
  /// Report gameplay event.
  /// ============================================================
  void report(RunEvent event) {
    if (_state != RunState.running) return;

    if (event is PopEvent) {
      _pops++;
      _score += event.points;

      final attempts = _pops + _misses;
      _accuracy01 = attempts > 0 ? _pops / attempts : 1.0;

      _streak++;
      if (_streak > _bestStreak) _bestStreak = _streak;

    } else if (event is MissEvent) {
      _misses++;

      final attempts = _pops + _misses;
      _accuracy01 = attempts > 0 ? _pops / attempts : 1.0;

      _streak = 0;

      if (_misses >= 10) {
        endRun(EndReason.missLimit);
        return;
      }

    } else if (event is EscapeEvent) {
      _escapes += event.count;

      if (event.count > 0) _streak = 0;

      if (_escapes >= 3) {
        endRun(EndReason.escapeLimit);
        return;
      }

    } else if (event is WorldTransitionEvent) {
      _currentWorldLevel = event.newWorldLevel;
      if (_currentWorldLevel > _maxWorldLevelReached) {
        _maxWorldLevelReached = _currentWorldLevel;
      }

    } else if (event is ScoreDeltaEvent) {
      _score += event.delta;
      if (_score < 0) _score = 0;
    }
  }

  /// ============================================================
  /// End the current run.
  /// ============================================================
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
      bestStreak: _bestStreak,
      accuracy01: _accuracy01,
      worldReached: _maxWorldLevelReached,
      endReason: reason,
    );
  }

  /// ============================================================
  /// Revive the last ended run.
  /// Keeps score/streak/world.
  /// Clears fail counters and resumes running state.
  /// ============================================================
  void revive() {
    if (_state != RunState.ended) return;

    _state = RunState.running;

    // Reset fail counters so player doesn’t instantly die again
    _misses = 0;
    _escapes = 0;

    // Clear end markers
    _endReason = null;
    _endTime = null;
    _latestSummary = null;
  }

  /// ============================================================
  /// Live snapshot of run state.
  /// ============================================================
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
      streak: _streak,
      bestStreak: _bestStreak,
      accuracy01: _accuracy01,
      currentWorldLevel: _currentWorldLevel,
      maxWorldLevelReached: _maxWorldLevelReached,
      elapsed: elapsed,
      endReason: _endReason,
    );
  }
}
