import '../gameplay/gameplay_world.dart';
import '../gameplay/balloon.dart';

import '../engine/momentum/momentum_controller.dart';
import '../engine/tier/tier_controller.dart';
import '../engine/speed/speed_curve.dart';
import '../engine/scroll/game_scroller.dart';

class GameController {
  GameplayWorld? gameplayWorld;

  final MomentumController momentum = MomentumController();
  final TierController tier = TierController();
  final SpeedCurve speedCurve = const SpeedCurve();
  final GameScroller scroller = GameScroller();

  double _lastScrollY = 0.0;

  void start() {
    final List<Balloon> balloons = List.generate(
      5,
      (i) => Balloon.spawnAt(i),
    );

    gameplayWorld = GameplayWorld(balloons: balloons);

    momentum.reset();
    tier.reset();
    scroller.reset();
    _lastScrollY = 0.0;
  }

  void update(double dt) {
    momentum.update(dt);
    tier.update(momentum.momentum);

    final speed = speedCurve.speedForTier(tier.currentTier);
    scroller.update(dt, speed);

    final dy = scroller.scrollY - _lastScrollY;
    _lastScrollY = scroller.scrollY;

    gameplayWorld = gameplayWorld?.applyScroll(dy);
  }

  void onBalloonHit({double accuracyWeight = 1.0}) {
    momentum.registerTap(
      hit: true,
      accuracyWeight: accuracyWeight,
    );
  }

  void onMiss() {
    momentum.registerTap(hit: false);
  }
}
