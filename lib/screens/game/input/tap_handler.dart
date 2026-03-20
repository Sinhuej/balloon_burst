import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/game/game_controller.dart';
import 'package:balloon_burst/game/balloon_spawner.dart';
import 'package:balloon_burst/gameplay/balloon.dart';
import 'package:balloon_burst/screens/game/effects/world_surge_pulse.dart';

class TapHandler {
  // 🔥 Pointer State
  static int? _activePointerId;
  static bool _isPointerDown = false;

  // 🔥 Debug Hold
  static Timer? _debugHoldTimer;
  static const Duration debugHoldDuration = Duration(seconds: 3);

  // ===============================
  // POINTER DOWN
  // ===============================
  static void handlePointerDown({
    required int pointerId,
    required Offset tapPos,
    required Size lastSize,
    required List<Balloon> balloons,
    required GameState gameState,
    required BalloonSpawner spawner,
    required GameController controller,
    required WorldSurgePulse surge,
    required double balloonRadius,
    required double hitForgiveness,
  }) {
    _activePointerId = pointerId;
    _isPointerDown = true;

    // 🔥 Start debug hold timer
    _debugHoldTimer?.cancel();
    _debugHoldTimer = Timer(debugHoldDuration, () {
      if (_isPointerDown && _activePointerId == pointerId) {
        controller.openDebugMenu(); // 👈 your debug trigger
      }
    });

    // 🔥 Process tap immediately (no delay)
    _processTap(
      tapPos: tapPos,
      lastSize: lastSize,
      balloons: balloons,
      gameState: gameState,
      spawner: spawner,
      controller: controller,
      surge: surge,
      balloonRadius: balloonRadius,
      hitForgiveness: hitForgiveness,
    );
  }

  // ===============================
  // POINTER UP
  // ===============================
  static void handlePointerUp(int pointerId) {
    if (_activePointerId == pointerId) {
      _clearTouchState();
    }
  }

  // ===============================
  // POINTER CANCEL
  // ===============================
  static void handlePointerCancel(int pointerId) {
    if (_activePointerId == pointerId) {
      _clearTouchState();
    }
  }

  // ===============================
  // CORE TAP LOGIC
  // ===============================
  static void _processTap({
    required Offset tapPos,
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

    final centerX = lastSize.width / 2;

    bool hit = false;
    bool perfectHit = false;

    int? bestHitIndex;
    double? closestDist;

    for (int i = 0; i < balloons.length; i++) {
      final b = balloons[i];

      if (!b.isAlive) continue;

      final dx = b.position.dx - tapPos.dx;
      final dy = b.position.dy - tapPos.dy;
      final dist = sqrt(dx * dx + dy * dy);

      final radius = balloonRadius + hitForgiveness;

      if (dist <= radius) {
        hit = true;

        if (closestDist == null || dist < closestDist) {
          closestDist = dist;
          bestHitIndex = i;
        }
      }
    }

    if (hit && bestHitIndex != null) {
      final b = balloons[bestHitIndex];

      // 🎯 Perfect hit check
      if (closestDist! < balloonRadius * 0.4) {
        perfectHit = true;
      }

      // 🔥 Pop balloon
      balloons[bestHitIndex] = b.pop();

      controller.onBalloonPopped(
        perfect: perfectHit,
        position: b.position,
      );

      surge.trigger();

    } else {
      // ❌ Miss
      controller.onMiss(tapPos);
    }

    // 🔥 IMPORTANT: Clear touch AFTER tap
    _clearTouchState();
  }

  // ===============================
  // CLEANUP
  // ===============================
  static void _clearTouchState() {
    _debugHoldTimer?.cancel();
    _debugHoldTimer = null;

    _activePointerId = null;
    _isPointerDown = false;
  }
}

