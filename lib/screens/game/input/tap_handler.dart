import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:balloon_burst/audio/audio_player.dart';
import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/game/game_controller.dart';
import 'package:balloon_burst/game/balloon_spawner.dart';
import 'package:balloon_burst/gameplay/balloon.dart';
import 'package:balloon_burst/screens/game/effects/world_surge_pulse.dart';

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

    double? closestDist;
    double? closestDx;
    double? closestDy;
    double? closestBx;
    double? closestBy;

    for (int i = 0; i < balloons.length; i++) {
      final b = balloons[i];
      if (b.isPopped) continue;

      // MUST MATCH BalloonPainter
      final bx = centerX + (b.xOffset * lastSize.width * 0.5);
      final by = b.y;

      final dx = tapPos.dx - bx;
      final dy = tapPos.dy - by;
      final dist = sqrt(dx * dx + dy * dy);
      final effectiveRadius = balloonRadius + hitForgiveness;

      if (closestDist == null || dist < closestDist!) {
        closestDist = dist;
        closestDx = dx;
        closestDy = dy;
        closestBx = bx;
        closestBy = by;
      }

      if (dist <= effectiveRadius) {
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
      if (closestDist != null) {
        gameState.log(
          'MISS world=${spawner.currentWorld} '
          'tap=(${tapPos.dx.toStringAsFixed(1)},${tapPos.dy.toStringAsFixed(1)}) '
          'balloon=(${closestBx!.toStringAsFixed(1)},${closestBy!.toStringAsFixed(1)}) '
          'dx=${closestDx!.toStringAsFixed(1)} '
          'dy=${closestDy!.toStringAsFixed(1)} '
          'dist=${closestDist!.toStringAsFixed(1)} '
          'r=${(balloonRadius + hitForgiveness).toStringAsFixed(1)}'
        );
      }

      spawner.registerMiss(gameState);
    }

    controller.registerTap(hit: hit);
  }
}
