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

    gameState.logEvent(
      DebugEventType.tap,
      'tap=(${tap.dx.toStringAsFixed(1)},${tap.dy.toStringAsFixed(1)})',
    );

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

        gameState.logEvent(
          DebugEventType.hit,
          'world=${spawner.currentWorld} '
          'tap=(${tap.dx.toStringAsFixed(1)},${tap.dy.toStringAsFixed(1)}) '
          'balloon=(${bx.toStringAsFixed(1)},${by.toStringAsFixed(1)}) '
          'dx=${dx.toStringAsFixed(1)} dy=${dy.toStringAsFixed(1)} '
          'dist=${dist.toStringAsFixed(1)} r=${(balloonRadius + hitForgiveness).toStringAsFixed(1)}',
        );

        surge.maybeTrigger(
          currentWorld: spawner.currentWorld,
          totalPops: spawner.totalPops,
          world2Pops: BalloonSpawner.world2Pops,
          world3Pops: BalloonSpawner.world3Pops,
          world4Pops: BalloonSpawner.world4Pops,
        );
        break;
      }
    }

    if (!hit) {
      spawner.registerMiss();

      gameState.logEvent(
        DebugEventType.miss,
        'world=${spawner.currentWorld} '
        'tap=(${tap.dx.toStringAsFixed(1)},${tap.dy.toStringAsFixed(1)}) '
        'recentMisses=${spawner.recentMisses} '
        'accuracy=${spawner.accuracyModifier.toStringAsFixed(2)}',
      );
    }

    controller.registerTap(hit: hit);
  }
}
