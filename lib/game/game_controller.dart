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
    gameState.logEvent(DebugEventType.run, 'RUN reset');
  }

  /// Register player input
  void registerTap({required bool hit}) {
    momentum.registerTap(hit: hit);

    if (hit) {
      _missStreak = 0;
      gameState.tapPulse = true;
      gameState.logEvent(DebugEventType.tap, 'HIT');
    } else {
      _missStreak++;
      gameState.logEvent(
        DebugEventType.tap,
        'MISS missStreak=$_missStreak',
      );
    }

    _checkFail();
  }

  void update(List<Balloon> balloons, double dt) {
    if (gameState.isGameOver) return;

    // Rising Worlds:
    // Balloons escape when they go ABOVE the top of the screen
    const double escapeMargin = 24.0;
    int escapedThisFrame = 0;

    balloons.removeWhere((b) {
      if (b.y < -escapeMargin) {
        escapedThisFrame++;
        return true;
      }
      return false;
    });

    if (escapedThisFrame > 0) {
      _escapeCount += escapedThisFrame;
      _missStreak += escapedThisFrame;

      momentum.registerTap(hit: false);

      gameState.logEvent(
        DebugEventType.run,
        'ESCAPE count=$_escapeCount escapedThisFrame=$escapedThisFrame missStreak=$_missStreak',
      );

      _checkFail();
    }
  }

  void _checkFail() {
    if (gameState.isGameOver) return;

    if (_escapeCount >= maxEscapesBeforeFail) {
      gameState.isGameOver = true;
      gameState.endReason = 'escape';
      gameState.logEvent(
        DebugEventType.run,
        'RUN END reason=escape escapes=$_escapeCount',
      );
    } else if (_missStreak >= maxMissStreakBeforeFail) {
      gameState.isGameOver = true;
      gameState.endReason = 'miss_streak';
      gameState.logEvent(
        DebugEventType.run,
        'RUN END reason=miss_streak missStreak=$_missStreak',
      );
    }
  }
}
