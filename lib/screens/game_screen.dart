import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/game/game_controller.dart';
import 'package:balloon_burst/game/balloon_spawner.dart';
import 'package:balloon_burst/gameplay/balloon.dart';

import 'package:balloon_burst/engine/momentum/momentum_controller.dart';
import 'package:balloon_burst/engine/tier/tier_controller.dart';
import 'package:balloon_burst/engine/speed/speed_curve.dart';

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

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late final Ticker _ticker;
  late final GameController _controller;
  late final WorldSurgePulse _surge;

  final List<Balloon> _balloons = [];

  Duration _lastTime = Duration.zero;
  Size _lastSize = Size.zero;

  // Gameplay tuning (owned by GameScreen; passed into TapHandler)
  static const double baseRiseSpeed = 120.0;
  static const double balloonRadius = 16.0;
  static const double hitForgiveness = 14.0;

  // Debug HUD (dev-only)
  bool _showHud = false;

  // Simple performance metric (smoothed)
  double _fps = 0.0;

  // DEV ONLY HUD — locked on in debug, impossible in release
  void _initDebugHud() {
    assert(() {
      _showHud = true;
      return true;
    }());
  }

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
    _initDebugHud();

    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final double dt = (_lastTime == Duration.zero)
        ? 0.016
        : (elapsed - _lastTime).inMicroseconds / 1e6;

    _lastTime = elapsed;

    // FPS: exponential moving average so it doesn't jitter
    final double instFps = (dt > 0) ? (1.0 / dt) : 0.0;
    _fps = (_fps == 0.0) ? instFps : (_fps * 0.9 + instFps * 0.1);

    widget.spawner.update(
      dt: dt,
      tier: 0,
      balloons: _balloons,
      viewportHeight: _lastSize.height,
    );

    final double speed = baseRiseSpeed * widget.spawner.speedMultiplier;

    for (int i = 0; i < _balloons.length; i++) {
      _balloons[i] = _balloons[i].movedBy(-speed * dt);
    }

    _controller.update(_balloons, dt);

    // Pump UI for painter + HUD + effects
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
    // NOTE: these are re-evaluated every build, which is fine (cheap).
    final int currentWorld = widget.spawner.currentWorld;
    final int nextWorld = currentWorld + 1;

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
            fps: _fps,
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
