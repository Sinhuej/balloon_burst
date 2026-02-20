// lib/tj_engine/engine/run/models/run_summary.dart

import 'run_state.dart';

/// ===============================================================
/// SYSTEM: RunSummary (Final End-of-Run Record)
/// ===============================================================
///
/// PURPOSE:
/// Represents the immutable result of a completed run.
/// Generated once when the run ends.
/// Must never mutate.
///
/// OWNED BY:
/// RunLifecycleManager
///
/// CONSUMED BY:
/// - RunEndOverlay
/// - Analytics
/// - DailyReward scaling
/// - Player stats tracking
///
/// IMPORTANT:
/// This class contains no logic.
/// It is a pure data container.
/// ===============================================================
class RunSummary {
  /// Unique ID for this run.
  final String runId;

  /// When the run started.
  final DateTime startTime;

  /// When the run ended.
  final DateTime endTime;

  /// Total duration of the run.
  ///
  /// To influence run length:
  /// -> Adjust fail conditions in RunLifecycleManager
  final Duration duration;

  /// Final score for this run.
  ///
  /// To change scoring behavior:
  /// -> Modify ScoreDeltaEvent handling later
  final int score;

  /// Total successful pops.
  final int pops;

  /// Total misses (tap misses).
  final int misses;

  /// Total escaped balloons.
  final int escapes;

  /// Best consecutive pop streak achieved in this run.
  ///
  /// STREAK RULES (competitive arcade):
  /// - Pop -> +1
  /// - Miss -> reset to 0
  /// - Escape -> reset to 0
  final int bestStreak;

  /// Final smoothed accuracy value (0.0 – 1.0).
  ///
  /// To adjust accuracy sensitivity:
  /// -> Modify momentum accuracy EMA settings
  final double accuracy01;

  /// Highest world reached during this run.
  ///
  /// To adjust world progression:
  /// -> Modify RisingWorlds thresholds
  final int worldReached;

  /// Why the run ended.
  ///
  /// To add new end types:
  /// -> Extend EndReason enum
  /// -> Handle in RunLifecycleManager
  final EndReason endReason;

  const RunSummary({
    required this.runId,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.score,
    required this.pops,
    required this.misses,
    required this.escapes,
    required this.bestStreak,
    required this.accuracy01,
    required this.worldReached,
    required this.endReason,
  });
}
