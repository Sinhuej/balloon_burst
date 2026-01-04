import 'dart:math';

/// Balloon
///
/// Immutable value object representing a single balloon.
/// Rising Worlds version: balloons spawn BELOW the screen and rise upward.
class Balloon {
  final String id;
  final bool isPopped;

  /// Vertical position in world units.
  final double y;

  /// Horizontal offset from center (used by renderer + tap hit logic).
  final double xOffset;

  /// Spawn/base offset (sway is applied around this).
  final double baseXOffset;

  /// Unique phase per balloon for deterministic motion.
  final double phase;

  const Balloon({
    required this.id,
    this.isPopped = false,
    required this.y,
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

  /// Rising Worlds spawn helper
  /// Balloons spawn BELOW the viewport and rise upward.
  static Balloon spawnAt(
    int index, {
    required int total,
    required int tier,
    required double viewportHeight,
  }) {
    final rand = Random(index * 997 + tier * 7919);

    // Horizontal spread grows with tier
    final baseSpread = 0.3 + (tier * 0.03);
    final baseX = (rand.nextDouble() * 2 - 1) * baseSpread;

    // Vertical spacing compresses as tier rises
    final spacing = max(40.0, 70.0 - tier * 3.0);

    // Spawn BELOW screen
    final startY = viewportHeight + (index * spacing);

    // Unique deterministic phase (0..2π)
    final phase = rand.nextDouble() * pi * 2;

    return Balloon(
      id: 'balloon_$index',
      y: startY,
      xOffset: baseX,
      baseXOffset: baseX,
      phase: phase,
    );
  }
}
