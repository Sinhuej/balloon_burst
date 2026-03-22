import 'dart:math';
import 'package:flutter/material.dart';

/// LightningPainter v4 — TJ Signature Lightning
/// - Bigger, louder diagonal strike
/// - Triple-layer bolt with hotter cyan glow
/// - Side-branch forks for personality
/// - Stronger world escalation
/// - Signature sparkle accent for premium feel
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

    final start = Offset(
      size.width * (0.05 + rand.nextDouble() * 0.10),
      -size.height * (0.16 + rand.nextDouble() * 0.10),
    );

    final end = Offset(
      size.width * (0.50 + (rand.nextDouble() - 0.5) * 0.24),
      size.height * (0.68 + rand.nextDouble() * 0.16),
    );

    final segments = 20;
    final points = <Offset>[start];
    final path = Path()..moveTo(start.dx, start.dy);

    for (int i = 1; i <= segments; i++) {
      final p = i / segments;
      final base = Offset.lerp(start, end, p)!;

      final mid = 1.0 - (2.0 * (p - 0.5)).abs();

      final jitterX =
          (rand.nextDouble() - 0.5) * size.width * 0.14 * mid;
      final jitterY =
          (rand.nextDouble() - 0.5) * size.height * 0.055 * mid;

      final point = Offset(base.dx + jitterX, base.dy + jitterY);
      points.add(point);
      path.lineTo(point.dx, point.dy);
    }

    final alpha = _alphaCurve(t);
    final thickness = _thicknessForWorld(currentWorld);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 4.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF00D8FF).withOpacity(alpha * 0.30);

    final outerBodyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 1.45
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFA8F3FF).withOpacity(alpha * 0.95);

    final bodyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFEAF8FF).withOpacity(alpha);

    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 0.42
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withOpacity(alpha);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, outerBodyPaint);
    canvas.drawPath(path, bodyPaint);
    canvas.drawPath(path, corePaint);

    _drawBranches(
      canvas: canvas,
      points: points,
      rand: rand,
      alpha: alpha,
      thickness: thickness,
    );

    _drawStrikeBloom(canvas, end, alpha);
    _drawStarSpecks(canvas, end, rand, alpha);
  }

  double _alphaCurve(double t) {
    final lingerMultiplier = currentWorld >= 3 ? 1.12 : 1.0;
    final adjustedT = (t / lingerMultiplier).clamp(0.0, 1.0);

    if (adjustedT < 0.10) {
      return (adjustedT / 0.10).clamp(0.0, 1.0);
    }

    final fade = (1.0 - ((adjustedT - 0.10) / 0.90)).clamp(0.0, 1.0);
    return fade * fade;
  }

  double _thicknessForWorld(int world) {
    switch (world) {
      case 1:
        return 3.8;
      case 2:
        return 5.6;
      case 3:
        return 7.8;
      default:
        return 6.6;
    }
  }

  void _drawBranches({
    required Canvas canvas,
    required List<Offset> points,
    required Random rand,
    required double alpha,
    required double thickness,
  }) {
    if (points.length < 8) return;

    final branchGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF00D8FF).withOpacity(alpha * 0.16);

    final branchBody = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 0.58
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withOpacity(alpha * 0.80);

    final branchCount = currentWorld >= 3 ? 3 : 2;

    for (int i = 0; i < branchCount; i++) {
      final idx = 4 + rand.nextInt(points.length - 6);
      final start = points[idx];

      final direction = rand.nextBool() ? 1.0 : -1.0;
      final end = Offset(
        start.dx + direction * (26 + rand.nextDouble() * 34),
        start.dy + (18 + rand.nextDouble() * 30),
      );

      final mid = Offset(
        (start.dx + end.dx) * 0.5 + direction * (8 + rand.nextDouble() * 10),
        (start.dy + end.dy) * 0.5,
      );

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);

      canvas.drawPath(path, branchGlow);
      canvas.drawPath(path, branchBody);
    }
  }

  void _drawStrikeBloom(Canvas canvas, Offset center, double alpha) {
    final glowPaint = Paint()
      ..color = const Color(0xFF9EF3FF).withOpacity(alpha * 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);

    final corePaint = Paint()
      ..color = Colors.white.withOpacity(alpha * 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(center, 26, glowPaint);
    canvas.drawCircle(center, 10, corePaint);
  }

  void _drawStarSpecks(
    Canvas canvas,
    Offset center,
    Random rand,
    double alpha,
  ) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(alpha * 0.62);

    final count = currentWorld >= 3 ? 22 : 14;
    final radiusMax = currentWorld >= 3 ? 58.0 : 40.0;

    for (int i = 0; i < count; i++) {
      final angle = rand.nextDouble() * pi * 2;
      final radius = rand.nextDouble() * radiusMax;
      final p = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );

      canvas.drawCircle(p, 1.0 + rand.nextDouble() * 1.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant LightningPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.currentWorld != currentWorld ||
        oldDelegate.seed != seed;
  }
}
