/// Balloon
///
/// Immutable value object.
class Balloon {
  final String id;
  final bool isPopped;

  const Balloon({
    required this.id,
    this.isPopped = false,
  });

  Balloon pop() => Balloon(id: id, isPopped: true);

  /// FREEZE FIX
  /// Deterministic spawn helper.
  static Balloon spawnAt(int index) {
    return Balloon(id: 'balloon_$index');
  }
}
