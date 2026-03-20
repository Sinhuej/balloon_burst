// lib/tj_engine/engine/run/run_lifecycle_manager.dart

import 'models/run_event.dart';
import 'models/run_state.dart';
import 'models/run_status_snapshot.dart';
import 'models/run_summary.dart';

/// ===============================================================
/// SHIELD ACCESS (interface only)
/// ===============================================================
///
/// Keeps RunLifecycleManager pure Dart.
/// Persistence is owned by an engine subsystem (ShieldManager).
abstract class ShieldAccess {
  bool get isPending;
  bool get isActive;

  Future<void> armForNextRun();
  Future<void> activateIfPending();
  Future<void> consume();
}

/// ===============================================================
/// SYSTEM: RunLifecycleManager
/// ===============================================================
class RunLifecycleManager {
  final ShieldAccess _shield;

  RunLifecycleManager({required ShieldAccess shield}) : _shield = shield;

  RunState _state = RunState.idle;

  String _runId = '';
  DateTime? _startTime;
  DateTime? _endTime;

  int _score = 0;
  int _pops = 0;
  int _misses = 0;
  int _escapes = 0;

  // STREAK (competitive precision arcade)
  int _streak = 0;
  int _bestStreak = 0;

  int _currentWorldLevel = 1;
  int _maxWorldLevelReached = 1;

  double _accuracy01 = 0.0;

  EndReason? _endReason;
  RunSummary? _latestSummary;

  RunState get state => _state;
  RunSummary? get latestSummary => _latestSummary;

  // ============================================================
  // SHIELD (persistent via ShieldManager)
  // ============================================================
  bool get isShieldActive => _shield.isActive;

  /// Useful for Start Screen UX / purchase button state.
  bool get isShieldArmedForNextRun => _shield.isPending;

  Future<void> armShieldForNextRun() async {
    await _shield.armForNextRun();
  }

  // ============================================================
  // RUN LIFECYCLE
  // ============================================================

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

    _accuracy01 = 0.0;
    _endReason = null;
    _latestSummary = null;

    // Activate shield (async) if it was purchased earlier.
    // Fire-and-forget by design (never block run start).
    _shield.activateIfPending();
  }

  void _recomputeAccuracy() {
    final attempts = _pops + _misses + _escapes;
    _accuracy01 = attempts > 0 ? _pops / attempts : 0.0;
  }

  void report(RunEvent event) {
    if (_state != RunState.running) return;

    if (event is PopEvent) {
      _pops++;
      _score += event.points;

      _recomputeAccuracy();

      _streak++;
      if (_streak > _bestStreak) _bestStreak = _streak;
      return;
    }

    if (event is MissEvent) {
      _misses++;

      _recomputeAccuracy();

      _streak = 0;

      if (_misses >= 10) {
        endRun(EndReason.missLimit);
      }
      return;
    }

    if (event is EscapeEvent) {
      // 🛡 Shield absorbs FIRST escape (if any occurred this event)
      if (_shield.isActive && event.count > 0) {
        // Consume shield (async) but do not block gameplay.
        _shield.consume();
        _streak = 0;
        return;
      }

      _escapes += event.count;
      if (event.count > 0) _streak = 0;

      _recomputeAccuracy();

      if (_escapes >= 3) {
        endRun(EndReason.escapeLimit);
      }
      return;
    }

    if (event is WorldTransitionEvent) {
      _currentWorldLevel = event.newWorldLevel;
      if (_currentWorldLevel > _maxWorldLevelReached) {
        _maxWorldLevelReached = _currentWorldLevel;
      }
      return;
    }

    if (event is ScoreDeltaEvent) {
      _score += event.delta;
      if (_score < 0) _score = 0;
      return;
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
      bestStreak: _bestStreak,
      accuracy01: _accuracy01,
      worldReached: _maxWorldLevelReached,
      endReason: reason,
    );
  }

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

    // If a shield is pending (purchased on RunEndOverlay), activate it now.
    _shield.activateIfPending();
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
