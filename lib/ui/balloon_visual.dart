/// BalloonVisual (UI-only)
/// Presentation mapping derived from index & score.
class BalloonVisual {
  final String color;
  final double size;
  final String rarity;

  const BalloonVisual({
    required this.color,
    required this.size,
    required this.rarity,
  });

  static BalloonVisual fromIndexAndScore(int index, int score) {
    if (score >= 50) {
      return const BalloonVisual(color: 'purple', size: 1.2, rarity: 'Epic');
    }
    if (score >= 20) {
      return const BalloonVisual(color: 'blue', size: 1.1, rarity: 'Rare');
    }
    return const BalloonVisual(color: 'red', size: 1.0, rarity: 'Common');
    }
}
