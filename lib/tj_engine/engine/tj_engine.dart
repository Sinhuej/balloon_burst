// lib/tj_engine/engine/tj_engine.dart

import 'core/difficulty_manager.dart';
import 'run/run_lifecycle_manager.dart';
import 'daily/daily_reward_manager.dart';
import 'leaderboard/leaderboard_manager.dart';

/// ===============================================================
/// SYSTEM: TJEngine (Engine Facade)
/// ===============================================================
///
/// PURPOSE:
/// Single entry point to TapJunkie engine systems.
///
/// IMPORTANT:
/// - Pure Dart (no Flutter imports)
/// - Games should access engine subsystems only through this facade
/// ===============================================================
class TJEngine {
  final RunLifecycleManager runLifecycle;
  final DifficultyManager difficulty;
  final DailyRewardManager dailyReward;

  // 🔥 NEW: Leaderboard system
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

  /// Called every frame from the game layer (GameScreen / Flame loop).
  void update(double dt) {
    difficulty.update(dt);
  }
}
