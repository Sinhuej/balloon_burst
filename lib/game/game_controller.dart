import '../gameplay/gameplay_world.dart';

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
  /// Exists only to keep CI green.
  /// Do NOT use for logic.
  GameControllerState get state =>
      _world == null ? GameControllerState.stopped : GameControllerState.running;

  /// Starts a new game session
  void start() {
    _world = GameplayWorld.initial();
  }

  /// Stops the current game session
  void stop() {
    _world = null;
  }

  /// LEGACY UI COMPATIBILITY
  /// Alias for stop() — no new behavior.
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

    _world = world.applyPopAt(index);
  }
}

/// LEGACY ENUM (UI ONLY)
enum GameControllerState {
  stopped,
  running,
}
