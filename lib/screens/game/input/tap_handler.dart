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
    bool hit = false;

    for (final b in balloons) {
      final dx = tap.dx - b.x;
      final dy = tap.dy - b.y;
      final dist = sqrt(dx * dx + dy * dy);

      if (dist <= balloonRadius + hitForgiveness) {
        hit = true;
        balloons.remove(b);
        spawner.registerHit(gameState);
        surge.maybeTrigger();
        break;
      }
    }

    if (!hit) {
      spawner.registerMiss(gameState);
    }

    controller.registerTap(hit: hit);
  }
}
