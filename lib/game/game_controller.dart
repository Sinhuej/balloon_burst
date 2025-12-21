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
}
