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

  static TapDownDetails? _bufferedTap;
  static DateTime? _bufferTime;

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

    // Buffer tap
    _bufferedTap = details;
    _bufferTime = DateTime.now();

    // Process buffered tap
    if (_bufferedTap != null) {
      details = _bufferedTap!;
      _bufferedTap = null;
    }

    // Expire old buffered taps
    if (_bufferTime != null &&
        DateTime.now().difference(_bufferTime!) >
            const Duration(milliseconds: 120)) {
      _bufferedTap = null;
    }

    final tapPos = details.localPosition;
    final centerX = lastSize.width / 2;

    bool hit = false;
    bool perfectHit = false;

    double? closestDist;
    double? closestDx;
    double? closestDy;
    double? closestBx;
    double? closestBy;

    double? bestScore;

    for (int i = 0; i < balloons.length; i++) {

      final b = balloons[i];
      if (b.isPopped) continue;

      final bx = centerX + (b.xOffset * lastSize.width * 0.5);
      final by = b.y;

      final dx = tapPos.dx - bx;
      final dy = tapPos.dy - by;

      final dist = sqrt(dx * dx + dy * dy);

      final centerBias = dx.abs();
      final tapScore = dist + centerBias * 0.35;

      final effectiveRadius = balloonRadius + hitForgiveness;

      if (bestScore == null || tapScore < bestScore) {
        bestScore = tapScore;
        closestDist = dist;
        closestDx = dx;
        closestDy = dy;
        closestBx = bx;
        closestBy = by;
      }

      if (dist <= effectiveRadius) {

        balloons[i] = b.pop();

        if (dist <= balloonRadius * 0.45) {
          perfectHit = true;
          gameState.log(
            'PERFECT HIT dist=${dist.toStringAsFixed(1)}'
          );
        }

        AudioPlayerService.playPop();

        if (perfectHit) {
          AudioPlayerService.playCoin();
        }

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

      final nearMissRadius = balloonRadius + hitForgiveness + 10;

      if (closestDist != null &&
          closestDist! > balloonRadius &&
          closestDist! <= nearMissRadius) {

        gameState.log(
          'NEAR MISS dist=${closestDist!.toStringAsFixed(1)}'
        );
      }

      spawner.registerMiss(gameState);
    }

    controller.registerTap(hit: hit, perfect: perfectHit);
  }
}
