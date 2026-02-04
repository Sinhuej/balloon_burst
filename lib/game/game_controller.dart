import 'package:balloon_burst/debug/debug_log.dart';
import 'package:balloon_burst/game/game_state.dart';

class GameController {
  final GameState gameState;

  bool isEnded = false;
  int escapes = 0;
  int misses = 0;

  GameController({
    required this.gameState,
  });

  void registerEscape() {
    escapes++;
    gameState.log(
      'ESCAPE: total=$escapes',
      type: DebugEventType.miss,
    );
  }

  void registerMiss() {
    misses++;
    gameState.log(
      'MISS: total=$misses',
      type: DebugEventType.miss,
    );
  }

  void endRun(String reason) {
    isEnded = true;
    gameState.log(
      'RUN END reason=$reason escapes=$escapes misses=$misses',
      type: DebugEventType.system,
    );
  }

  void reset() {
    isEnded = false;
    escapes = 0;
    misses = 0;
    gameState.log(
      'SYSTEM: run reset',
      type: DebugEventType.system,
    );
  }
}
