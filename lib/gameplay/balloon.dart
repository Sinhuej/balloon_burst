/// Balloon
///
/// Gameplay entity placeholder.
/// Contains identity, classification, and minimal state.
///
/// Step 10: classification added (no behavior)
/// Step 11-1: state added (no behavior)
/// Step 11-2: explicit state mutation added (pop)
enum BalloonType {
  basic,
}

class Balloon {
  final String id;
  final BalloonType type;

  /// Smallest gameplay state: whether this balloon has been popped.
  final bool isPopped;

  const Balloon({
    required this.id,
    required this.type,
    this.isPopped = false,
  });

  /// Explicit domain behavior: popping a balloon.
  /// Returns a new Balloon instance with isPopped set to true.
  Balloon pop() {
    return Balloon(
      id: id,
      type: type,
      isPopped: true,
    );
  }
}
