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

  static const int maxEscapesBeforeFail = 3;
  static const int maxMissesBeforeFail = 10;

  int _escapeCount = 0;
  int _missCount = 0;
  bool _ended = false;

  void reset() {
    _escapeCount = 0;
    _missCount = 0;
    _ended = false;
  }

  /// Register player input ONLY
  void registerTap({required bool hit}) {
    if (_ended) return;

    momentum.registerTap(hit: hit);

    if (hit) {
      gameState.tapPulse = true;
      _missCount = 0;
    } else {
      _missCount++;
      _checkFail();
    }
  }

  void update(List<Balloon> balloons, double dt) {
    if (_ended) return;

    final double escapeY = gameState.viewportHeight + 24.0;
    int escapedThisFrame = 0;

    balloons.removeWhere((b) {
      if (b.y > escapeY) {
        escapedThisFrame++;
        return true;
      }
      return false;
    });

    if (escapedThisFrame > 0) {
      _escapeCount += escapedThisFrame;

      gameState.logEvent(
        DebugEventType.run,
        'ESCAPE count=$_escapeCount escapedThisFrame=$escapedThisFrame',
      );

      _checkFail();
    }
  }

  void _checkFail() {
    if (_ended) return;

    if (_escapeCount >= maxEscapesBeforeFail) {
      _endRun('escape');
    } else if (_missCount >= maxMissesBeforeFail) {
      _endRun('miss');
    }
  }

  void _endRun(String reason) {
    if (_ended) return;
    _ended = true;

    gameState.logEvent(
      DebugEventType.run,
      'RUN END reason=$reason escapes=$_escapeCount misses=$_missCount',
    );
  }
}
