import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/game/game_controller.dart';
import 'package:balloon_burst/game/balloon_spawner.dart';
import 'package:balloon_burst/gameplay/balloon.dart';

import 'game/render/game_canvas.dart';
import 'game/effects/world_surge_pulse.dart';
import 'game/input/tap_handler.dart';

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
  late final WorldSurgePulse _surge;

  final List<Balloon> _balloons = [];

  Duration _lastTime = Duration.zero;
  Size _lastSize = Size.zero;

  static const double baseRiseSpeed = 120.0;
  static const double balloonRadius = 16.0;
  static const double hitForgiveness = 14.0;

  bool _showHud = false;

  @override
  void initState() {
    super.initState();

    _controller = GameController(
      momentum: MomentumController(),
      tier: TierController(),
      speed: SpeedCurve(),
      gameState: widget.gameState,
    );

    _surge = WorldSurgePulse(vsync: this);

    assert(() {
      _showHud = true;
      return true;
    }());

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

    _controller.update(_balloons, dt);
    setState(() {});
  }

  @override
  void dispose() {
    _surge.dispose();
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
    final currentWorld = widget.spawner.currentWorld;
    final nextWorld = currentWorld + 1;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          _lastSize = constraints.biggest;

          return GameCanvas(
            currentWorld: currentWorld,
            nextWorld: nextWorld,
            backgroundColor: _backgroundForWorld(currentWorld),
            pulseColor: _backgroundForWorld(nextWorld),
            surge: _surge,
            balloons: _balloons,
            gameState: widget.gameState,
            showHud: _showHud,
            fps: _ticker.isActive
                ? 1 / (_lastTime.inMicroseconds / 1e6)
                : 0,
            speedMultiplier: widget.spawner.speedMultiplier,
            recentAccuracy: widget.spawner.accuracyModifier,
            recentMisses: widget.spawner.recentMisses,
            onTapDown: (details) => TapHandler.handleTap(
              details: details,
              lastSize: _lastSize,
              balloons: _balloons,
              gameState: widget.gameState,
              spawner: widget.spawner,
              controller: _controller,
              surge: _surge,
              balloonRadius: balloonRadius,
              hitForgiveness: hitForgiveness,
            ),
            onLongPress: widget.onRequestDebug,
          );
        },
      ),
    );
  }
}
