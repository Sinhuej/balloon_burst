import '../gameplay/gameplay_world.dart';

enum GameState {
  idle,
  running,
  ended,
}

class GameController {
  GameState _state = GameState.idle;
  GameState get state => _state;

  GameplayWorld? gameplayWorld;

  void start() {
    _state = GameState.running;
    gameplayWorld = GameplayWorld();
  }

  void stop() {
    _state = GameState.ended;
    gameplayWorld = null;
  }

  void reset() {
    _state = GameState.idle;
    gameplayWorld = null;
  }
}
