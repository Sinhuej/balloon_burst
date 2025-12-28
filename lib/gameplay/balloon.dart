import 'dart:math';

/// Balloon
///
/// Immutable value object representing a single balloon.
class Balloon {
  final String id;
  final bool isPopped;

  /// Vertical position in world units.
  final double y;

  /// Horizontal offset from center (-1..1 scaled by renderer).
  final double xOffset;

  const Balloon({
    required this.id,
    this.isPopped = false,
    this.y = 0.0,
    this.xOffset = 0.0,
  });

  Balloon pop() => Balloon(
        id: id,
        isPopped: true,
        y: y,
        xOffset: xOffset,
      );

  Balloon movedBy(double dy) => Balloon(
        id: id,
        isPopped: isPopped,
        y: y + dy,
        xOffset: xOffset,
      );

  /// Deterministic-but-chaotic spawn helper.
  /// Breaks diagonal patterns and increases density pressure by tier.
  static Balloon spawnAt(
    int index, {
    required int total,
    required int tier,
  }) {
    final rand = Random(index * 997 + tier * 7919);

    // Horizontal spread grows with tier
    final baseSpread = 0.3 + (tier * 0.03); // caps naturally via renderer

    final xOffset = (rand.nextDouble() * 2 - 1) * baseSpread;

    // Vertical spacing compresses as tier rises
    final spacing = max(40.0, 70.0 - tier * 3.0);

    return Balloon(
      id: 'balloon_$index',
      y: -index * spacing,
      xOffset: xOffset,
    );
  }
}
