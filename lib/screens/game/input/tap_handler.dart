import 'dart:math';

import 'package:flutter/material.dart';

import 'package:balloon_burst/audio/audio_player.dart';
import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/game/game_controller.dart';
import 'package:balloon_burst/game/balloon_spawner.dart';
import 'package:balloon_burst/gameplay/balloon.dart';

import 'package:balloon_burst/dev/dev_flags.dart';
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
    if (lastSize == Size.zero) return;

    final tapPos = details.localPosition;
    final centerX = lastSize.width / 2;

    bool hit = false;

    for (int i = 0; i < balloons.length; i++) {
      final b = balloons[i];
      if (b.isPopped) continue;

      final bx = centerX + (b.xOffset * lastSize.width * 0.5);
      final by = b.y;

      final dx = tapPos.dx - bx;
      final dy = tapPos.dy - by;
      final dist = sqrt(dx * dx + dy * dy);

      if (dist <= balloonRadius + hitForgiveness) {
        balloons[i] = b.pop();
        AudioPlayerService.playPop();
        spawner.registerPop(gameState);
        surge.maybeTrigger(
         totalPops: spawner.totalPops,
         currentWorld: spawner.currentWorld,
         world2Pops: BalloonSpawner.world2Pops,
         world3Pops: BalloonSpawner.world3Pops,
         world4Pops: BalloonSpawner.world4Pops,
       );
        hit = true;
        break;
      }
    }

    if (!hit) {
      spawner.registerMiss(gameState);

      // 🔎 Detailed telemetry (DEV ONLY)
      if (DevFlags.logMissDetails && balloons.isNotEmpty) {
        final b = balloons.first;
        final bx = centerX + (b.xOffset * lastSize.width * 0.5);
        final by = b.y;

        final dx = tapPos.dx - bx;
        final dy = tapPos.dy - by;
        final dist = sqrt(dx * dx + dy * dy);

        gameState.log(
          'MISS world=${spawner.currentWorld} '
          'tap=(${tapPos.dx.toStringAsFixed(1)},${tapPos.dy.toStringAsFixed(1)}) '
          'balloon=(${bx.toStringAsFixed(1)},${by.toStringAsFixed(1)}) '
          'dx=${dx.toStringAsFixed(1)} '
          'dy=${dy.toStringAsFixed(1)} '
          'dist=${dist.toStringAsFixed(1)} '
          'r=${(balloonRadius + hitForgiveness).toStringAsFixed(1)}',
        );
      }
    }

    controller.registerTap(hit: hit);
  }
}
