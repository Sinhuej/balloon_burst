import 'package:flutter/material.dart';
import 'package:balloon_burst/game/game_state.dart';
import 'balloon.dart';

class BalloonPainter extends CustomPainter {
  final List<Balloon> balloons;
  final GameState gameState;

  BalloonPainter(this.balloons, this.gameState);

  @override
  void paint(Canvas canvas, Size size) {
    // Viewport truth captured here
    gameState.viewportHeight = size.height;

    // Background
    final bgPaint = Paint()..color = Colors.black;
    canvas.drawRect(Offset.zero & size, bgPaint);

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

    // Tap feedback pulse (very subtle, one frame)
    if (gameState.tapPulse) {
      final pulsePaint = Paint()
        ..color = const Color.fromARGB(18, 80, 160, 255);
      canvas.drawRect(Offset.zero & size, pulsePaint);

      // Clear immediately (one-frame pulse)
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
