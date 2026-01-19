import 'dart:async';
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
    with TickerProviderStateMixin {
  late final Ticker _ticker;
  late final GameController _controller;

  final List<Balloon> _balloons = [];

  Duration _lastTime = Duration.zero;
  Size _lastSize = Size.zero;

  static const double baseRiseSpeed = 120.0;
  static const double balloonRadius = 16.0;
  static const double hitForgiveness = 14.0;

  late final AnimationController _pulseCtrl;
  late final AnimationController _shakeCtrl;

  int _lastSurgeWorld = 0;

  static const double _pulseMaxOpacity = 0.08;
  static const double _shakeAmpPx = 2.5;

  @override
  void initState() {
    super.initState();

    _controller = GameController(
      momentum: MomentumController(),
      tier: TierController(),
      speed: SpeedCurve(),
      gameState: widget.gameState,
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
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

  void _maybeTriggerWorldSurge() {
    final pops = widget.spawner.totalPops;
    final world = widget.spawner.currentWorld;

    if (_lastSurgeWorld == world) return;

    final triggerAt = switch (world) {
      1 => BalloonSpawner.world2Pops - 5,
      2 => BalloonSpawner.world3Pops - 5,
      3 => BalloonSpawner.world4Pops - 5,
      _ => null,
    };

    if (triggerAt != null && pops == triggerAt) {
      _lastSurgeWorld = world;
      _pulseCtrl.forward(from: 0.0);
      _shakeCtrl.forward(from: 0.0);
    }
  }

  double _shakeYOffset() =>
      sin(pi * _shakeCtrl.value) * _shakeAmpPx;

  void _handleTap(TapDownDetails details) {
    if (_lastSize == Size.zero) return;

    final tapPos = details.localPosition;
    final centerX = _lastSize.width / 2;

    bool hit = false;

    for (int i = 0; i < _balloons.length; i++) {
      final b = _balloons[i];
      if (b.isPopped) continue;

      final bx = centerX + (b.xOffset * _lastSize.width * 0.5);
      final by = b.y;

      final dx = tapPos.dx - bx;
      final dy = tapPos.dy - by;
      final dist = sqrt(dx * dx + dy * dy);

      if (dist <= balloonRadius + hitForgiveness) {
        _balloons[i] = b.pop();
        AudioPlayerService.playPop();
        widget.spawner.registerPop(widget.gameState);

        _maybeTriggerWorldSurge();

        hit = true;
        break;
      }
    }

    if (!hit) {
      widget.spawner.registerMiss(widget.gameState);
    }

    _controller.registerTap(hit: hit);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
    _ticker.dispose();
    super.dispose();
  }

  Color _backgroundForWorld(int world) {
    switch (world) {
      case 2:
        return const Color(0xFF2E86DE);
      case 3:
        return const Color(0xFF6C2EB9);
      case 4:
        return const Color(0xFF0B0F2F);
      default:
        return const Color(0xFF0A0A0F);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          _lastSize = constraints.biggest;

          final currentWorld = widget.spawner.currentWorld;
          final nextWorld = currentWorld + 1;

          return SizedBox.expand(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: _handleTap,
              onLongPress: widget.onRequestDebug,
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulseCtrl, _shakeCtrl]),
                builder: (context, _) {
                  return Stack(
                    children: [
                      // Base background
                      Positioned.fill(
                        child: Container(
                          color: _backgroundForWorld(currentWorld),
                        ),
                      ),

                      // Pulse layer (behind balloons, SAFE animation)
                      Positioned.fill(
                        child: AnimatedOpacity(
                          opacity: _pulseCtrl.isAnimating ? _pulseMaxOpacity : 0.0,
                          duration: const Duration(milliseconds: 180),
                          child: Container(
                            color: _backgroundForWorld(nextWorld),
                          ),
                        ),
                      ),

                      // Gameplay
                      Positioned.fill(
                        child: Transform.translate(
                          offset: Offset(0, _shakeYOffset()),
                          child: CustomPaint(
                            painter: BalloonPainter(_balloons, widget.gameState),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
