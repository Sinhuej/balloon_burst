import 'dart:math';
import 'package:flutter/material.dart';

/// TAPJUNKIE LightningPainter v1 (Brand Bolt)
/// - Single iconic jagged bolt
/// - Upper-left → mid-lower
/// - World-based thickness progression
/// - Subtle flicker life
/// - 3-layer rendering (glow + body + core)
/// - Star specks only on 3→4 transition

class LightningPainter extends CustomPainter {
  final double t; // 0..1
  final int currentWorld;
  final int seed;

  LightningPainter({
    required this.t,
    required this.currentWorld,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;

    final rand = Random(seed);

    final start = Offset(
      size.width * (0.10 + rand.nextDouble() * 0.10),
      -size.height * (0.12 + rand.nextDouble() * 0.08),
    );

    final end = Offset(
      size.width * (0.48 + (rand.nextDouble() - 0.5) * 0.16),
      size.height * (0.60 + rand.nextDouble() * 0.14),
    );

    final path = _buildJaggedPath(start, end, size, rand);

    final flicker = 0.90 + rand.nextDouble() * 0.25;
    final alpha = _boltAlpha(t) * flicker;

    final thickness = _thicknessForWorld(currentWorld);

    // OUTER GLOW
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF7EC8FF).withOpacity(alpha * 0.25);

    // MAIN BODY
    final bodyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFEAF4FF).withOpacity(alpha);

    // INNER CORE (energy)
    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 0.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withOpacity(alpha * 1.2);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, bodyPaint);
    canvas.drawPath(path, corePaint);

    if (currentWorld == 3) {
      _drawStarSpecks(canvas, end, rand, alpha);
    }
  }

  Path _buildJaggedPath(
      Offset start, Offset end, Size size, Random rand) {
    const segments = 12;
    final path = Path()..moveTo(start.dx, start.dy);

    for (int i = 1; i <= segments; i++) {
      final p = i / segments;
      final base = Offset.lerp(start, end, p)!;

      final midBoost = 1.0 - (2.0 * (p - 0.5)).abs();

      final jitterX =
          (rand.nextDouble() - 0.5) * size.width * 0.07 * midBoost;

      final jitterY =
          (rand.nextDouble() - 0.5) * size.height * 0.025 * midBoost;

      final point = Offset(base.dx + jitterX, base.dy + jitterY);
      path.lineTo(point.dx, point.dy);
    }

    return path;
  }

  double _boltAlpha(double t) {
    if (t < 0.08) {
      return (t / 0.08).clamp(0.0, 1.0);
    }
    final fade = (1.0 - ((t - 0.08) / 0.92)).clamp(0.0, 1.0);
    return fade * fade;
  }

  double _thicknessForWorld(int world) {
    switch (world) {
      case 1:
        return 2.5;
      case 2:
        return 3.5;
      case 3:
        return 4.8;
      default:
        return 3.5;
    }
  }

  void _drawStarSpecks(
      Canvas canvas, Offset center, Random rand, double alpha) {
    final speckPaint = Paint()
      ..color = Colors.white.withOpacity(alpha * 0.6);

    for (int i = 0; i < 18; i++) {
      final angle = rand.nextDouble() * pi * 2;
      final radius = rand.nextDouble() * 50.0;

      final p = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );

      canvas.drawCircle(p, 0.8 + rand.nextDouble() * 2.2, speckPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LightningPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.currentWorld != currentWorld ||
        oldDelegate.seed != seed;
  }
}
