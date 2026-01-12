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

  final List<Balloon> _balloons = [];
  late final GameController _controller;

  Duration _lastTime = Duration.zero;

  static const double baseRiseSpeed = 120.0;
  static const double balloonRadius = 16.0;

  // 🎯 Spatial forgiveness
  static const double hitForgiveness = 6.0;

  // 🎯 Temporal compensation (~40ms)
  static const double hitTimeCompensation = 0.04;

  Size _lastSize = Size.zero;

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

    widget.spawner.update(
      dt: dt,
      tier: 0,
      balloons: _balloons,
      viewportHeight: _lastSize.height,
    );

    final speed = baseRiseSpeed * widget.spawner.speedMultiplier;

    for (int i = 0; i < _balloons.length; i++) {
      final b = _balloons[i];
      _balloons[i] = b.movedBy(-speed * dt);
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

    final rawCompensation =
        baseRiseSpeed *
        widget.spawner.speedMultiplier *
        hitTimeCompensation;

    final compensation = rawCompensation.clamp(0.0, 6.0);

    bool hit = false;

    for (int i = 0; i < _balloons.length; i++) {
      final b = _balloons[i];
      if (b.isPopped) continue;

      final bx = centerX + (b.xOffset * _lastSize.width * 0.5);
      final by = b.y + compensation;

      final dx = tapPos.dx - bx;
      final dy = tapPos.dy - by;

      if (sqrt(dx * dx + dy * dy) <=
          balloonRadius + hitForgiveness) {
        _balloons[i] = b.pop();
        hit = true;

        AudioPlayerService.playPop();

        // ✅ FIX: pass currentWorld
        widget.spawner.registerPop(widget.spawner.currentWorld);

        break;
      }
    }

    if (!hit) {
      // ✅ FIX: pass currentWorld
      widget.spawner.registerMiss(widget.spawner.currentWorld);
    }

    _controller.registerTap(hit: hit);
  }

  Color _backgroundForWorld(int world) {
    switch (world) {
      case 2:
        return Colors.lightBlue.shade300;
      case 3:
        return Colors.purple.shade700;
      case 4:
        return Colors.black;
      default:
        return Colors.black;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final world = widget.spawner.currentWorld;
    final progress = widget.spawner.worldProgress;

    final bool anticipating = progress >= 0.85;

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
                // 🌍 World background
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  color: _backgroundForWorld(world),
                ),

                // 🔔 Anticipation overlay
                if (anticipating)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.white.withOpacity(0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
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
