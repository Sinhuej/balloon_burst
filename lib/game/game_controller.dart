import 'dart:math';
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
  double _time = 0.0;

  static const int baseBalloonCount = 5;
  static const int maxBalloonCount = 10;

  // Placeholder world-space escape threshold (viewport binding comes in Step 28)
  static const double escapeY = 800.0;
  static const int maxEscapesBeforeFail = 3;

  int _escapeCount = 0;

  void start() {
    momentum.reset();
    tier.reset();
    scroller.reset();
    _lastScrollY = 0.0;
    _time = 0.0;
    _escapeCount = 0;

    _spawnFreshWorld(_balloonCountForTier(1));
  }

  void update(double dt) {
    final w = world.value;
    if (w == null) return;

    _time += dt;

    momentum.update(dt);
    tier.update(momentum.momentum);

    final speed = speedCurve.speedForTier(tier.currentTier);
    scroller.update(dt, speed);

    final dy = scroller.scrollY - _lastScrollY;
    _lastScrollY = scroller.scrollY;

    var nextWorld = w.applyScroll(dy);

    // Off-screen pressure + escape tracking
    final remaining = <Balloon>[];
    bool escapedThisFrame = false;

    for (final b in nextWorld.balloons) {
      if (b.isPopped) continue;

      if (b.y > escapeY) {
        escapedThisFrame = true;
        _escapeCount += 1;
        momentum.registerTap(hit: false);
      } else {
        remaining.add(b);
      }
    }

    if (escapedThisFrame) {
      nextWorld = GameplayWorld(balloons: remaining);
    }

    // FAILURE CONDITION
    if (_escapeCount >= maxEscapesBeforeFail) {
      _handleFail();
      return;
    }

    // ✅ STEP 27-3: Apply deterministic sway to active balloons
    final t = tier.currentTier;

    // Amplitude in "offset units" (renderer scales xOffset to pixels).
    // Starts gentle, ramps to noticeable.
    final amp = (0.06 + t * 0.01).clamp(0.06, 0.18);

    // Frequency in radians/sec-ish. Higher tiers sway faster.
    final freq = (0.9 + t * 0.08).clamp(0.9, 1.9);

    final updated = <Balloon>[];
    for (final b in nextWorld.balloons) {
      if (b.isPopped) {
        updated.add(b);
        continue;
      }

      // Sway around baseXOffset, unique per balloon via phase.
      var x = b.baseXOffset + sin((_time * freq) + b.phase) * amp;

      // Clamp to a safe range so balloons stay tappable & on-screen-ish.
      x = x.clamp(-1.2, 1.2);

      updated.add(b.withXOffset(x));
    }
    nextWorld = GameplayWorld(balloons: updated);

    // Respawn when no active balloons remain
    final hasActiveBalloons =
        nextWorld.balloons.any((b) => !b.isPopped);

    if (!hasActiveBalloons) {
      final count = _balloonCountForTier(tier.currentTier);
      _spawnFreshWorld(count);
      return;
    }

    world.value = nextWorld;
  }

  void _handleFail() {
    momentum.reset();
    tier.reset();
    scroller.reset();
    _lastScrollY = 0.0;
    _time = 0.0;
    _escapeCount = 0;

    _spawnFreshWorld(_balloonCountForTier(1));
  }

  int _balloonCountForTier(int tier) {
    final extra = ((tier - 1) ~/ 2);
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
