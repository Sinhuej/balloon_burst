import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:balloon_burst/audio/audio_player.dart';
import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/game/game_controller.dart';
import 'package:balloon_burst/game/balloon_painter.dart';
import 'package:balloon_burst/game/balloon_spawner.dart';
import 'package:balloon_burst/gameplay/balloon.dart';

import 'package:balloon_burst/engine/momentum/momentum_controller.dart';
import 'package:balloon_burst/engine/tier/tier_controller.dart';
import 'package:balloon_burst/engine/speed/speed_curve.dart';

class GameScreen extends StatefulWidget {
  final GameState gameState;
  final BalloonSpawner spawner;
  final VoidCallback onRequestDebug;

  const GameScreen({
    super.key,
    required this.gameState,
    required this.spawner,
    required this.onRequestDebug,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final GameController _controller;

  final List<Balloon> _balloons = [];

  Duration _lastTime = Duration.zero;
  Size _lastSize = Size.zero;

  double _lastDt = 0.016; // last frame delta (for hit compensation)

  static const double baseRiseSpeed = 120.0;
  static const double balloonRadius = 16.0;

  // Spatial forgiveness
  static const double hitForgiveness = 14.0;

  @override
  void initState() {
    super.initState();

    _controller = GameController(
      momentum: MomentumController(),
      tier: TierController(),
      speed: SpeedCurve(),
      gameState: widget.gameState,
    );

    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = (_lastTime == Duration.zero)
        ? 0.016
        : (elapsed - _lastTime).inMicroseconds / 1e6;

    _lastTime = elapsed;
    _lastDt = dt;

    widget.spawner.update(
      dt: dt,
      tier: 0,
      balloons: _balloons,
      viewportHeight: _lastSize.height,
    );

    final speed = baseRiseSpeed * widget.spawner.speedMultiplier;

    for (int i = 0; i < _balloons.length; i++) {
      _balloons[i] = _balloons[i].movedBy(-speed * dt);
    }

    for (int i = _balloons.length - 1; i >= 0; i--) {
      if (_balloons[i].y < -balloonRadius) {
        _balloons.removeAt(i);
      }
    }

    _controller.update(_balloons, dt);
    setState(() {});
  }

  void _handleTap(TapDownDetails details) {
    if (_lastSize == Size.zero) return;

    final tapPos = details.localPosition;
    final centerX = _lastSize.width / 2;

    // One-frame vertical lead compensation
    final frameLead =
        baseRiseSpeed * widget.spawner.speedMultiplier * _lastDt;

    bool hit = false;

    double? closestDist;
    double? closestDx;
    double? closestDy;
    double? closestBx;
    double? closestBy;

    for (int i = 0; i < _balloons.length; i++) {
      final b = _balloons[i];
      if (b.isPopped) continue;

      final bx = centerX + (b.xOffset * _lastSize.width * 0.5);
      final by = b.y + balloonRadius + 18.0 - frameLead;

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
        _balloons[i] = b.pop();
        AudioPlayerService.playPop();
        widget.spawner.registerPop(widget.gameState);
        hit = true;
        break;
      }
    }

    if (!hit) {
      if (closestDist != null) {
        widget.gameState.log(
          'MISS world=${widget.spawner.currentWorld} '
          'tap=(${tapPos.dx.toStringAsFixed(1)},${tapPos.dy.toStringAsFixed(1)}) '
          'balloon=(${closestBx!.toStringAsFixed(1)},${closestBy!.toStringAsFixed(1)}) '
          'dx=${closestDx!.toStringAsFixed(1)} '
          'dy=${closestDy!.toStringAsFixed(1)} '
          'dist=${closestDist!.toStringAsFixed(1)} '
          'r=${(balloonRadius + hitForgiveness).toStringAsFixed(1)}'
        );
      }

      widget.spawner.registerMiss(widget.gameState);
    }

    _controller.registerTap(hit: hit);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Color _backgroundForWorld(int world) {
    switch (world) {
      case 2:
        return const Color(0xFF2E86DE); // Sky Blue
      case 3:
        return const Color(0xFF6C2EB9); // Neon Purple
      case 4:
        return const Color(0xFF0B0F2F); // Deep Space
      default:
        return const Color(0xFF0A0A0F); // Dark Carnival
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          _lastSize = constraints.biggest;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _handleTap,
            onLongPress: widget.onRequestDebug,
            child: Stack(
              children: [
                Container(
                  color: _backgroundForWorld(widget.spawner.currentWorld),
                ),
                CustomPaint(
                  painter: BalloonPainter(_balloons, widget.gameState),
                  size: Size.infinite,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
