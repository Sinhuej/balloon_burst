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
  static const int maxEscapesBeforeFail = 3;

  void reset() {
    _escapeCount = 0;
  }

  void update(List<Balloon> balloons, double dt) {
    bool escapedThisFrame = false;

    final double escapeY = gameState.viewportHeight + 24.0;

    for (final b in balloons) {
      if (b.y > escapeY) {
        escapedThisFrame = true;
        _escapeCount += 1;
      }
    }

    if (escapedThisFrame) {
      momentum.registerTap(hit: false);
    }

    // Successful tap feedback (engine truth)
    if (momentum.lastTapWasHit) {
      gameState.tapPulse = true;
    }

    if (_escapeCount >= maxEscapesBeforeFail) {
      // existing failure handling
    }
  }
}
