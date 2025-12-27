/// Balloon
///
/// Immutable value object representing a single balloon in the world.
class Balloon {
  final String id;
  final bool isPopped;

  /// Vertical position in world units.
  final double y;

  const Balloon({
    required this.id,
    this.isPopped = false,
    this.y = 0.0,
  });

  Balloon pop() => Balloon(
        id: id,
        isPopped: true,
        y: y,
      );

  Balloon movedBy(double dy) => Balloon(
        id: id,
        isPopped: isPopped,
        y: y + dy,
      );

  /// Deterministic spawn helper.
  static Balloon spawnAt(int index) {
    return Balloon(
      id: 'balloon_$index',
      y: -index * 60.0, // staggered spawn vertically
    );
  }
}
