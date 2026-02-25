// lib/tj_engine/engine/tj_engine.dart

import 'core/difficulty_manager.dart';
import 'run/run_lifecycle_manager.dart';
import 'daily/daily_reward_manager.dart';
import 'leaderboard/leaderboard_manager.dart';
import 'leaderboard/leaderboard_entry.dart';

class TJEngine {
  final RunLifecycleManager runLifecycle;
  final DifficultyManager difficulty;
  final DailyRewardManager dailyReward;
  final LeaderboardManager leaderboard;

  TJEngine({
    RunLifecycleManager? runLifecycle,
    DifficultyManager? difficulty,
    DailyRewardManager? dailyReward,
    LeaderboardManager? leaderboard,
  })  : runLifecycle = runLifecycle ?? RunLifecycleManager(),
        difficulty = difficulty ?? DifficultyManager(),
        dailyReward = dailyReward ?? DailyRewardManager(),
        leaderboard = leaderboard ?? LeaderboardManager();

  void update(double dt) {
    difficulty.update(dt);
  }

  /// ============================================================
  /// App-start loads (call from app bootstrap).
  /// ============================================================
  Future<void> loadDailyReward() async {
    await dailyReward.load();
  }

  /// ============================================================
  /// Submit latest run to leaderboard
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
