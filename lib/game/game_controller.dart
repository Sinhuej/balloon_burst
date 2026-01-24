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

  // 🔔 Run-end callback (replay feedback, UI, etc.)
  final void Function(int world)? onRunEnd;

  GameController({
    required this.momentum,
    required this.tier,
    required this.speed,
    required this.gameState,
    this.onRunEnd,
  });

  int _escapeCount = 0;
  static const int maxEscapesBeforeFail = 3;

  void reset() {
    _escapeCount = 0;
  }

  /// Register player input
  void registerTap({required bool hit}) {
    momentum.registerTap(hit: hit);

    // One-frame visual feedback only
    if (hit) {
      gameState.tapPulse = true;
    }
  }

  void update(List<Balloon> balloons, double dt) {
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
    }

    // 🚨 RUN ENDS HERE
    if (_escapeCount >= maxEscapesBeforeFail) {
      onRunEnd?.call(gameState.currentWorld);

      // prevent double-fire
      _escapeCount = 0;
    }
  }
}
