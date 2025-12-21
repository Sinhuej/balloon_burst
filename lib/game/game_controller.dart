import '../gameplay/gameplay_world.dart';
import '../gameplay/balloon.dart';

/// GameController
///
/// Responsibility:
/// - Owns the current GameplayWorld reference
/// - Initiates explicit intent requests
/// - Never mutates the world directly
///
/// NOTE:
/// - No automatic behavior
/// - No ticking
/// - No side effects
class GameController {
  GameplayWorld? _world;

  /// Read-only access to current world
  GameplayWorld? get gameplayWorld => _world;

  /// LEGACY UI COMPATIBILITY (read-only)
  GameControllerState get state =>
      _world == null ? GameControllerState.stopped : GameControllerState.running;

  /// Starts a new game session
  ///
  /// Explicit, non-magical world creation.
  void start() {
    _world = const GameplayWorld(balloons: <Balloon>[]);
  }

  /// Stops the current game session
  void stop() {
    _world = null;
  }

  /// LEGACY UI COMPATIBILITY
  void reset() {
    stop();
  }

  /// STEP 14-1
  ///
  /// Explicit intent passthrough:
  /// Requests that the world attempt to pop a balloon at [index].
  ///
  /// Rules:
  /// - If no world exists, do nothing
  /// - World decides validity
  /// - World returns a new instance
  /// - Controller replaces its reference
  void requestPopAt(int index) {
    final world = _world;
    if (world == null) return;

    _world = world.popBalloonAt(index);
  }

  /// STEP 15-1
  ///
  /// First automated intent trigger (deterministic):
  /// Pop the first unpopped balloon, if any.
  ///
  /// Rules:
  /// - If no world exists, do nothing
  /// - If all balloons are already popped (or none exist), do nothing
  /// - This method does NOT pop directly; it calls the intent boundary
  void autoPopFirstAvailable() {
    final world = _world;
    if (world == null) return;

    final index = world.balloons.indexWhere((b) => !b.isPopped);
    if (index < 0) return;

    requestPopAt(index);
  }
}

/// LEGACY ENUM (UI ONLY)
enum GameControllerState {
  stopped,
  running,
}
