import 'daily_reward_model.dart';

/// ===============================================================
/// MODEL: DailyRewardStatus
/// ===============================================================
///
/// Snapshot exposed to UI.
/// UI reads this only.
/// No calculations in UI.
/// ===============================================================
class DailyRewardStatus {
  final bool isAvailable;
  final Duration timeRemaining;

  final int currentWorldLevel;

  final DailyRewardModel computedReward;

  const DailyRewardStatus({
    required this.isAvailable,
    required this.timeRemaining,
    required this.currentWorldLevel,
    required this.computedReward,
  });
}
