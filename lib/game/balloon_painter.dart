import 'package:flutter/material.dart';
import '../ui/skins.dart';
import '../gameplay/balloon.dart';

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
    // Background
    final bgPaint = Paint()..color = skin.background;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final centerX = size.width / 2;
    const radius = 24.0;

    for (final b in balloons) {
      if (b.isPopped) continue;

      final paint = Paint()
        ..color = skin.glowColor
        ..style = PaintingStyle.fill;

      // 🔑 THIS IS THE KEY CHANGE:
      // Balloon vertical position now comes from simulation (b.y)
      final position = Offset(centerX, b.y);

      canvas.drawCircle(position, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BalloonPainter oldDelegate) => true;
}
