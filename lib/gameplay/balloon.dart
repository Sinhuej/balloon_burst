/// Balloon
///
/// Gameplay entity placeholder.
/// Contains identity and classification only.
///
/// Step 10: classification added (no behavior)
enum BalloonType {
  basic,
}

class Balloon {
  final String id;
  final BalloonType type;

  Balloon({
    required this.id,
    required this.type,
  });
}
