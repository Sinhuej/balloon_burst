import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/debug/debug_log.dart';
import 'package:balloon_burst/game/game_controller.dart';
import 'package:balloon_burst/game/balloon_spawner.dart';
import 'package:balloon_burst/gameplay/balloon.dart';

import 'package:balloon_burst/engine/momentum/momentum_controller.dart';
import 'package:balloon_burst/engine/tier/tier_controller.dart';
import 'package:balloon_burst/engine/speed/speed_curve.dart';

import 'package:balloon_burst/screens/game/render/game_canvas.dart';
import 'package:balloon_burst/screens/game/effects/world_surge_pulse.dart';
import 'package:balloon_burst/screens/game/input/tap_handler.dart';
import 'package:balloon_burst/screens/game/intro/carnival_intro_overlay.dart';

import 'package:balloon_burst/game/end/run_end_overlay.dart';
import 'package:balloon_burst/game/end/run_end_state.dart';

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

  bool _showHud = false;
  bool _showIntro = true; // Intro auto-plays on fresh launch
  double _fps = 0.0;
  bool _canCountMisses = false;

  static const double baseRiseSpeed = 120.0;
  static const double balloonRadius = 16.0;
  static const double hitForgiveness = 18.0;

  @override
  void initState() {
    super.initState();

    widget.gameState.log(
      'SYSTEM: GAME WIRED',
      type: DebugEventType.system,
    );

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
    if (_controller.isEnded) {
      _lastTime = elapsed;
      if (mounted) setState(() {});
      return;
    }

    final dt = (_lastTime == Duration.zero)
        ? 0.016
        : (elapsed - _lastTime).inMicroseconds / 1e6;
    _lastTime = elapsed;

    final instFps = dt > 0 ? (1.0 / dt) : 0.0;
    _fps = (_fps == 0.0) ? instFps : (_fps * 0.9 + instFps * 0.1);

    widget.spawner.update(
      dt: dt,
      tier: 0,
      balloons: _balloons,
      viewportHeight: _lastSize.height,
    );

    if (!_canCountMisses && _balloons.isNotEmpty) {
      _canCountMisses = true;
    }

    for (int i = 0; i < _balloons.length; i++) {
      final b = _balloons[i];
      final speed =
          baseRiseSpeed * widget.spawner.speedMultiplier * b.riseSpeedMultiplier;

      final moved = b.movedBy(-speed * dt);
      final driftX = moved.driftedX(
        amplitude: 0.035,
        frequency: 0.015,
      );

      _balloons[i] = moved.withXOffset(driftX);
    }

    int escapedThisTick = 0;
    for (int i = _balloons.length - 1; i >= 0; i--) {
      final b = _balloons[i];
      if (b.y < -balloonRadius) {
        if (!b.isPopped) escapedThisTick++;
        _balloons.removeAt(i);
      }
    }

    if (escapedThisTick > 0) {
      _controller.registerEscapes(escapedThisTick);
      widget.gameState.log(
        'MISS: escaped=$escapedThisTick',
        type: DebugEventType.miss,
      );
    }

    _controller.update(_balloons, dt);

    _surge.maybeTrigger(
      totalPops: widget.spawner.totalPops,
      currentWorld: widget.spawner.currentWorld,
      world2Pops: BalloonSpawner.world2Pops,
      world3Pops: BalloonSpawner.world3Pops,
      world4Pops: BalloonSpawner.world4Pops,
    );

    setState(() {});
  }

  void _handleTap(TapDownDetails details) {
    if (_showIntro) return; // Protect taps during intro
    if (_controller.isEnded || !_canCountMisses) return;

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
    if (_showIntro) return; // no HUD during intro
    setState(() => _showHud = !_showHud);
    widget.onRequestDebug();
  }

  void _replay() {
    _balloons.clear();
    _canCountMisses = false;

    _controller.reset();
    widget.spawner.resetForNewRun();
    _surge.reset();

    widget.gameState.clearLogs();
    _lastTime = Duration.zero;
    setState(() {});
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

          final bgColor = _surge.showNextWorldColor
              ? _backgroundForWorld(nextWorld)
              : _backgroundForWorld(currentWorld);

          return Stack(
            children: [
              IgnorePointer(
                child: Container(color: bgColor),
              ),

              GameCanvas(
                currentWorld: currentWorld,
                nextWorld: nextWorld,
                backgroundColor: Colors.transparent,
                pulseColor: _backgroundForWorld(nextWorld),
                surge: _surge,
                balloons: _balloons,
                gameState: widget.gameState,
                onTapDown: _handleTap,
                onLongPress: _handleLongPress,
                showHud: _showHud,
                fps: _fps,
                speedMultiplier: widget.spawner.speedMultiplier,
                recentAccuracy: _controller.accuracy01,
                recentMisses: widget.spawner.recentMisses,
              ),

              if (_showIntro)
                CarnivalIntroOverlay(
                  onComplete: () {
                    if (!mounted) return;
                    setState(() => _showIntro = false);
                  },
                ),

              if (_controller.isEnded)
                RunEndOverlay(
                  state: RunEndState.fromController(_controller),
                  onReplay: _replay,
                ),
            ],
          );
        },
      ),
    );
  }

  Color _backgroundForWorld(int world) {
    switch (world) {
      case 1:
        return const Color(0xFF6EC6FF); // Sky
      case 2:
        return const Color(0xFF2E86DE); // Navy
      case 3:
        return const Color(0xFF6C2EB9); // Purple
      case 4:
        return const Color(0xFF0B0F2F); // Deep space
      default:
        return const Color(0xFF6EC6FF);
    }
  }
}
