import 'dart:math';
import 'package:flutter/material.dart';

/// LightningPainter v3 — TJ Brand Lightning
/// - Strong jagged diagonal
/// - Triple-layer bolt (glow + body + core)
/// - Escalates thickness by world
/// - World 3 slightly longer linger
class LightningPainter extends CustomPainter {
  final double t; // 0..1 animation progress
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

    // Start upper-left quadrant
    final start = Offset(
      size.width * (0.08 + rand.nextDouble() * 0.08),
      -size.height * (0.12 + rand.nextDouble() * 0.10),
    );

    // Target near mid-lower
    final end = Offset(
      size.width * (0.48 + (rand.nextDouble() - 0.5) * 0.20),
      size.height * (0.60 + rand.nextDouble() * 0.15),
    );

    final segments = 16;
    final path = Path()..moveTo(start.dx, start.dy);

    for (int i = 1; i <= segments; i++) {
      final p = i / segments;
      final base = Offset.lerp(start, end, p)!;

      // Stronger mid deviation
      final mid = 1.0 - (2.0 * (p - 0.5)).abs(); // 0..1..0

      final jitterX =
          (rand.nextDouble() - 0.5) * size.width * 0.10 * mid;
      final jitterY =
          (rand.nextDouble() - 0.5) * size.height * 0.04 * mid;

      path.lineTo(base.dx + jitterX, base.dy + jitterY);
    }

    final alpha = _alphaCurve(t);
    final thickness = _thicknessForWorld(currentWorld);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 3.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF6EC6FF).withOpacity(alpha * 0.25);

    final bodyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFEAF4FF).withOpacity(alpha);

    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 0.35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withOpacity(alpha);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, bodyPaint);
    canvas.drawPath(path, corePaint);

    if (currentWorld == 3) {
      _drawStarSpecks(canvas, end, rand, alpha);
    }
  }

  double _alphaCurve(double t) {
    // Slight linger in World 3
    final lingerMultiplier = currentWorld == 3 ? 1.08 : 1.0;
    final adjustedT = (t / lingerMultiplier).clamp(0.0, 1.0);

    if (adjustedT < 0.12) {
      return (adjustedT / 0.12).clamp(0.0, 1.0);
    }

    final fade = (1.0 - ((adjustedT - 0.12) / 0.88)).clamp(0.0, 1.0);
    return fade * fade;
  }

  double _thicknessForWorld(int world) {
    switch (world) {
      case 1:
        return 3.0;
      case 2:
        return 4.5;
      case 3:
        return 6.5;
      default:
        return 5.0;
    }
  }

  void _drawStarSpecks(
      Canvas canvas, Offset center, Random rand, double alpha) {
    final paint =
        Paint()..color = Colors.white.withOpacity(alpha * 0.6);

    for (int i = 0; i < 18; i++) {
      final angle = rand.nextDouble() * pi * 2;
      final radius = rand.nextDouble() * 50.0;
      final p = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );

      canvas.drawCircle(p, 1.2 + rand.nextDouble() * 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant LightningPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.currentWorld != currentWorld ||
        oldDelegate.seed != seed;
  }
}
