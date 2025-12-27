import '../gameplay/gameplay_world.dart';
import '../gameplay/balloon.dart';

import '../engine/momentum/momentum_controller.dart';
import '../engine/tier/tier_controller.dart';
import '../engine/speed/speed_curve.dart';
import '../engine/scroll/game_scroller.dart';

/// GameController
/// --------------
/// Owns high-level game state and core TapJunkie engine signals.
/// Momentum → Tier → Speed → Scroll are now fully wired.
/// Gameplay does not yet react to scroll (safe staging).
class GameController {
  GameplayWorld? gameplayWorld;

  /// Core TapJunkie systems
  final MomentumController momentum = MomentumController();
  final TierController tier = TierController();
  final SpeedCurve speedCurve = const SpeedCurve();
  final GameScroller scroller = GameScroller();

  double _logTimer = 0.0;

  void start() {
    final List<Balloon> balloons = List.generate(
      5,
      (i) => Balloon(
        id: 'balloon_$i',
      ),
    );

    gameplayWorld = GameplayWorld(
      balloons: balloons,
    );

    momentum.reset();
    tier.reset();
    scroller.reset();
    _logTimer = 0.0;
  }

  /// Called every frame / tick by the game loop.
  void update(double dt) {
    momentum.update(dt);
    tier.update(momentum.momentum);

    final speed = speedCurve.speedForTier(tier.currentTier);
    scroller.update(dt, speed);

    // Temporary debug logging (safe, removable)
    _logTimer += dt;
    if (_logTimer >= 1.0) {
      _logTimer = 0.0;
      // ignore: avoid_print
      print(
        '[Motion] tier=${tier.currentTier} '
        'speed=${speed.toStringAsFixed(1)} '
        'scrollY=${scroller.scrollY.toStringAsFixed(1)}',
      );
    }
  }

  /// Successful balloon hit.
  void onBalloonHit({double accuracyWeight = 1.0}) {
    momentum.registerTap(
      hit: true,
      accuracyWeight: accuracyWeight,
    );
  }

  /// Missed or incorrect tap.
  void onMiss() {
    momentum.registerTap(hit: false);
  }
}
