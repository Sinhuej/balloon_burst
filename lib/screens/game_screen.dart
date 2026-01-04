import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/game/game_controller.dart';
import 'package:balloon_burst/game/balloon_painter.dart';
import 'package:balloon_burst/game/balloon_spawner.dart';
import 'package:balloon_burst/gameplay/balloon.dart';
import 'package:balloon_burst/world/world_state.dart';

import 'package:balloon_burst/engine/momentum/momentum_controller.dart';
import 'package:balloon_burst/engine/tier/tier_controller.dart';
import 'package:balloon_burst/engine/speed/speed_curve.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  final GameState _gameState = GameState();
  final List<Balloon> _balloons = [];
  final BalloonSpawner _spawner = BalloonSpawner();
  final WorldState _worldState = WorldState();

  late final GameController _controller;

  bool _pendingWorldReset = false;

  Duration _lastTime = Duration.zero;

  static const double baseFallSpeed = 120.0;
  static const double balloonRadius = 16.0;

  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();

    _controller = GameController(
      momentum: MomentumController(),
      tier: TierController(),
      speed: SpeedCurve(),
      gameState: _gameState,
    );

    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    // 🔁 TJ-30: safe world reset between frames
    if (_pendingWorldReset) {
      _pendingWorldReset = false;
      _balloons.clear();
      _controller.momentum.reset();
    }

    final dt = (_lastTime == Duration.zero)
        ? 0.016
        : (elapsed - _lastTime).inMicroseconds / 1e6;

    _lastTime = elapsed;

    _spawner.update(
      dt: dt,
      tier: 0,
      balloons: _balloons,
    );

    for (int i = 0; i < _balloons.length; i++) {
      final b = _balloons[i];
      _balloons[i] = b.movedBy(baseFallSpeed * dt);
    }

    _controller.update(_balloons, dt);

    setState(() {});
  }

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

      if (sqrt(dx * dx + dy * dy) <= balloonRadius) {
        _balloons[i] = b.pop();
        hit = true;

        _worldState.registerPop();

        if (_worldState.isWorldComplete) {
          _worldState.advanceWorld();
          _pendingWorldReset = true;
        }

        break;
      }
    }

    // 🔊 ⚡ This must see a consistent world
    _controller.registerTap(hit: hit);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
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
            child: CustomPaint(
              painter: BalloonPainter(_balloons, _gameState),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }
}
