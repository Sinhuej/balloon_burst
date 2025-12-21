import '../gameplay/gameplay_world.dart';
import '../gameplay/balloon.dart';

enum GameState {
  idle,
  running,
  stopped,
}

class GameController {
  GameState _state = GameState.idle;

  GameplayWorld? gameplayWorld;

  GameState get state => _state;

  void start() {
    _state = GameState.running;

    gameplayWorld = GameplayWorld(
      balloons: <Balloon>[],
    );
  }

  void stop() {
    _state = GameState.stopped;
    gameplayWorld = null;
  }

  /// Restores controller to a fresh running state.
  /// UI contract method — no gameplay logic.
  void reset() {
    stop();
    start();
  }
}
