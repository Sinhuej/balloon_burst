import "../gameplay/gameplay_world.dart";
import "../gameplay/balloon.dart";

/// GameController
///
/// Responsibility:
/// - Owns the current GameplayWorld reference
/// - Initiates explicit intent requests
/// - Never mutates the world directly
class GameController {
  GameplayWorld? _world;

  GameplayWorld? get gameplayWorld => _world;

  /// Starts a new game session
  void start() {
    _world = const GameplayWorld(balloons: <Balloon>[]);
  }

  /// Stops the current game session
  void stop() {
    _world = null;
  }

  /// STEP 14-1
  /// Explicit intent passthrough
  void requestPopAt(int index) {
    final world = _world;
    if (world == null) return;

    _world = world.popBalloonAt(index);
  }

  /// STEP 15-1
  /// Deterministic automated intent
  void autoPopFirstAvailable() {
    final world = _world;
    if (world == null) return;

    final index =
        world.balloons.indexWhere((b) => !b.isPopped);
    if (index < 0) return;

    requestPopAt(index);
  }
}
