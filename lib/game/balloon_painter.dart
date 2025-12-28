import 'package:flutter/material.dart';
import '../gameplay/balloon.dart';

class BalloonPainter extends CustomPainter {
  final List<Balloon> balloons;
  final bool frenzy;

  BalloonPainter({
    required this.balloons,
    required this.frenzy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final centerX = size.width / 2;
    const radius = 24.0;

    // Horizontal spread scale (screen-relative)
    final spreadPx = size.width * 0.35;

    for (final b in balloons) {
      if (b.isPopped) continue;

      final paint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      // 🔑 THIS IS THE FIX:
      // Apply xOffset to center position
      final x = centerX + (b.xOffset * spreadPx);
      final y = b.y;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BalloonPainter oldDelegate) => true;
}
