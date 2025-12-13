// lib/engine/core/game_manager.dart

import 'states.dart';

// TapJunkie progression systems
import '../momentum/momentum_controller.dart';
import '../tier/tier_manager.dart';

typedef GameStateListener = void Function(GameState state);

/// Central controller for high-level game state & score.
/// Pure Dart – no Flutter imports – reusable across all TapJunkie games.
class GameManager {
  GameState _state = GameState.mainMenu;
  int _score = 0;
  int _highScore = 0;

  final List<GameStateListener> _listeners = [];

  GameState get state => _state;
  int get score => _score;
  int get highScore => _highScore;

  void addListener(GameStateListener listener) {
    _listeners.add(listener);
  }

  void removeListener(GameStateListener listener) {
    _listeners.remove(listener);
  }

  void _notify() {
    // Copy to avoid modification during iteration
    for (final listener in List<GameStateListener>.from(_listeners)) {
      listener(_state);
    }
  }

  void setState(GameState newState) {
    if (_state == newState) return;
    _state = newState;
    _notify();
  }

  /// Called when a new run begins.
  void start() {
    _score = 0;

    // Reset TapJunkie progression systems
    momentumController.reset();
    tierManager.reset();

    setState(GameState.playing);
  }

  /// Called when the player loses.
  void gameOver() {
    if (_score > _highScore) {
      _highScore = _score;
    }

    // Cleanly stop momentum so it doesn't leak between runs
    momentumController.reset();

    setState(GameState.gameOver);
  }

  /// Restart from the beginning of gameplay.
  void restart() {
    _score = 0;

    // Reset TapJunkie progression systems
    momentumController.reset();
    tierManager.reset();

    setState(GameState.playing);
  }

  /// Go back to the main menu.
  void backToMenu() {
    setState(GameState.mainMenu);
  }

  /// Adjust score (can be positive or negative).
  void addScore(int amount) {
    _score += amount;
    if (_score < 0) _score = 0;
  }

  /// Reset everything back to fresh state.
  void resetAll() {
    _score = 0;

    momentumController.reset();
    tierManager.reset();

    setState(GameState.mainMenu);
  }
}
