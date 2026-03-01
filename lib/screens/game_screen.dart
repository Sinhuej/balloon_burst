import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';

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
import 'package:balloon_burst/screens/leaderboard_screen.dart';

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
  bool _reviveProtectionActive = false;
  bool _reviveFlashActive = false;  
  Timer? _reviveProtectionTimer;
  
  bool _previousShieldState = false;
  bool _showShieldFlash = false;  

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
  
  void _triggerShieldBreakFeedback() {
   // Visual flash
   _showShieldFlash = true;

   _shieldFlashTimer?.cancel();
   _shieldFlashTimer = Timer(
    const Duration(milliseconds: 250),
    () {
      if (!mounted) return;
      setState(() {
        _showShieldFlash = false;
      });
    },
  );

  // Optional sound
  AudioPlayerService.playShieldBreak();
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

    final shieldNow = widget.engine.runLifecycle.isShieldActive;

    // Detect shield consumption
    if (_previousShieldState && !shieldNow) {
     _triggerShieldBreakFeedback();
   }

    _previousShieldState = shieldNow;

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

    final currentWorld = widget.spawner.currentWorld;
    if (currentWorld != _lastReportedWorld) {
      _lastReportedWorld = currentWorld;
      widget.engine.runLifecycle.report(
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
  if (!_reviveProtectionActive) {
    _controller.registerEscapes(escapedThisTick);
    widget.engine.runLifecycle.report(
      EscapeEvent(count: escapedThisTick),
    );
  }
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
     if (!_reviveProtectionActive) {
      widget.engine.runLifecycle.report(const MissEvent());
    }
     return;
    }

    widget.engine.runLifecycle.report(const PopEvent(points: 1));

    final nextStreak =
        widget.engine.runLifecycle.getSnapshot().streak;

    final prevMilestone =
        _milestoneForStreak(prevStreak);
    final nextMilestone =
        _milestoneForStreak(nextStreak);

    if (nextMilestone > prevMilestone) {
      AudioPlayerService.playStreakMilestone(
          nextMilestone);
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

    widget.engine.difficulty.reset();

    widget.engine.runLifecycle.startRun(
      runId: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    setState(() {});
  }

 static const int _reviveCost = 50;

 Future<void> _revive() async {
  final success =
      await widget.engine.wallet.spendCoins(_reviveCost);

  if (!success) return;

  _leaderboardSubmitted = false;
  _leaderboardPlacement = null;

  widget.engine.runLifecycle.revive();

  // 🔒 Protection window
  _reviveProtectionActive = true;

  _reviveProtectionTimer?.cancel();
  _reviveProtectionTimer = Timer(
    const Duration(milliseconds: 1250),
    () {
      if (!mounted) return;
      setState(() {
        _reviveProtectionActive = false;
      });
    },
  );

  // ✨ Flash + sound
  _reviveFlashActive = true;
  AudioPlayerService.playStreakMilestone(1); // temporary reuse or swap later

  Future.delayed(
    const Duration(milliseconds: 500),
    () {
      if (!mounted) return;
      setState(() {
        _reviveFlashActive = false;
      });
    },
  );

  setState(() {});
}

  @override
  void dispose() {
  _shieldFlashTimer?.cancel(); 
  _reviveProtectionTimer?.cancel();  
  _surge.dispose();
  _ticker.dispose();
  super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.engine.runLifecycle.latestSummary;

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

              if (_showShieldFlash)
               IgnorePointer(
                child: Container(
                 color: Colors.amber.withOpacity(0.25),
                ),
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
                streak: widget.engine.runLifecycle.getSnapshot().streak,
              ),

              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: Icon(
                    widget.engine.isMuted
                        ? Icons.volume_off
                        : Icons.volume_up,
                    color: Colors.white70,
                  ),
                  onPressed: () async {
                    final muted = await widget.engine.toggleMute();
                    AudioPlayerService.setMuted(muted);
                    if (!mounted) return;
                    setState(() {});
                  },
                ),
              ),

              Positioned(
                top: 40,
                left: 16,
                child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [

                  // Wallet
                  Text(
                   '💰 ${widget.engine.wallet.balance}',
                   style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                   ),
                  ),

                  const SizedBox(height: 6),

                  // Shield Indicator (only visible if active)
                  if (widget.engine.runLifecycle.isShieldActive)
                   const Text(
                    '🛡 SHIELD READY',
                    style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.cyanAccent,
                   ),
                  ),
               ],
              ),
             ),

               if (_reviveFlashActive)
                Positioned.fill(
                 child: IgnorePointer(
                  child: AnimatedOpacity(
                   opacity: _reviveFlashActive ? 0.35 : 0.0,
                   duration: const Duration(milliseconds: 250),
                  child: Container(
                 color: Colors.amber,
                ),
               ),
              ),
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
                onRevive: _revive,
                placement: _leaderboardPlacement,
                  onViewLeaderboard: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LeaderboardScreen(
                          engine: widget.engine,
                        ),
                      ),
                    );
                  },
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
