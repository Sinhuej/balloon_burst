import 'package:flutter/foundation.dart';

import '../gameplay/gameplay_world.dart';
import '../gameplay/balloon.dart';

import '../engine/momentum/momentum_controller.dart';
import '../engine/tier/tier_controller.dart';
import '../engine/speed/speed_curve.dart';
import '../engine/scroll/game_scroller.dart';

class GameController {
  final ValueNotifier<GameplayWorld?> world =
      ValueNotifier<GameplayWorld?>(null);

  final MomentumController momentum = MomentumController();
  final TierController tier = TierController();
  final SpeedCurve speedCurve = const SpeedCurve();
  final GameScroller scroller = GameScroller();

  double _lastScrollY = 0.0;

  static const int baseBalloonCount = 5;

  void start() {
    _spawnFreshWorld(baseBalloonCount);

    momentum.reset();
    tier.reset();
    scroller.reset();
    _lastScrollY = 0.0;
  }

  void update(double dt) {
    final w = world.value;
    if (w == null) return;

    momentum.update(dt);
    tier.update(momentum.momentum);

    final speed = speedCurve.speedForTier(tier.currentTier);
    scroller.update(dt, speed);

    final dy = scroller.scrollY - _lastScrollY;
    _lastScrollY = scroller.scrollY;

    var nextWorld = w.applyScroll(dy);

    // 🔑 STEP 27-2: recovery rule
    if (nextWorld.balloons.every((b) => b.isPopped)) {
      _spawnFreshWorld(baseBalloonCount);
      return;
    }

    world.value = nextWorld;
  }

  void _spawnFreshWorld(int count) {
    final balloons = List<Balloon>.generate(
      count,
      (i) => Balloon.spawnAt(i),
    );
    world.value = GameplayWorld(balloons: balloons);
    scroller.reset();
    _lastScrollY = 0.0;
  }

  void onBalloonHit() {
    momentum.registerTap(hit: true);
  }

  void onMiss() {
    momentum.registerTap(hit: false);
  }
}
