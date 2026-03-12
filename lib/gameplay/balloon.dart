import 'dart:math';
import 'package:balloon_burst/game/balloon_type.dart';

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

  /// Balloon behavior type (Step 1)
  final BalloonType type;

  const Balloon({
    required this.id,
    this.isPopped = false,
    required this.y,
    this.xOffset = 0.0,
    this.baseXOffset = 0.0,
    this.phase = 0.0,
    this.type = BalloonType.standard,
  });

  Balloon pop() => Balloon(
        id: id,
        isPopped: true,
        y: y,
        xOffset: xOffset,
        baseXOffset: baseXOffset,
        phase: phase,
        type: type,
      );

  Balloon movedBy(double dy) => Balloon(
        id: id,
        isPopped: isPopped,
        y: y + dy,
        xOffset: xOffset,
        baseXOffset: baseXOffset,
        phase: phase,
        type: type,
      );

  Balloon withXOffset(double newX) => Balloon(
        id: id,
        isPopped: isPopped,
        y: y,
        xOffset: newX,
        baseXOffset: baseXOffset,
        phase: phase,
        type: type,
      );

  /// Micro speed variance per balloon.
  /// Deterministic and stable: derived from phase.
  /// Range ~[0.92 .. 1.08]
  double get riseSpeedMultiplier {
    final m = 1.0 + sin(phase) * 0.10;
    return m.clamp(0.92, 1.08);
  }

  /// Horizontal drift + micro wobble
  /// This is the Fruit Ninja style motion trick.
  double driftedX({
    required double amplitude,
    required double frequency,
  }) {
    final drift = sin(phase + y * frequency) * amplitude;

    // ✨ micro wobble (very subtle)
    final wobble = sin(phase + y * frequency * 0.6) * amplitude * 0.15;

    return baseXOffset + drift + wobble;
  }

  /// Rising Worlds spawn helper
  /// Balloons spawn BELOW the viewport and rise upward.
  static Balloon spawnAt(
    int index, {
    required int total,
    required int tier,
    required double viewportHeight,
    BalloonType type = BalloonType.standard,
  }) {
    final rand = Random(index * 997 + tier * 7919);

    final clusterSpread = 0.22;
    final baseX = (rand.nextDouble() * 2 - 1) * clusterSpread;

    final spacing = max(40.0, 70.0 - tier * 3.0);

    final startY = viewportHeight - (index * spacing);

    final phase = rand.nextDouble() * pi * 2;

    return Balloon(
      id: 'balloon_$index',
      y: startY,
      xOffset: baseX,
      baseXOffset: baseX,
      phase: phase,
      type: type,
    );
  }
}
