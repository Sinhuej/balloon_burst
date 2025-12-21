/// Minimal gameplay controller scaffold.
/// Owns high-level game lifecycle state only.
/// No gameplay logic is implemented in Step 7A.

enum GameState {
  idle,
  running,
  ended,
}

class GameController {
  GameState _state = GameState.idle;

  GameState get state => _state;

  /// Start the game.
  /// No timers, no scoring, no side effects yet.
  void start() {
    _state = GameState.running;
  }

  /// End the game.
  /// No cleanup logic yet.
  void stop() {
    _state = GameState.ended;
  }

  /// Reset back to idle state.
  void reset() {
    _state = GameState.idle;
  }
}
