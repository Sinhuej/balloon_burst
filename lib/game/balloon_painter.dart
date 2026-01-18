import 'package:flutter/material.dart';
import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/gameplay/balloon.dart';

class BalloonPainter extends CustomPainter {
  final List<Balloon> balloons;
  final GameState gameState;

  BalloonPainter(this.balloons, this.gameState);

  static const double balloonRadius = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Viewport truth
    gameState.viewportHeight = size.height;
    gameState.framesSinceStart++;

    // Subtle bottom danger affordance
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

    // Intro banner (first ~1.5s)
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

    // Tap feedback pulse
    if (gameState.tapPulse) {
      final pulsePaint = Paint()
        ..color = const Color.fromARGB(18, 80, 160, 255);
      canvas.drawRect(Offset.zero & size, pulsePaint);
      gameState.tapPulse = false;
    }

    // Balloons
    final centerX = size.width / 2;

    for (final balloon in balloons) {
      if (balloon.isPopped) continue;

      final paint = Paint()
        ..color = Colors.redAccent
        ..style = PaintingStyle.fill;

      final x = centerX + (balloon.xOffset * size.width * 0.5);

      // IMPORTANT: Balloon.y is the circle center y.
      final y = balloon.y;

      canvas.drawCircle(
        Offset(x, y),
        balloonRadius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BalloonPainter oldDelegate) => true;
}
