// lib/tj_engine/engine/tj_engine.dart

import 'core/difficulty_manager.dart';
import 'run/run_lifecycle_manager.dart';
import 'daily/daily_reward_manager.dart';
import 'leaderboard/leaderboard_manager.dart';
import 'leaderboard/leaderboard_entry.dart';

// Audio settings
import 'audio/audio_settings_manager.dart';

class TJEngine {
  final RunLifecycleManager runLifecycle;
  final DifficultyManager difficulty;
  final DailyRewardManager dailyReward;
  final LeaderboardManager leaderboard;
  final AudioSettingsManager audio;

  TJEngine({
    RunLifecycleManager? runLifecycle,
    DifficultyManager? difficulty,
    DailyRewardManager? dailyReward,
    LeaderboardManager? leaderboard,
    AudioSettingsManager? audio,
  })  : runLifecycle = runLifecycle ?? RunLifecycleManager(),
        difficulty = difficulty ?? DifficultyManager(),
        dailyReward = dailyReward ?? DailyRewardManager(),
        leaderboard = leaderboard ?? LeaderboardManager(),
        audio = audio ?? AudioSettingsManager();

  void update(double dt) {
    difficulty.update(dt);
  }

  /// Load all engine subsystems that require async storage.
  /// Call once at app start.
  Future<void> loadAll() async {
    await leaderboard.load();
    await dailyReward.load();
    await audio.load();
  }

  /// Back-compat: your app calls this already.
  Future<void> loadDailyReward() async {
    await dailyReward.load();
  }

  /// Optional: allow UI to force-save if needed.
  Future<void> saveDailyReward() async {
    await dailyReward.save();
  }

  /// Audio helpers for UI.
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
