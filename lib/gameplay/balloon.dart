import 'dart:math';

/// Balloon
///
/// Immutable value object representing a single balloon.
class Balloon {
  final String id;
  final bool isPopped;

  /// Vertical position in world units.
  final double y;

  /// Horizontal offset from center (-1..1 range scaled by renderer).
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

  /// Deterministic spawn helper with horizontal spread.
  static Balloon spawnAt(int index, {int total = 5}) {
    final spread = max(1, total - 1);
    final normalized = (index / spread) * 2 - 1; // -1 .. +1

    return Balloon(
      id: 'balloon_$index',
      y: -index * 60.0,
      xOffset: normalized * 0.6, // control horizontal spread
    );
  }
}
