class RunReward {
  final int baseCoins;
  final int popCoins;
  final int worldCoins;
  final int accuracyCoins;
  final int streakCoins;

  int get totalCoins =>
      baseCoins +
      popCoins +
      worldCoins +
      accuracyCoins +
      streakCoins;

  const RunReward({
    required this.baseCoins,
    required this.popCoins,
    required this.worldCoins,
    required this.accuracyCoins,
    required this.streakCoins,
  });
}
