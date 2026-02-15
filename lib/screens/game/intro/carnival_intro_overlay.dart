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
          final drop =
              22.0 * _easeInCubic(((t - 0.55) / 0.45).clamp(0.0, 1.0));
          final y = lift + drop;

          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, y),
              child: const SizedBox.expand(
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
}

class _CarnivalPainter extends CustomPainter {
  const _CarnivalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- SKY + GRASS (full overlay) ---
    final skyPaint = Paint()..color = const Color(0xFF6EC6FF);
    final grassPaint = Paint()..color = const Color(0xFF2E7D32);

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    final hillTopY = h * 0.86;
    final hillSag = h * 0.075;

    final hillPath = Path()
      ..moveTo(-w * 0.15, hillTopY)
      ..quadraticBezierTo(w * 0.50, hillTopY - hillSag, w * 1.15, hillTopY)
      ..lineTo(w * 1.15, h)
      ..lineTo(-w * 0.15, h)
      ..close();

    canvas.drawPath(hillPath, grassPaint);

    // --- Layout anchors ---
    final baseY = hillTopY + 2.0;

    // Tents: wider + playful proportions
    final bigH = h * 0.150;
    final smallH = h * 0.118;

    final bigW = w * 0.50;
    final smallW = w * 0.34;

    final bigCx = w * 0.50;
    final leftCx = w * 0.25;
    final rightCx = w * 0.75;

    // Colors (muted but readable)
    final tentRed = const Color(0xFF7D1E22).withOpacity(0.70);
    final tentStripe = const Color(0xFFF5F5F5).withOpacity(0.38);
    final tentEdge = Colors.black.withOpacity(0.10);

    // --- Ferris Wheel (background, partially hidden behind tents) ---
    _drawFerrisWheelBehindTents(
      canvas,
      size,
      baseY: baseY,
      tentTopY: baseY - bigH,
      center: Offset(w * 0.86, baseY - bigH * 0.88),
      radius: h * 0.20,
    );

    // --- Tents (midground) ---
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

    // --- String lights (poles high on ends, droop low in center) ---
    _drawStringLights(
      canvas,
      size,
      baseY: baseY,
      tentTopY: baseY - bigH,
      leftX: w * 0.12,
      rightX: w * 0.88,
    );

    // --- Balloon machine (foreground, centered, clearly separate) ---
    _drawBalloonMachine(canvas, size, baseY: baseY);
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

    // Wide, “big-top” curved cap (not mountains)
    final body = Path()
      ..moveTo(cx - half, baseY)
      ..lineTo(cx - half * 0.82, topY + height * 0.32)
      ..quadraticBezierTo(cx, topY, cx + half * 0.82, topY + height * 0.32)
      ..lineTo(cx + half, baseY)
      ..close();

    canvas.drawPath(body, Paint()..color = red);

    canvas.drawPath(
      body,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Stripes (clipped)
    final stripePaint = Paint()..color = stripe;
    const count = 9;
    for (int i = 0; i < count; i++) {
      final t = i / (count - 1);
      final x = (cx - half) + (width * t);
      final stripeW = width * 0.050;

      final stripeRect = Rect.fromLTWH(
        x - stripeW * 0.5,
        topY + height * 0.24,
        stripeW,
        height * 0.76,
      );

      canvas.save();
      canvas.clipPath(body);
      canvas.drawRect(stripeRect, stripePaint);
      canvas.restore();
    }

    // Small flag
    final flag = Path()
      ..moveTo(cx, topY + height * 0.06)
      ..lineTo(cx - 7, topY + height * 0.15)
      ..lineTo(cx + 7, topY + height * 0.15)
      ..close();
    canvas.drawPath(flag, Paint()..color = stripe.withOpacity(0.55));
  }

  void _drawFerrisWheelBehindTents(
    Canvas canvas,
    Size size, {
    required double baseY,
    required double tentTopY,
    required Offset center,
    required double radius,
  }) {
    // Dimmer so it reads background
    final rim = Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final spoke = Paint()
      ..color = Colors.black.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final cabin = Paint()..color = Colors.black.withOpacity(0.18);

    // Clip so it appears behind tents/ground (only upper portion)
    canvas.save();
    final clipY = tentTopY + (baseY - tentTopY) * 0.15;
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, clipY));

    canvas.drawCircle(center, radius, rim);
    canvas.drawCircle(center, radius * 0.10, cabin);

    const spokes = 12;
    for (int i = 0; i < spokes; i++) {
      final a = (i / spokes) * pi * 2;
      final p = Offset(center.dx + cos(a) * radius, center.dy + sin(a) * radius);
      canvas.drawLine(center, p, spoke);

      // Gondolas as dots
      if (i.isEven) {
        final g = Offset(
          center.dx + cos(a) * radius * 1.02,
          center.dy + sin(a) * radius * 1.02,
        );
        canvas.drawCircle(g, 3.0, cabin);
      }
    }

    canvas.restore();
  }

  void _drawStringLights(
    Canvas canvas,
    Size size, {
    required double baseY,
    required double tentTopY,
    required double leftX,
    required double rightX,
  }) {
    final h = size.height;

    final poleTopY = tentTopY - h * 0.030; // slightly above tent peaks
    final polePaint = Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Poles
    canvas.drawLine(Offset(leftX, baseY), Offset(leftX, poleTopY), polePaint);
    canvas.drawLine(Offset(rightX, baseY), Offset(rightX, poleTopY), polePaint);

    // Wire (droops low in center)
    final midX = (leftX + rightX) * 0.5;
    final sagY = poleTopY + h * 0.060;

    final wire = Path()
      ..moveTo(leftX, poleTopY)
      ..quadraticBezierTo(midX, sagY, rightX, poleTopY);

    final wirePaint = Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawPath(wire, wirePaint);

    // Warm bulbs + glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFE08A).withOpacity(0.24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final bulbPaint = Paint()
      ..color = const Color(0xFFFFD36A).withOpacity(0.95);

    const bulbs = 14;
    for (int i = 0; i < bulbs; i++) {
      final p = i / (bulbs - 1);
      final x = _lerp(leftX, rightX, p);
      final y = _quadBezierY(x, leftX, poleTopY, midX, sagY, rightX, poleTopY);

      final c = Offset(x, y);
      canvas.drawCircle(c, 6.0, glowPaint);
      canvas.drawCircle(c, 2.9, bulbPaint);
    }
  }

  void _drawBalloonMachine(Canvas canvas, Size size, {required double baseY}) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.50;

    final machineH = h * 0.18;
    final machineW = w * 0.15;

    final topY = baseY - machineH * 1.05;
    final left = cx - machineW * 0.5;

    // Shadow so it separates from tents
    final shadow = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseY + 7),
        width: machineW * 1.25,
        height: 14,
      ),
      shadow,
    );

    // Base body (deep carnival red)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, topY + machineH * 0.30, machineW, machineH * 0.78),
      const Radius.circular(12),
    );

    final bodyPaint = Paint()..color = const Color(0xFF8A1C1F).withOpacity(0.95);
    canvas.drawRRect(bodyRect, bodyPaint);

    // Subtle highlight stroke
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = Colors.white.withOpacity(0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Glass chamber (top)
    final chamberRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + machineW * 0.10, topY, machineW * 0.80, machineH * 0.40),
      const Radius.circular(16),
    );

    final glass = Paint()..color = const Color(0xFFBFE8FF).withOpacity(0.22);
    final bezel = Paint()
      ..color = const Color(0xFFB9BFC7).withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRRect(chamberRect, glass);
    canvas.drawRRect(chamberRect, bezel);

    // “Cap” to make it read like a machine, not a tent doorway
    final capRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + machineW * 0.06, topY - machineH * 0.07, machineW * 0.88, machineH * 0.12),
      const Radius.circular(10),
    );
    canvas.drawRRect(capRect, Paint()..color = Colors.black.withOpacity(0.10));

    // Knob + lever (right side)
    final leverPaint = Paint()
      ..color = Colors.black.withOpacity(0.50)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final leverBase = Offset(left + machineW * 0.82, topY + machineH * 0.72);
    canvas.drawLine(leverBase, leverBase + const Offset(14, -10), leverPaint);

    final knob = Paint()..color = const Color(0xFFB9BFC7).withOpacity(0.80);
    canvas.drawCircle(leverBase + const Offset(16, -12), 5.5, knob);

    // Coin slot detail
    final slotPaint = Paint()..color = Colors.black.withOpacity(0.20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + machineW * 0.34, topY + machineH * 0.60, machineW * 0.32, 10),
        const Radius.circular(6),
      ),
      slotPaint,
    );
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
    final t = ((x - x0) / (x2 - x0)).clamp(0.0, 1.0);
    final a = pow(1 - t, 2).toDouble();
    final b = 2 * (1 - t) * t;
    final c = t * t;
    return a * y0 + b * y1 + c * y2;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
