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
    final start = Offset(
      size.width * (0.10 + rand.nextDouble() * 0.12),
      -size.height * (0.08 + rand.nextDouble() * 0.12),
    );

    // Target near center / mid-lower with small randomization
    final end = Offset(
      size.width * (0.50 + (rand.nextDouble() - 0.5) * 0.18),
      size.height * (0.60 + rand.nextDouble() * 0.18),
    );

    // Build a jagged path (single bolt)
    // More segments = more "bolt" and less "straight line"
    final segments = 14;
    final path = Path()..moveTo(start.dx, start.dy);

    for (int i = 1; i <= segments; i++) {
      final p = i / segments;
      final lerp = Offset.lerp(start, end, p)!;

      // Strongest jitter mid-bolt
      final midBoost = 1.0 - (2.0 * (p - 0.5)).abs(); // 0..1..0

      final jitterX = (rand.nextDouble() - 0.5) * size.width * 0.055 * midBoost;
      final jitterY = (rand.nextDouble() - 0.5) * size.height * 0.014 * midBoost;

      path.lineTo(lerp.dx + jitterX, lerp.dy + jitterY);
    }

    final alpha = _boltAlpha(t);

    final thickness = _thicknessForWorld(currentWorld);

    // Brighter core + stronger glow reads as "lightning" on all backgrounds
    final coreColor = const Color(0xFFF8FDFF).withOpacity(alpha);
    final glowColor = const Color(0xFF7EC8FF).withOpacity(alpha * 0.35);

    // Glow (wider)
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 3.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = glowColor;

    // Main bolt (core)
    final boltPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = coreColor;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, boltPaint);

    // Star specks ONLY on 3→4 transition (currentWorld == 3)
    if (currentWorld == 3) {
      _drawStarSpecks(canvas, end, rand, alpha);
    }
  }

  double _boltAlpha(double t) {
    // Fast in, then decay
    if (t < 0.08) {
      return (t / 0.08).clamp(0.0, 1.0);
    }
    final fade = (1.0 - ((t - 0.08) / 0.92)).clamp(0.0, 1.0);
    return fade * fade;
  }

  double _thicknessForWorld(int world) {
    switch (world) {
      case 1:
        return 2.8;
      case 2:
        return 3.8;
      case 3:
        return 5.0;
      default:
        return 3.8;
    }
  }

  void _drawStarSpecks(Canvas canvas, Offset center, Random rand, double alpha) {
    final speckCount = 16;
    final speckPaint = Paint()
      ..color = Colors.white.withOpacity(alpha * 0.6);

    for (int i = 0; i < speckCount; i++) {
      final angle = rand.nextDouble() * pi * 2;
      final radius = rand.nextDouble() * 46.0;
      final p = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );

      final r = 0.9 + rand.nextDouble() * 2.2;
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
