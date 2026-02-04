import 'package:balloon_burst/game/game_state.dart'
    show GameState, DebugEventType;
import 'package:balloon_burst/gameplay/balloon.dart';

import 'package:balloon_burst/engine/momentum/momentum_controller.dart';
import 'package:balloon_burst/engine/tier/tier_controller.dart';
import 'package:balloon_burst/engine/speed/speed_curve.dart';

class GameController {
  final MomentumController momentum;
  final TierController tier;
  final SpeedCurve speed;
  final GameState gameState;

  bool isEnded = false;

  int _escapeCount = 0;
  int _missCount = 0;
  String _endReason = '';

  GameController({
    required this.momentum,
    required this.tier,
    required this.speed,
    required this.gameState,
  });

  int get escapeCount => _escapeCount;
  int get missCount => _missCount;
  String get endReason => _endReason;

  void update(List<Balloon> balloons, double dt) {
    momentum.update(dt);
    tier.update(dt);
    gameState.framesSinceStart++;
  }

  void registerEscapes(int count) {
    _escapeCount += count;

    gameState.log(
      'WORLD: ESCAPE +$count total=$_escapeCount',
      type: DebugEventType.miss,
    );

    if (_escapeCount >= 3) {
      endRun('escape');
    }
  }

  void registerTap({required bool hit}) {
    if (!hit) {
      _missCount++;

      gameState.log(
        'MISS: count=$_missCount',
        type: DebugEventType.miss,
      );

      if (_missCount >= 10) {
        endRun('miss');
      }
    }
  }

  void endRun(String reason) {
    if (isEnded) return;

    isEnded = true;
    _endReason = reason;

    gameState.log(
      'SYSTEM: RUN END reason=$reason escapes=$_escapeCount misses=$_missCount',
      type: DebugEventType.system,
    );
  }

  void reset() {
    isEnded = false;
    _escapeCount = 0;
    _missCount = 0;
    _endReason = '';

    momentum.reset();
    tier.reset();

    gameState.log(
      'SYSTEM: run reset',
      type: DebugEventType.system,
    );
  }
}
