// lib/tj_engine/engine/tj_engine.dart

import 'core/difficulty_manager.dart';
import 'run/run_lifecycle_manager.dart';
import 'daily/daily_reward_manager.dart';
import 'leaderboard/leaderboard_manager.dart';
import 'leaderboard/leaderboard_entry.dart';
import 'wallet/wallet_manager.dart';
import 'audio/audio_settings_manager.dart';
import 'daily/models/daily_reward_model.dart';

class TJEngine {
  final RunLifecycleManager runLifecycle;
  final DifficultyManager difficulty;
  final DailyRewardManager dailyReward;
  final LeaderboardManager leaderboard;
  final AudioSettingsManager audio;
  final WalletManager wallet;

  TJEngine({
    RunLifecycleManager? runLifecycle,
    DifficultyManager? difficulty,
    DailyRewardManager? dailyReward,
    LeaderboardManager? leaderboard,
    AudioSettingsManager? audio,
    WalletManager? wallet,
  })  : runLifecycle = runLifecycle ?? RunLifecycleManager(),
        difficulty = difficulty ?? DifficultyManager(),
        dailyReward = dailyReward ?? DailyRewardManager(),
        leaderboard = leaderboard ?? LeaderboardManager(),
        audio = audio ?? AudioSettingsManager(),
        wallet = wallet ?? WalletManager();

  void update(double dt) {
    difficulty.update(dt);
  }

  /// Load all engine subsystems that require async storage.
  Future<void> loadAll() async {
    await leaderboard.load();
    await dailyReward.load();
    await audio.load();
    await wallet.load();
  }

 /// Claim daily reward and credit wallet.
  Future<DailyRewardModel?> claimDailyRewardAndCredit({
    required int currentWorldLevel,
  }) async {
    final reward = dailyReward.claim(
      currentWorldLevel: currentWorldLevel,
    );

    if (reward == null) return null;

    await wallet.addCoins(reward.coins);

    return reward;
  }

  /// Back-compat method (safe)
  Future<void> loadDailyReward() async {
    await dailyReward.load();
  }

  /// Audio helpers
  bool get isMuted => audio.muted;

  Future<void> setMuted(bool value) async {
    await audio.setMuted(value);
  }

  Future<bool> toggleMute() async {
    return audio.toggleMuted();
  }

  /// Submit latest run to leaderboard
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
