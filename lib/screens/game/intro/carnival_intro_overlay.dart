import 'dart:math';
import 'package:flutter/material.dart';

/// CarnivalIntroOverlay v2
/// - Tap-safe: IgnorePointer
/// - 3-second intro on fresh app launch
/// - Blue sky + green hill already in world 1
/// - Foreground balloon machine centered
/// - Background tents + ferris wheel + string lights
class CarnivalIntroOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const CarnivalIntroOverlay({
    super.key,
    required this.onComplete,
  });

  @override
  State<CarnivalIntroOverlay> createState() => _CarnivalIntroOverlayState();
}

class _CarnivalIntroOverlayState extends State<CarnivalIntroOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onComplete();
      });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value.clamp(0.0, 1.0);

          // Opacity: hold, then fade last ~0.65s
          final opacity = (t < 0.78) ? 1.0 : (1.0 - (t - 0.78) / 0.22).clamp(0.0, 1.0);

          // Motion: slight lift early, then drift downward as it fades
          final lift = -12.0 * _easeOutCubic((t / 0.30).clamp(0.0, 1.0));
          final drop = 22.0 * _easeInCubic(((t - 0.55) / 0.45).clamp(0.0, 1.0));
          final y = lift + drop;

          return Positioned.fill(
            child: Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, y),
                child: CustomPaint(
                  painter: _CarnivalPainter(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  double _easeOutCubic(double x) => 1 - pow(1 - x, 3).toDouble();
  double _easeInCubic(double x) => x * x * x;
}

class _CarnivalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- Layout anchors ---
    final hillTopY = h * 0.86;                 // top of hill arc
    final tentBaseY = hillTopY + 2;            // sit tents just on the hill
    final tentHBig = h * 0.18;
    final tentHSmall = h * 0.14;

    // --- Hill shadow arc (subtle grounding; real grass is behind in GameScreen) ---
    // We do NOT repaint grass/sky here; this is just a mild shadow line so silhouettes feel seated.
    final hillShadow = Paint()
      ..color = const Color(0xFF000000).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final hillPath = Path()
      ..moveTo(-w * 0.15, hillTopY)
      ..quadraticBezierTo(w * 0.50, hillTopY - h * 0.07, w * 1.15, hillTopY);

    canvas.drawPath(hillPath, hillShadow);

    // --- Ferris wheel (background; top 2/3 only) ---
    _drawFerrisWheel(
      canvas,
      size,
      center: Offset(w * 0.84, tentBaseY - tentHBig * 0.55),
      radius: tentHBig * 0.62,
      horizonY: hillTopY,
    );

    // --- Tents (midground) ---
    _drawTentCluster(canvas, size, baseY: tentBaseY, bigH: tentHBig, smallH: tentHSmall);

    // --- String lights (just above tent peaks, anchored) ---
    _drawStringLights(canvas, size, baseY: tentBaseY, tentTopY: tentBaseY - tentHBig);

    // --- Balloon machine (foreground center; NOT silhouette black) ---
    _drawBalloonMachine(canvas, size, baseY: tentBaseY);
  }

  void _drawTentCluster(Canvas canvas, Size size, {
    required double baseY,
    required double bigH,
    required double smallH,
  }) {
    final w = size.width;

    // Muted tent colors (not pure black)
    final tentRed = const Color(0xFF7D1E22).withOpacity(0.78);
    final stripe = const Color(0xFFF5F5F5).withOpacity(0.45);
    final tentShadow = const Color(0xFF000000).withOpacity(0.10);

    // Positions: left, center(big), right
    _drawTent(
      canvas,
      centerX: w * 0.33,
      baseY: baseY,
      width: w * 0.22,
      height: smallH,
      red: tentRed,
      stripe: stripe,
      shadow: tentShadow,
    );

    _drawTent(
      canvas,
      centerX: w * 0.52,
      baseY: baseY,
      width: w * 0.32,
      height: bigH,
      red: tentRed,
      stripe: stripe,
      shadow: tentShadow,
    );

    _drawTent(
      canvas,
      centerX: w * 0.70,
      baseY: baseY,
      width: w * 0.22,
      height: smallH,
      red: tentRed,
      stripe: stripe,
      shadow: tentShadow,
    );
  }

  void _drawTent(
    Canvas canvas, {
    required double centerX,
    required double baseY,
    required double width,
    required double height,
    required Color red,
    required Color stripe,
    required Color shadow,
  }) {
    final half = width / 2;
    final topY = baseY - height;

    // Tent body (trapezoid)
    final body = Path()
      ..moveTo(centerX - half, baseY)
      ..lineTo(centerX - half * 0.72, topY + height * 0.22)
      ..quadraticBezierTo(centerX, topY, centerX + half * 0.72, topY + height * 0.22)
      ..lineTo(centerX + half, baseY)
      ..close();

    // Fill
    final bodyPaint = Paint()..color = red;
    canvas.drawPath(body, bodyPaint);

    // Soft shadow at base
    final shadowPaint = Paint()..color = shadow;
    canvas.drawRect(
      Rect.fromLTWH(centerX - half, baseY - 4, width, 6),
      shadowPaint,
    );

    // Stripes (vertical)
    final stripePaint = Paint()..color = stripe;
    final stripeCount = 7;
    for (int i = 0; i < stripeCount; i++) {
      final x = centerX - half + (width * (i / (stripeCount - 1)));
      final stripeW = width * 0.055;

      final stripeRect = Rect.fromLTWH(x - stripeW / 2, topY + height * 0.18, stripeW, height * 0.80);
      canvas.save();
      canvas.clipPath(body);
      canvas.drawRect(stripeRect, stripePaint);
      canvas.restore();
    }

    // Small pennant at top
    final pennant = Path()
      ..moveTo(centerX, topY + height * 0.03)
      ..lineTo(centerX - 6, topY + height * 0.10)
      ..lineTo(centerX + 6, topY + height * 0.10)
      ..close();

    canvas.drawPath(pennant, Paint()..color = stripe.withOpacity(0.65));
  }

  void _drawFerrisWheel(Canvas canvas, Size size, {
    required Offset center,
    required double radius,
    required double horizonY,
  }) {
    // Dimmer than tents so it reads “background”
    final rimPaint = Paint()
      ..color = const Color(0xFF000000).withOpacity(0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final spokePaint = Paint()
      ..color = const Color(0xFF000000).withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final cabinPaint = Paint()
      ..color = const Color(0xFF000000).withOpacity(0.25)
      ..style = PaintingStyle.fill;

    // Clip so only top portion shows (distance illusion)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, horizonY - 2));

    canvas.drawCircle(center, radius, rimPaint);

    // Hub
    canvas.drawCircle(center, radius * 0.10, cabinPaint);

    // Spokes
    const spokes = 10;
    for (int i = 0; i < spokes; i++) {
      final a = (i / spokes) * pi * 2;
      final p = Offset(center.dx + cos(a) * radius, center.dy + sin(a) * radius);
      canvas.drawLine(center, p, spokePaint);

      // Cabins as dots near rim (top-heavy looks okay due to clip)
      if (i % 2 == 0) {
        final c = Offset(center.dx + cos(a) * radius * 1.02, center.dy + sin(a) * radius * 1.02);
        canvas.drawCircle(c, 2.6, cabinPaint);
      }
    }

    // Simple supports (also clipped)
    final baseY = horizonY - 2;
    final legPaint = Paint()
      ..color = const Color(0xFF000000).withOpacity(0.28)
      ..strokeWidth = 3.0;

    canvas.drawLine(
      center + Offset(-radius * 0.18, radius * 0.70),
      Offset(center.dx - radius * 0.55, baseY),
      legPaint,
    );
    canvas.drawLine(
      center + Offset(radius * 0.18, radius * 0.70),
      Offset(center.dx + radius * 0.55, baseY),
      legPaint,
    );

    canvas.restore();
  }

  void _drawStringLights(Canvas canvas, Size size, {
    required double baseY,
    required double tentTopY,
  }) {
    final w = size.width;

    final leftPoleX = w * 0.22;
    final rightPoleX = w * 0.84;
    final poleTopY = baseY - (baseY - tentTopY) * 0.95; // near tent peak height

    // Poles
    final polePaint = Paint()
      ..color = const Color(0xFF000000).withOpacity(0.35)
      ..strokeWidth = 3.0;

    canvas.drawLine(Offset(leftPoleX, baseY), Offset(leftPoleX, poleTopY), polePaint);
    canvas.drawLine(Offset(rightPoleX, baseY), Offset(rightPoleX, poleTopY), polePaint);

    // Sag curve just above tents
    final midX = (leftPoleX + rightPoleX) / 2;
    final sagY = poleTopY + (baseY - poleTopY) * 0.22;

    final wire = Path()
      ..moveTo(leftPoleX, poleTopY)
      ..quadraticBezierTo(midX, sagY, rightPoleX, poleTopY);

    final wirePaint = Paint()
      ..color = const Color(0xFF000000).withOpacity(0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawPath(wire, wirePaint);

    // Bulbs: warm yellow with glow halo
    final glowPaint = Paint()
      ..color = const Color(0xFFFFE08A).withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final bulbPaint = Paint()
      ..color = const Color(0xFFFFD36A).withOpacity(0.92);

    const bulbs = 13;
    for (int i = 0; i < bulbs; i++) {
      final p = i / (bulbs - 1);
      final x = _lerp(leftPoleX, rightPoleX, p);

      // Evaluate quadratic Bezier point (same as wire)
      final y = _quadBezierY(
        x,
        leftPoleX, poleTopY,
        midX, sagY,
        rightPoleX, poleTopY,
      );

      final c = Offset(x, y);
      canvas.drawCircle(c, 6.0, glowPaint);
      canvas.drawCircle(c, 2.8, bulbPaint);
    }
  }

  double _quadBezierY(double x,
      double x0, double y0,
      double x1, double y1,
      double x2, double y2) {
    // Invert x->t approx using linear ratio (good enough for our gentle curve)
    final t = ((x - x0) / (x2 - x0)).clamp(0.0, 1.0);
    final a = pow(1 - t, 2).toDouble();
    final b = 2 * (1 - t) * t;
    final c = t * t;
    return a * y0 + b * y1 + c * y2;
  }

  void _drawBalloonMachine(Canvas canvas, Size size, {required double baseY}) {
    final w = size.width;

    // Center it under spawn (you said balloons start center)
    final cx = w * 0.50;

    // Machine scale
    final machineH = size.height * 0.18;
    final machineW = w * 0.12;

    final topY = baseY - machineH;
    final left = cx - machineW / 2;

    // Shadow so it separates from tents
    final shadow = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, baseY + 6), width: machineW * 1.3, height: 12),
      shadow,
    );

    // Base body (deep carnival red)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, topY + machineH * 0.22, machineW, machineH * 0.78),
      const Radius.circular(10),
    );

    final bodyPaint = Paint()..color = const Color(0xFF8A1C1F).withOpacity(0.92);
    canvas.drawRRect(bodyRect, bodyPaint);

    // Highlight edge
    final highlight = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(bodyRect, highlight);

    // Glass chamber (silver bezel + light blue glass)
    final chamberRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + machineW * 0.12, topY, machineW * 0.76, machineH * 0.36),
      const Radius.circular(14),
    );

    final bezel = Paint()
      ..color = const Color(0xFFB9BFC7).withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final glass = Paint()
      ..color = const Color(0xFFBFE8FF).withOpacity(0.22);

    canvas.drawRRect(chamberRect, glass);
    canvas.drawRRect(chamberRect, bezel);

    // Lever/handle (right side)
    final leverPaint = Paint()
      ..color = const Color(0xFF2C2C2C).withOpacity(0.65)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final leverBase = Offset(left + machineW * 0.80, topY + machineH * 0.62);
    canvas.drawLine(leverBase, leverBase + const Offset(14, -10), leverPaint);
    canvas.drawCircle(leverBase + const Offset(16, -12), 5, Paint()..color = const Color(0xFFB9BFC7).withOpacity(0.75));

    // Coin slot (small detail)
    final slotPaint = Paint()..color = Colors.black.withOpacity(0.22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + machineW * 0.36, topY + machineH * 0.56, machineW * 0.28, 10),
        const Radius.circular(6),
      ),
      slotPaint,
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
