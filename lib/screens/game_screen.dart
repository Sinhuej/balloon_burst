import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/game/game_controller.dart';
import 'package:balloon_burst/game/balloon_spawner.dart';
import 'package:balloon_burst/gameplay/balloon.dart';

import 'package:balloon_burst/engine/momentum/momentum_controller.dart';
import 'package:balloon_burst/engine/tier/tier_controller.dart';
import 'package:balloon_burst/engine/speed/speed_curve.dart';

import 'screens/game/effects/world_surge_pulse.dart';
import 'screens/game/input/tap_handler.dart';
import 'screens/game/render/game_canvas.dart';

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

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late final Ticker _ticker;
  late final GameController _controller;
  late final WorldSurgePulse _surge;

  final List<Balloon> _balloons = [];

  Duration _lastTime = Duration.zero;
  Size _lastSize = Size.zero;

  // Gameplay constants
  static const double baseRiseSpeed = 120.0;
  static const double balloonRadius = 16.0;
  static const double hitForgiveness = 14.0;

  // Debug HUD
  bool _showHud = false;
  double _fps = 0.0;

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

    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = (_lastTime == Duration.zero)
        ? 0.016
        : (elapsed - _lastTime).inMicroseconds / 1e6;

    _lastTime = elapsed;

    // FPS (smoothed)
    final instFps = dt > 0 ? (1.0 / dt) : 0.0;
    _fps = (_fps == 0.0) ? instFps : (_fps * 0.9 + instFps * 0.1);

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
    TapHandler.handleTap(
      details: details,
      lastSize: _lastSize,
      balloons: _balloons,
      gameState: widget.gameState,
      spawner: widget.spawner,
      controller: _controller,
      surge: _surge,
      balloonRadius: balloonRadius,
      hitForgiveness: hitForgiveness,
    );
  }

  void _handleLongPress() {
    // Toggle HUD locally (dev-only), AND still allow external debug hook.
    setState(() => _showHud = !_showHud);
    widget.onRequestDebug();
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

  double _recentAccuracy() {
    final hits = widget.spawner.recentHits;
    final misses = widget.spawner.recentMisses;
    final total = hits + misses;
    if (total <= 0) return 1.0;
    return hits / total;
  }

  @override
  void dispose() {
    _surge.dispose();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          _lastSize = constraints.biggest;

          final currentWorld = widget.spawner.currentWorld;
          final nextWorld = currentWorld + 1;

          return GameCanvas(
            currentWorld: currentWorld,
            nextWorld: nextWorld,
            backgroundColor: _backgroundForWorld(currentWorld),
            pulseColor: _backgroundForWorld(nextWorld),
            surge: _surge,
            balloons: _balloons,
            gameState: widget.gameState,
            onTapDown: _handleTap,
            onLongPress: _handleLongPress,
            showHud: _showHud,
            fps: _fps,
            speedMultiplier: widget.spawner.speedMultiplier,
            recentAccuracy: _recentAccuracy(),
            recentMisses: widget.spawner.recentMisses,
          );
        },
      ),
    );
  }
}
