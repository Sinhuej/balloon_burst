import 'package:balloon_burst/engine/momentum/momentum_controller.dart';
import 'package:balloon_burst/engine/tier/tier_controller.dart';
import 'package:balloon_burst/engine/speed/speed_curve.dart';
import 'package:balloon_burst/gameplay/balloon.dart';
import 'package:balloon_burst/game/game_state.dart';

class GameController {
  final MomentumController momentum;
  final TierController tier;
  final SpeedCurve speed;
  final GameState gameState;

  GameController({
    required this.momentum,
    required this.tier,
    required this.speed,
    required this.gameState,
  });

  int _escapeCount = 0;
  int _missStreak = 0;

  static const int maxEscapesBeforeFail = 3;
  static const int maxMissStreakBeforeFail = 10;

  void reset() {
    _escapeCount = 0;
    _missStreak = 0;
    gameState.resetRun();
  }

  /// Register player input
  void registerTap({required bool hit}) {
    momentum.registerTap(hit: hit);

    if (hit) {
      _missStreak = 0;
      gameState.tapPulse = true;
    } else {
      _missStreak++;
    }

    _checkFail();
  }

  void update(List<Balloon> balloons, double dt) {
    if (gameState.isGameOver) return;

    bool escapedThisFrame = false;
    final double escapeY = gameState.viewportHeight + 24.0;

    for (final b in balloons) {
      if (b.y > escapeY) {
        escapedThisFrame = true;
        _escapeCount++;
      }
    }

    if (escapedThisFrame) {
      momentum.registerTap(hit: false);
      _missStreak++;
      _checkFail();
    }
  }

  void _checkFail() {
    if (gameState.isGameOver) return;

    if (_escapeCount >= maxEscapesBeforeFail) {
      gameState.isGameOver = true;
      gameState.endReason = 'escape';
      gameState.log('RUN END: too many escapes');
    } else if (_missStreak >= maxMissStreakBeforeFail) {
      gameState.isGameOver = true;
      gameState.endReason = 'miss_streak';
      gameState.log('RUN END: miss streak');
    }
  }
}
