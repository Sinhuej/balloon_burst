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
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final centerX = size.width / 2;
    const radius = 24.0;

    for (final b in balloons) {
      if (b.isPopped) continue;

      final paint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      final position = Offset(centerX, b.y);
      canvas.drawCircle(position, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BalloonPainter oldDelegate) => true;
}
