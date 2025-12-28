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
  static const int maxBalloonCount = 10;

  void start() {
    momentum.reset();
    tier.reset();
    scroller.reset();
    _lastScrollY = 0.0;

    _spawnFreshWorld(_balloonCountForTier(1));
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

    final nextWorld = w.applyScroll(dy);

    // Respawn when all balloons are popped
    if (nextWorld.balloons.every((b) => b.isPopped)) {
      final count = _balloonCountForTier(tier.currentTier);
      _spawnFreshWorld(count);
      return;
    }

    world.value = nextWorld;
  }

  int _balloonCountForTier(int tier) {
    final extra = ((tier - 1) ~/ 2); // +1 every 2 tiers
    final count = baseBalloonCount + extra;
    return count.clamp(baseBalloonCount, maxBalloonCount);
  }

  void _spawnFreshWorld(int count) {
    final currentTier = tier.currentTier;

    final balloons = List<Balloon>.generate(
      count,
      (i) => Balloon.spawnAt(
        i,
        total: count,
        tier: currentTier,
      ),
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
