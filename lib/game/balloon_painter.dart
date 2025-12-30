import 'package:flutter/material.dart';
import 'package:balloon_burst/game/game_state.dart';
import 'balloon.dart';

class BalloonPainter extends CustomPainter {
  final List<Balloon> balloons;
  final GameState gameState;

  BalloonPainter(this.balloons, this.gameState);

  @override
  void paint(Canvas canvas, Size size) {
    // ✅ Viewport truth captured here
    gameState.viewportHeight = size.height;

    final bgPaint = Paint()..color = Colors.black;
    canvas.drawRect(Offset.zero & size, bgPaint);

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
