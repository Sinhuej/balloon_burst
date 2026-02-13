import 'dart:math';
import 'package:flutter/material.dart';

/// TAPJUNKIE Lightning v2 — Brand Strike
/// - Violent mid-bend
/// - Thick commanding silhouette
/// - 3-layer energy rendering
/// - Thickness pulses slightly during strike
/// - Star burst only on 3→4

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
      size.width * (0.08 + rand.nextDouble() * 0.08),
      -size.height * (0.14 + rand.nextDouble() * 0.08),
    );

    final end = Offset(
      size.width * (0.50 + (rand.nextDouble() - 0.5) * 0.22),
      size.height * (0.62 + rand.nextDouble() * 0.18),
    );

    final path = _buildAggressivePath(start, end, size, rand);

    final alpha = _boltAlpha(t);

    final baseThickness = _thicknessForWorld(currentWorld);

    // Pulse thickness slightly during strike
    final pulseBoost = 1.0 + (sin(t * pi) * 0.35);
    final thickness = baseThickness * pulseBoost;

    // OUTER ENERGY HALO
    final haloPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF5AB0FF).withOpacity(alpha * 0.22);

    // PRIMARY BODY
    final bodyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFEAF4FF).withOpacity(alpha);

    // INNER CORE (hot white center)
    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 0.55
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withOpacity(alpha * 1.4);

    canvas.drawPath(path, haloPaint);
    canvas.drawPath(path, bodyPaint);
    canvas.drawPath(path, corePaint);

    if (currentWorld == 3) {
      _drawStarBurst(canvas, end, rand, alpha);
    }
  }

  Path _buildAggressivePath(
      Offset start, Offset end, Size size, Random rand) {
    const segments = 14;
    final path = Path()..moveTo(start.dx, start.dy);

    for (int i = 1; i <= segments; i++) {
      final p = i / segments;
      final base = Offset.lerp(start, end, p)!;

      // Strongest violence in the middle
      final mid = 1.0 - (2.0 * (p - 0.5)).abs();

      final jitterX =
          (rand.nextDouble() - 0.5) * size.width * 0.12 * mid;

      final jitterY =
          (rand.nextDouble() - 0.5) * size.height * 0.04 * mid;

      path.lineTo(base.dx + jitterX, base.dy + jitterY);
    }

    return path;
  }

  double _boltAlpha(double t) {
    if (t < 0.06) {
      return (t / 0.06).clamp(0.0, 1.0);
    }

    final fade = (1.0 - ((t - 0.06) / 0.94)).clamp(0.0, 1.0);
    return fade * fade;
  }

  double _thicknessForWorld(int world) {
    switch (world) {
      case 1:
        return 3.5;
      case 2:
        return 5.0;
      case 3:
        return 7.5;
      default:
        return 5.0;
    }
  }

  void _drawStarBurst(
      Canvas canvas, Offset center, Random rand, double alpha) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(alpha * 0.7);

    for (int i = 0; i < 24; i++) {
      final angle = rand.nextDouble() * pi * 2;
      final radius = rand.nextDouble() * 60;

      final p = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );

      canvas.drawCircle(p, 1.2 + rand.nextDouble() * 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant LightningPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.currentWorld != currentWorld ||
        oldDelegate.seed != seed;
  }
}
