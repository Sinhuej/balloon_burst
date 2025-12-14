import 'package:flutter/material.dart';
import '../main.dart';
import 'balloon.dart';

class BalloonPainter extends CustomPainter {
  final List<Balloon> balloons;
  final SkinDef skin;
  final bool frenzy;

  BalloonPainter({
    required this.balloons,
    required this.skin,
    required this.frenzy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = skin.background;
    canvas.drawRect(Offset.zero & size, bgPaint);

    for (final b in balloons) {
      final paint = Paint()
        ..color = (b.isGolden ? skin.goldGlowColor : skin.glowColor)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(b.position, b.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BalloonPainter oldDelegate) => true;
}
