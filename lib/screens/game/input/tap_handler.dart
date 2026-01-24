import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:balloon_burst/gameplay/balloon.dart';
import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/game/balloon_spawner.dart';
import 'package:balloon_burst/game/game_controller.dart';
import '../effects/world_surge_pulse.dart';

class TapHandler {
  static void handleTap({
    required TapDownDetails details,
    required Size lastSize,
    required List<Balloon> balloons,
    required GameState gameState,
    required BalloonSpawner spawner,
    required GameController controller,
    required WorldSurgePulse surge,
    required double balloonRadius,
    required double hitForgiveness,
  }) {
    if (lastSize == Size.zero || balloons.isEmpty) return;

    final tap = details.localPosition;
    final centerX = lastSize.width / 2;

    bool hit = false;

    for (final b in List<Balloon>.from(balloons)) {
      final bx = centerX + (b.xOffset * lastSize.width * 0.5);
      final by = b.y;

      final dx = tap.dx - bx;
      final dy = tap.dy - by;
      final dist = sqrt(dx * dx + dy * dy);

      if (dist <= balloonRadius + hitForgiveness) {
        hit = true;
        balloons.remove(b);
        spawner.registerHit();

        surge.maybeTrigger(currentWorld: spawner.currentWorld, totalPops: spawner.totalPops, world2Pops: BalloonSpawner.world2Pops, world3Pops: BalloonSpawner.world3Pops, world4Pops: BalloonSpawner.world4Pops);
        break;
      }
    }

    if (!hit) {
      spawner.registerMiss();
    }

    controller.registerTap(hit: hit);
  }
}
