import 'dart:math';

/// Balloon
///
/// Immutable value object representing a single balloon.
class Balloon {
  final String id;
  final bool isPopped;

  /// Vertical position in world units.
  final double y;

  /// Current horizontal offset from center (used by renderer + tap hit logic).
  final double xOffset;

  /// Spawn/base offset (sway is applied around this).
  final double baseXOffset;

  /// Unique phase per balloon for deterministic motion.
  final double phase;

  const Balloon({
    required this.id,
    this.isPopped = false,
    this.y = 0.0,
    this.xOffset = 0.0,
    this.baseXOffset = 0.0,
    this.phase = 0.0,
  });

  Balloon pop() => Balloon(
        id: id,
        isPopped: true,
        y: y,
        xOffset: xOffset,
        baseXOffset: baseXOffset,
        phase: phase,
      );

  Balloon movedBy(double dy) => Balloon(
        id: id,
        isPopped: isPopped,
        y: y + dy,
        xOffset: xOffset,
        baseXOffset: baseXOffset,
        phase: phase,
      );

  Balloon withXOffset(double newX) => Balloon(
        id: id,
        isPopped: isPopped,
        y: y,
        xOffset: newX,
        baseXOffset: baseXOffset,
        phase: phase,
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
    final baseSpread = 0.3 + (tier * 0.03);

    final baseX = (rand.nextDouble() * 2 - 1) * baseSpread;

    // Vertical spacing compresses as tier rises
    final spacing = max(40.0, 70.0 - tier * 3.0);

    // Unique deterministic phase (0..2π)
    final phase = rand.nextDouble() * pi * 2;

    return Balloon(
      id: 'balloon_$index',
      y: -index * spacing,
      xOffset: baseX,
      baseXOffset: baseX,
      phase: phase,
    );
  }
}
