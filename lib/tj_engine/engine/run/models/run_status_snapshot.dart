// lib/tj_engine/engine/run/models/run_status_snapshot.dart

import 'run_state.dart';

/// ===============================================================
/// SYSTEM: RunStatusSnapshot (Live Run State View)
/// ===============================================================
///
/// PURPOSE:
/// Represents the current, live state of an active run.
/// This object is safe for UI consumption.
///
/// OWNED BY:
/// RunLifecycleManager
///
/// CONSUMED BY:
/// - HUD
/// - Debug overlays
/// - Difficulty manager
///
/// IMPORTANT:
/// This is a pure immutable data container.
/// It contains no logic.
/// ===============================================================
class RunStatusSnapshot {
  /// Unique identifier for this run.
  final String runId;

  /// Current lifecycle state.
  final RunState state;

  /// Current score.
  final int score;

  /// Total successful pops.
  final int pops;

  /// Total tap misses.
  final int misses;

  /// Total escaped balloons.
  final int escapes;

  /// Smoothed accuracy value (0.0 – 1.0).
  ///
  /// To change how accuracy is calculated:
  /// -> Modify momentum accuracy logic
  final double accuracy01;

  /// Current world level.
  ///
  /// To change world progression:
  /// -> Modify RisingWorlds thresholds
  final int currentWorldLevel;

  /// Highest world reached during this run.
  final int maxWorldLevelReached;

  /// Elapsed time since run start.
  final Duration elapsed;

  /// End reason (null while running).
  final EndReason? endReason;

  const RunStatusSnapshot({
    required this.runId,
    required this.state,
    required this.score,
    required this.pops,
    required this.misses,
    required this.escapes,
    required this.accuracy01,
    required this.currentWorldLevel,
    required this.maxWorldLevelReached,
    required this.elapsed,
    required this.endReason,
  });
}
