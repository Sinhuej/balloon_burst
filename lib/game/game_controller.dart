import 'package:balloon_burst/engine/momentum/momentum_controller.dart';
import 'package:balloon_burst/engine/tier/tier_controller.dart';
import 'package:balloon_burst/engine/speed/speed_curve.dart';
import 'package:balloon_burst/gameplay/balloon.dart';

class GameController {
  final MomentumController momentum;
  final TierController tier;
  final SpeedCurve speed;

  /// Screen height in world coordinates (provided by caller)
  double screenHeight;

  GameController({
    required this.momentum,
    required this.tier,
    required this.speed,
    required this.screenHeight,
  });

  int _escapeCount = 0;
  static const int maxEscapesBeforeFail = 3;

  void reset() {
    _escapeCount = 0;
  }

  void update(List<Balloon> balloons, double dt) {
    bool escapedThisFrame = false;

    // Viewport-aware escape threshold (bottom + small buffer)
    final double escapeY = screenHeight + 24.0;

    for (final b in balloons) {
      if (b.y > escapeY) {
        escapedThisFrame = true;
        _escapeCount += 1;
      }
    }

    if (escapedThisFrame) {
      momentum.registerTap(hit: false);
    }

    if (_escapeCount >= maxEscapesBeforeFail) {
      // Existing failure handling remains unchanged
    }
  }
}
