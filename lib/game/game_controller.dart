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
  int _missCount = 0;
  bool _ended = false;

  static const int maxEscapesBeforeFail = 3;
  static const int maxMissesBeforeFail = 10;

  void reset() {
    _escapeCount = 0;
    _missCount = 0;
    _ended = false;
    gameState.isGameOver = false;
    gameState.endReason = null;
  }

  /// Register player input
  void registerTap({required bool hit}) {
    if (_ended) return;

    momentum.registerTap(hit: hit);

    if (hit) {
      gameState.tapPulse = true;
    } else {
      _missCount++;
      _checkFail();
    }
  }

  void update(List<Balloon> balloons, double dt) {
    if (_ended) return;

    final double escapeY = gameState.viewportHeight + 24.0;
    int escapedThisFrame = 0;

    for (final b in balloons) {
      if (b.y > escapeY) {
        escapedThisFrame++;
      }
    }

    if (escapedThisFrame > 0) {
      _escapeCount += escapedThisFrame;
      momentum.registerTap(hit: false);
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
    _ended = true;
    gameState.isGameOver = true;
    gameState.endReason = reason;
  }
}
