/// ===============================================================
/// MODEL: DailyRewardModel
/// ===============================================================
///
/// Represents the reward granted when claiming daily reward.
/// This is pure data — no logic.
/// ===============================================================
class DailyRewardModel {
  final int coins;
  final int bonusPoints;

  const DailyRewardModel({
    required this.coins,
    required this.bonusPoints,
  });
}
