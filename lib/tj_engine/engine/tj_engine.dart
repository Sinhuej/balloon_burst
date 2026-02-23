// lib/tj_engine/engine/tj_engine.dart

import 'package:shared_preferences/shared_preferences.dart';

import 'core/difficulty_manager.dart';
import 'run/run_lifecycle_manager.dart';
import 'daily/daily_reward_manager.dart';
import 'leaderboard/leaderboard_manager.dart';
import 'leaderboard/leaderboard_entry.dart';

/// ===============================================================
/// SYSTEM: TJEngine (Engine Facade)
/// ===============================================================
///
/// PURPOSE:
/// Single entry point to TapJunkie engine systems.
///
/// IMPORTANT:
/// - Engine core systems remain pure Dart.
/// - Persistence (SharedPreferences) is handled here at the facade boundary.
/// ===============================================================
class TJEngine {
  final RunLifecycleManager runLifecycle;
  final DifficultyManager difficulty;
  final DailyRewardManager dailyReward;
  final LeaderboardManager leaderboard;

  static const String _dailyClaimKey = 'tj_daily_last_claim_epoch';

  TJEngine({
    RunLifecycleManager? runLifecycle,
    DifficultyManager? difficulty,
    DailyRewardManager? dailyReward,
    LeaderboardManager? leaderboard,
  })  : runLifecycle = runLifecycle ?? RunLifecycleManager(),
        difficulty = difficulty ?? DifficultyManager(),
        dailyReward = dailyReward ?? DailyRewardManager(),
        leaderboard = leaderboard ?? LeaderboardManager();

  /// Called every frame from the game layer (GameScreen / loop).
  void update(double dt) {
    difficulty.update(dt);
  }

  /// ============================================================
  /// Persistence: Daily Reward
  /// ============================================================
  Future<void> loadDailyReward() async {
    final prefs = await SharedPreferences.getInstance();
    final epoch = prefs.getInt(_dailyClaimKey);

    if (epoch == null) {
      dailyReward.restoreLastClaim(null);
      return;
    }

    dailyReward.restoreLastClaim(
      DateTime.fromMillisecondsSinceEpoch(epoch),
    );
  }

  Future<void> saveDailyReward() async {
    final prefs = await SharedPreferences.getInstance();
    final claim = dailyReward.lastClaimTime;

    if (claim == null) return;

    await prefs.setInt(
      _dailyClaimKey,
      claim.millisecondsSinceEpoch,
    );
  }

  /// ============================================================
  /// Leaderboard submit helper (called when run ends)
  /// ============================================================
  Future<int?> submitLatestRunToLeaderboard() async {
    final summary = runLifecycle.latestSummary;
    if (summary == null) return null;

    final entry = LeaderboardEntry(
      score: summary.score,
      worldReached: summary.worldReached,
      accuracy01: summary.accuracy01,
      bestStreak: summary.bestStreak,
      timestamp: summary.endTime,
    );

    return leaderboard.submit(entry);
  }
}
