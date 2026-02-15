import 'dart:math';
import 'package:flutter/material.dart';

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
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _easeOutCubic(double x) => 1 - pow(1 - x, 3).toDouble();
  double _easeInCubic(double x) => x * x * x;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value.clamp(0.0, 1.0);

          // Opacity: hold, then fade last ~0.60s
          final opacity =
              (t < 0.80) ? 1.0 : (1.0 - (t - 0.80) / 0.20).clamp(0.0, 1.0);

          // Motion: slight lift early, then drift down as it fades
          final lift = -12.0 * _easeOutCubic((t / 0.30).clamp(0.0, 1.0));
          final drop = 22.0 * _easeInCubic(((t - 0.55) / 0.45).clamp(0.0, 1.0));
          final y = lift + drop;

          return Positioned.fill(
            child: Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, y),
                child: SizedBox.expand(
                  child: CustomPaint(
                    painter: _CarnivalPainter(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CarnivalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- COLORS (TapJunkie-safe) ---
    final skyPaint = Paint()..color = const Color(0xFF6EC6FF);
    final grassPaint = Paint()..color = const Color(0xFF2E7D32);

    // Muted carnival palette (not harsh black)
    final tentRed = const Color(0xFF7D1E22).withOpacity(0.70);
    final tentStripe = const Color(0xFFF5F5F5).withOpacity(0.40);
    final tentEdge = Colors.black.withOpacity(0.10);

    // Background ferris (dim + behind)
    final ferrisRim = Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    final ferrisSpoke = Paint()
      ..color = Colors.black.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final ferrisCabin = Paint()..color = Colors.black.withOpacity(0.18);

    // Lights
    final polePaint = Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final wirePaint = Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final glowPaint = Paint()
      ..color = const Color(0xFFFFE08A).withOpacity(0.24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final bulbPaint = Paint()
      ..color = const Color(0xFFFFD36A).withOpacity(0.95);

    // --- LAYOUT ---
    final hillTopY = h * 0.86;
    final hillSag = h * 0.075;

    // Stylized tent sizes (WIDE, not mountains)
    final baseY = hillTopY + 2.0;
    final bigH = h * 0.155;
    final smallH = h * 0.120;

    final bigW = w * 0.44;
    final smallW = w * 0.30;

    final bigCx = w * 0.50;
    final leftCx = w * 0.24;
    final rightCx = w * 0.76;

    // --- 1) SKY ---
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // --- 2) GRASS HILL (soft arc) ---
    final hillPath = Path()
      ..moveTo(-w * 0.15, hillTopY)
      ..quadraticBezierTo(w * 0.5, hillTopY - hillSag, w * 1.15, hillTopY)
      ..lineTo(w * 1.15, h)
      ..lineTo(-w * 0.15, h)
      ..close();
    canvas.drawPath(hillPath, grassPaint);

    // --- 3) FERRIS WHEEL (BACKGROUND, behind tents, partially hidden) ---
    // Bigger + further right, and clipped so only upper portion shows.
    final ferrisCenter = Offset(w * 0.84, baseY - bigH * 0.78);
    final ferrisRadius = h * 0.17;

    canvas.save();
    // Clip so the wheel is "behind the ground/tents"
    // Anything below this line won't draw.
    final clipY = baseY - bigH * 0.12;
    canvas.clipRect(Rect.fromLTWH(0, 0, w, clipY));

    canvas.drawCircle(ferrisCenter, ferrisRadius, ferrisRim);
    canvas.drawCircle(ferrisCenter, ferrisRadius * 0.10, ferrisCabin);

    const spokes = 12;
    for (int i = 0; i < spokes; i++) {
      final a = (i / spokes) * pi * 2;
      final p = Offset(
        ferrisCenter.dx + cos(a) * ferrisRadius,
        ferrisCenter.dy + sin(a) * ferrisRadius,
      );
      canvas.drawLine(ferrisCenter, p, ferrisSpoke);

      // Gondolas as dots around rim
      if (i % 2 == 0) {
        final g = Offset(
          ferrisCenter.dx + cos(a) * ferrisRadius * 1.02,
          ferrisCenter.dy + sin(a) * ferrisRadius * 1.02,
        );
        canvas.drawCircle(g, 3.0, ferrisCabin);
      }
    }

    canvas.restore();

    // --- 4) TENTS (MIDGROUND) ---
    _drawTent(
      canvas,
      cx: leftCx,
      baseY: baseY,
      width: smallW,
      height: smallH,
      red: tentRed,
      stripe: tentStripe,
      edge: tentEdge,
    );

    _drawTent(
      canvas,
      cx: bigCx,
      baseY: baseY,
      width: bigW,
      height: bigH,
      red: tentRed,
      stripe: tentStripe,
      edge: tentEdge,
    );

    _drawTent(
      canvas,
      cx: rightCx,
      baseY: baseY,
      width: smallW,
      height: smallH,
      red: tentRed,
      stripe: tentStripe,
      edge: tentEdge,
    );

    // --- 5) STRING LIGHTS (anchored poles + droop into center) ---
    final poleLeftX = w * 0.14;
    final poleRightX = w * 0.86;

    // Put poles around tent height, not in the sky
    final tentTopY = baseY - bigH;
    final poleTopY = tentTopY - h * 0.025;

    // Poles
    canvas.drawLine(Offset(poleLeftX, baseY), Offset(poleLeftX, poleTopY), polePaint);
    canvas.drawLine(Offset(poleRightX, baseY), Offset(poleRightX, poleTopY), polePaint);

    // Droop (lower in center)
    final midX = (poleLeftX + poleRightX) * 0.5;
    final sagY = poleTopY + h * 0.055; // visible droop

    final wire = Path()
      ..moveTo(poleLeftX, poleTopY)
      ..quadraticBezierTo(midX, sagY, poleRightX, poleTopY);

    canvas.drawPath(wire, wirePaint);

    // Bulbs + glow
    const bulbs = 14;
    for (int i = 0; i < bulbs; i++) {
      final p = i / (bulbs - 1);
      final x = _lerp(poleLeftX, poleRightX, p);
      final y = _quadBezierY(
        x,
        poleLeftX, poleTopY,
        midX, sagY,
        poleRightX, poleTopY,
      );

      final c = Offset(x, y);
      canvas.drawCircle(c, 6.0, glowPaint);
      canvas.drawCircle(c, 2.9, bulbPaint);
    }
  }

  void _drawTent(
    Canvas canvas, {
    required double cx,
    required double baseY,
    required double width,
    required double height,
    required Color red,
    required Color stripe,
    required Color edge,
  }) {
    final half = width * 0.5;
    final topY = baseY - height;

    // Curved "big-top" body (wide + playful)
    final body = Path()
      ..moveTo(cx - half, baseY)
      ..lineTo(cx - half * 0.78, topY + height * 0.28)
      ..quadraticBezierTo(cx, topY, cx + half * 0.78, topY + height * 0.28)
      ..lineTo(cx + half, baseY)
      ..close();

    // Fill
    canvas.drawPath(body, Paint()..color = red);

    // Subtle edge definition (helps it not look like mountains)
    canvas.drawPath(
      body,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Vertical stripes (clipped)
    final stripePaint = Paint()..color = stripe;
    const count = 8;
    for (int i = 0; i < count; i++) {
      final t = i / (count - 1);
      final x = (cx - half) + (width * t);
      final stripeW = width * 0.05;

      final stripeRect = Rect.fromLTWH(
        x - stripeW * 0.5,
        topY + height * 0.22,
        stripeW,
        height * 0.78,
      );

      canvas.save();
      canvas.clipPath(body);
      canvas.drawRect(stripeRect, stripePaint);
      canvas.restore();
    }

    // Little top flag
    final flag = Path()
      ..moveTo(cx, topY + height * 0.06)
      ..lineTo(cx - 7, topY + height * 0.14)
      ..lineTo(cx + 7, topY + height * 0.14)
      ..close();
    canvas.drawPath(flag, Paint()..color = stripe.withOpacity(0.55));
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double _quadBezierY(
    double x,
    double x0,
    double y0,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    // For gentle curves, linear t estimate is fine
    final t = ((x - x0) / (x2 - x0)).clamp(0.0, 1.0);
    final a = pow(1 - t, 2).toDouble();
    final b = 2 * (1 - t) * t;
    final c = t * t;
    return a * y0 + b * y1 + c * y2;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
