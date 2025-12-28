import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../game/balloon_painter.dart';
import '../gameplay/gameplay_world.dart';
import '../gameplay/balloon.dart';

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

  void _handleTap(TapDownDetails details, GameplayWorld world, Size size) {
    final tap = details.localPosition;

    const radius = 24.0;
    final centerX = size.width / 2;

    for (var i = 0; i < world.balloons.length; i++) {
      final b = world.balloons[i];
      if (b.isPopped) continue;

      final spreadPx = size.width * 0.35;
      final balloonX = centerX + (b.xOffset * spreadPx);
      final dx = balloonX - tap.dx;
      final dy = b.y - tap.dy;
      final dist = sqrt(dx * dx + dy * dy);

      if (dist <= radius) {
        _controller.onBalloonHit();
        _controller.world.value = world.popBalloonAt(i);
        return;
      }
    }

    _controller.onMiss();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ValueListenableBuilder<GameplayWorld?>(
            valueListenable: _controller.world,
            builder: (context, world, _) {
              if (world == null) {
                return const SizedBox.shrink();
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) =>
                    _handleTap(details, world, constraints.biggest),
                child: CustomPaint(
                  painter: BalloonPainter(
                    balloons: world.balloons,
                    frenzy: false,
                  ),
                  child: const SizedBox.expand(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
