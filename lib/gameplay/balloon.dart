/// Balloon
///
/// Gameplay entity placeholder.
/// Contains identity, classification, and minimal state.
///
/// Step 10: classification added (no behavior)
/// Step 11-1: state added (no behavior)
enum BalloonType {
  basic,
}

class Balloon {
  final String id;
  final BalloonType type;

  /// Smallest gameplay state: whether this balloon has been popped.
  final bool isPopped;

  Balloon({
    required this.id,
    required this.type,
    this.isPopped = false,
  });
}
