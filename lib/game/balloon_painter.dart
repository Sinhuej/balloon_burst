import 'package:flutter/material.dart';
import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/gameplay/balloon.dart';

class BalloonPainter extends CustomPainter {
  final List<Balloon> balloons;
  final GameState gameState;

  BalloonPainter(this.balloons, this.gameState);

  @override
  void paint(Canvas canvas, Size size) {
    // Viewport truth
    gameState.viewportHeight = size.height;
    gameState.framesSinceStart++;

    // Background
    final bgPaint = Paint()..color = Colors.black;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Subtle bottom danger affordance (visual only)
    final dangerHeight = 40.0;
    final dangerRect = Rect.fromLTWH(
      0,
      size.height - dangerHeight,
      size.width,
      dangerHeight,
    );

    final dangerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Color.fromARGB(20, 255, 0, 0),
        ],
      ).createShader(dangerRect);

    canvas.drawRect(dangerRect, dangerPaint);

    // Intro banner (first ~1.5s @ ~60fps)
    if (gameState.framesSinceStart < 90) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Tap to Burst',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(
        (size.width - textPainter.width) / 2,
        size.height * 0.25,
      );

      textPainter.paint(canvas, offset);
    }

    // Tap feedback pulse (one frame)
    if (gameState.tapPulse) {
      final pulsePaint = Paint()
        ..color = const Color.fromARGB(18, 80, 160, 255);
      canvas.drawRect(Offset.zero & size, pulsePaint);
      gameState.tapPulse = false;
    }

    // Balloons
    for (final balloon in balloons) {
      final paint = Paint()
        ..color = balloon.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(balloon.x, balloon.y),
        balloon.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BalloonPainter oldDelegate) => true;
}
