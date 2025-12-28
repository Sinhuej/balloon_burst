import 'dart:async';
import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../game/balloon_painter.dart';
import '../gameplay/gameplay_world.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = GameController();
    _controller.start();

    // Drive engine at ~60 FPS
    _timer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _controller.update(1 / 60),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<GameplayWorld?>(
        valueListenable: _controller.world,
        builder: (context, world, _) {
          if (world == null) {
            return const SizedBox.shrink();
          }

          return CustomPaint(
            painter: BalloonPainter(
              balloons: world.balloons,
              frenzy: false,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}
