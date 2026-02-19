import 'models/daily_reward_model.dart';
import 'models/daily_reward_status.dart';
import 'now_provider.dart';

/// ===============================================================
/// SYSTEM: DailyRewardManager
/// ===============================================================
///
/// ENGINE-OWNED.
/// No UI logic.
/// No Flutter imports.
/// Pure Dart.
///
/// RULE:
/// Reward available every 24 hours from last claim.
/// Not midnight reset.
/// ===============================================================
class DailyRewardManager {
  static const Duration claimInterval = Duration(hours: 24);

  final NowProvider _clock;

  DateTime? _lastClaimTime;

  DailyRewardManager({NowProvider? clock})
      : _clock = clock ?? SystemNowProvider();

  /// ============================================================
  /// Get current reward status snapshot.
  /// ============================================================
  DailyRewardStatus getStatus({
    required int currentWorldLevel,
  }) {
    final now = _clock.now();

    final lastClaim = _lastClaimTime;
    bool isAvailable;
    Duration remaining;

    if (lastClaim == null) {
      isAvailable = true;
      remaining = Duration.zero;
    } else {
      final nextEligible = lastClaim.add(claimInterval);
      if (now.isAfter(nextEligible)) {
        isAvailable = true;
        remaining = Duration.zero;
      } else {
        isAvailable = false;
        remaining = nextEligible.difference(now);
      }
    }

    final reward = _computeReward(currentWorldLevel);

    return DailyRewardStatus(
      isAvailable: isAvailable,
      timeRemaining: remaining,
      currentWorldLevel: currentWorldLevel,
      computedReward: reward,
    );
  }

  /// ============================================================
  /// Claim reward (if eligible).
  /// Returns reward or null if not available.
  /// ============================================================
  DailyRewardModel? claim({
    required int currentWorldLevel,
  }) {
    final status = getStatus(currentWorldLevel: currentWorldLevel);

    if (!status.isAvailable) return null;

    _lastClaimTime = _clock.now();

    return status.computedReward;
  }

  /// ============================================================
  /// Reward scaling logic (temporary numbers for now)
  /// Will be tuned later.
  /// ============================================================
  DailyRewardModel _computeReward(int worldLevel) {
    const baseCoins = 100;
    const perWorldBonus = 25;

    final coins = baseCoins + (worldLevel * perWorldBonus);

    return DailyRewardModel(
      coins: coins,
      bonusPoints: worldLevel * 5,
    );
  }
}
