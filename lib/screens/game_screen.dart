import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/debug/debug_log.dart';
import 'package:balloon_burst/game/game_controller.dart';
import 'package:balloon_burst/game/balloon_spawner.dart';
import 'package:balloon_burst/gameplay/balloon.dart';
import 'package:balloon_burst/audio/audio_player.dart';

import 'package:balloon_burst/engine/momentum/momentum_controller.dart';
import 'package:balloon_burst/engine/tier/tier_controller.dart';
import 'package:balloon_burst/engine/speed/speed_curve.dart';

import 'package:balloon_burst/tj_engine/engine/tj_engine.dart';
import 'package:balloon_burst/tj_engine/engine/run/models/run_state.dart';
import 'package:balloon_burst/tj_engine/engine/run/models/run_event.dart';

import 'package:balloon_burst/screens/game/render/game_canvas.dart';
import 'package:balloon_burst/screens/game/effects/world_surge_pulse.dart';
import 'package:balloon_burst/screens/game/input/tap_handler.dart';
import 'package:balloon_burst/screens/game/intro/carnival_intro_overlay.dart';

import 'package:balloon_burst/game/end/run_end_overlay.dart';
import 'package:balloon_burst/game/end/run_end_state.dart';

class GameScreen extends StatefulWidget {
  final GameState gameState;
  final BalloonSpawner spawner;
  final TJEngine engine;
  final VoidCallback onRequestDebug;

  const GameScreen({
    super.key,
    required this.gameState,
    required this.spawner,
    required this.engine,
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

  bool _showHud = false;
  bool _showIntro = true;
  bool _canCountMisses = false;

  double _fps = 0.0;

  bool _leaderboardSubmitted = false;
  int? _leaderboardPlacement;
  int _lastReportedWorld = 1;

  static const double baseRiseSpeed = 120.0;
  static const double balloonRadius = 16.0;
  static const double hitForgiveness = 18.0;

  bool get _isRunEnded =>
      widget.engine.runLifecycle.state == RunState.ended;

  @override
  void initState() {
    super.initState();

    widget.gameState.log(
      'SYSTEM: GAME WIRED',
      type: DebugEventType.system,
    );

    // ✅ Ensure difficulty always starts fresh
    widget.engine.difficulty.reset();

    widget.engine.runLifecycle.startRun(
      runId: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    _lastReportedWorld = widget.spawner.currentWorld;

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

    if (_isRunEnded) {
      _lastTime = elapsed;
      _maybeSubmitLeaderboard();
      if (mounted) setState(() {});
      return;
    }

    final dt = (_lastTime == Duration.zero)
        ? 0.016
        : (elapsed - _lastTime).inMicroseconds / 1e6;

    _lastTime = elapsed;

    final instFps = dt > 0 ? (1.0 / dt) : 0.0;
    _fps = (_fps == 0.0) ? instFps : (_fps * 0.9 + instFps * 0.1);

    widget.engine.update(dt);

    widget.spawner.update(
      dt: dt,
      tier: 0,
      balloons: _balloons,
      viewportHeight: _lastSize.height,
      engineSpawnInterval:
          widget.engine.difficulty.snapshot.spawnInterval,
      engineMaxSimultaneousSpawns:
          widget.engine.difficulty.snapshot.maxSimultaneousSpawns,
    );

    // 🔥 REPORT WORLD TRANSITION TO ENGINE
     final currentWorld = widget.spawner.currentWorld;
     if (currentWorld != _lastReportedWorld) {
     _lastReportedWorld = currentWorld;
     gwidget.engine.runLifecycle.report(
      WorldTransitionEvent(newWorldLevel: currentWorld),
    );
   }

    if (!_canCountMisses && _balloons.isNotEmpty) {
      _canCountMisses = true;
    }

    for (int i = 0; i < _balloons.length; i++) {
      final b = _balloons[i];

      final engineSpeed =
          widget.engine.difficulty.snapshot.speedMultiplier;

      final speed = baseRiseSpeed *
          widget.spawner.speedMultiplier *
          engineSpeed *
          b.riseSpeedMultiplier;

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
      widget.engine.runLifecycle.report(
        EscapeEvent(count: escapedThisTick),
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

  void _maybeSubmitLeaderboard() {
    if (_leaderboardSubmitted) return;

    _leaderboardSubmitted = true;

    widget.engine.submitLatestRunToLeaderboard().then((placement) {
      if (!mounted) return;

      setState(() {
        _leaderboardPlacement = placement;
      });

      final entries = widget.engine.leaderboard.entries;

      widget.gameState.log('TJ LEADERBOARD SIZE: ${entries.length}');

      for (int i = 0; i < entries.length; i++) {
        final e = entries[i];
        widget.gameState.log(
          ' #${i + 1} score=${e.score} world=${e.worldReached} streak=${e.bestStreak}',
        );
      }
    });
  }

  int _milestoneForStreak(int streak) {
    if (streak >= 30) return 3;
    if (streak >= 20) return 2;
    if (streak >= 10) return 1;
    return 0;
  }

  void _handleTap(TapDownDetails details) {
    if (_showIntro) return;
    if (_isRunEnded || !_canCountMisses) return;

    final prevStreak =
        widget.engine.runLifecycle.getSnapshot().streak;

    final missesBefore = _controller.missCount;

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

    final missesAfter = _controller.missCount;

    if (missesAfter > missesBefore) {
      widget.engine.runLifecycle.report(const MissEvent());
      return;
    }

    widget.engine.runLifecycle.report(const PopEvent(points: 1));

    final nextStreak =
        widget.engine.runLifecycle.getSnapshot().streak;

    final prevMilestone = _milestoneForStreak(prevStreak);
    final nextMilestone = _milestoneForStreak(nextStreak);

    if (nextMilestone > prevMilestone) {
      AudioPlayerService.playStreakMilestone(nextMilestone);
    }
  }

  void _handleLongPress() {
    if (_showIntro) return;
    setState(() => _showHud = !_showHud);
    widget.onRequestDebug();
  }

  void _replay() {
    _balloons.clear();
    _canCountMisses = false;

    _leaderboardSubmitted = false;
    _leaderboardPlacement = null;

    _controller.reset();
    widget.spawner.resetForNewRun();
    _surge.reset();

    widget.gameState.clearLogs();
    _lastTime = Duration.zero;

    // ✅ Reset difficulty for new run
    widget.engine.difficulty.reset();

    widget.engine.runLifecycle.startRun(
      runId: DateTime.now().millisecondsSinceEpoch.toString(),
    );

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
    final summary = widget.engine.runLifecycle.latestSummary;
    final snapshot = widget.engine.runLifecycle.getSnapshot();

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
              IgnorePointer(child: Container(color: bgColor)),
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
                streak: snapshot.streak,
              ),
              if (_showIntro)
                CarnivalIntroOverlay(
                  onComplete: () {
                    if (!mounted) return;
                    setState(() => _showIntro = false);
                  },
                ),
              if (_isRunEnded && summary != null)
               RunEndOverlay(
                state: RunEndState.fromSummary(summary),
                onReplay: _replay,
                placement: _leaderboardPlacement,
                engine: widget.engine,
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
        return const Color(0xFF6EC6FF);
      case 2:
        return const Color(0xFF2E86DE);
      case 3:
        return const Color(0xFF6C2EB9);
      case 4:
        return const Color(0xFF0B0F2F);
      default:
        return const Color(0xFF6EC6FF);
    }
  }
}
