import 'dart:math';
import 'package:flutter/material.dart';

/// LightningPainter (visual-only)
/// - Single jagged bolt path (brand-recognizable)
/// - Upper-left quadrant → mid-lower target
/// - Slight randomization, same general diagonal direction
/// - Thickness increases by world (progression)
/// - Optional star specks ONLY for 3→4 transition (currentWorld == 3)
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

    // Start upper-left (slightly off-screen)
    final start = Offset(size.width * (0.12 + rand.nextDouble() * 0.10),
        -size.height * (0.10 + rand.nextDouble() * 0.10));

    // Target near center / mid-lower with small randomization
    final end = Offset(
      size.width * (0.48 + (rand.nextDouble() - 0.5) * 0.18),
      size.height * (0.58 + rand.nextDouble() * 0.16),
    );

    // Build a jagged path (single bolt)
    final segments = 10;
    final path = Path()..moveTo(start.dx, start.dy);

    for (int i = 1; i <= segments; i++) {
      final p = i / segments;
      final lerp = Offset.lerp(start, end, p)!;

      // Per-segment jitter; strongest in the middle
      final midBoost = 1.0 - (2.0 * (p - 0.5)).abs(); // 0..1..0
      final jitterX = (rand.nextDouble() - 0.5) * size.width * 0.04 * midBoost;
      final jitterY = (rand.nextDouble() - 0.5) * size.height * 0.01 * midBoost;

      final point = Offset(lerp.dx + jitterX, lerp.dy + jitterY);
      path.lineTo(point.dx, point.dy);
    }

    // Opacity curve: visible quickly, fades out by end
    final alpha = _boltAlpha(t);

    // Thickness by world (progression)
    final thickness = _thicknessForWorld(currentWorld);

    // Color (kept mostly consistent for brand identity)
    final boltColor = const Color(0xFFEAF4FF).withOpacity(alpha);
    final glowColor = const Color(0xFF7EC8FF).withOpacity(alpha * 0.22);

    // Glow (wider)
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = glowColor;

    // Main bolt
    final boltPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = boltColor;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, boltPaint);

    // Star specks ONLY on 3→4 transition (currentWorld == 3)
    if (currentWorld == 3) {
      _drawStarSpecks(canvas, size, end, rand, alpha);
    }
  }

  double _boltAlpha(double t) {
    // Fast in, then decay
    if (t < 0.10) {
      return (t / 0.10).clamp(0.0, 1.0);
    }
    final fade = (1.0 - ((t - 0.10) / 0.90)).clamp(0.0, 1.0);
    return fade * fade;
  }

  double _thicknessForWorld(int world) {
    // World 1 thin → World 3 thicker
    switch (world) {
      case 1:
        return 2.2;
      case 2:
        return 3.2;
      case 3:
        return 4.2;
      default:
        return 3.2;
    }
  }

  void _drawStarSpecks(
    Canvas canvas,
    Size size,
    Offset center,
    Random rand,
    double alpha,
  ) {
    final speckCount = 14;
    final speckPaint = Paint()
      ..color = Colors.white.withOpacity(alpha * 0.55);

    for (int i = 0; i < speckCount; i++) {
      final angle = rand.nextDouble() * pi * 2;
      final radius = rand.nextDouble() * 42.0;
      final p = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );

      final r = 0.8 + rand.nextDouble() * 1.8;
      canvas.drawCircle(p, r, speckPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LightningPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.currentWorld != currentWorld ||
        oldDelegate.seed != seed;
  }
}
