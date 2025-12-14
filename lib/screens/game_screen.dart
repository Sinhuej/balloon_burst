import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../main.dart'; // TEMP: GameMode
import '../tj_engine/engine/momentum/momentum_storage.dart';
import '../tj_engine/engine/momentum/momentum_config.dart';
import '../tj_engine/engine/momentum/momentum_manager.dart';


import '../game/balloon.dart';
import '../game/balloon_painter.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final List<Mission> missions;
  final SkinDef skin;

  const GameScreen({
    super.key,
    required this.mode,
    required this.missions,
    required this.skin,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {

  late final MomentumManager _momentum;
  late final Ticker _ticker;

  final List<Balloon> _balloons = [];
  Duration _lastTick = Duration.zero;

  bool _frenzy = false;

  @override
  void initState() {
    super.initState();

    _momentum = MomentumManager(
      config: MomentumConfig(
        worldThresholds: [0, 100, 300, 700, 1500],
        localGainRate: 1.0,
        localDecayRate: 0.5,
        universalShare: 0.2,
      ),
      storage: InMemoryMomentumStorage(),
    );

    _momentum.init();

    _ticker = Ticker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }

    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;

    _momentum.decayLocal(dt);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomPaint(
        painter: BalloonPainter(
          balloons: _balloons,
          skin: widget.skin,
          frenzy: _frenzy,
        ),
        child: Container(),
      ),
    );
  }
}

