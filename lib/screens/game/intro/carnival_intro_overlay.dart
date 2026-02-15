import 'dart:math';
import 'package:flutter/material.dart';

/// CarnivalIntroOverlay v3 (TapJunkie)
/// - Self-contained paint: sky + hill + tents + lights + ferris + balloon machine
/// - Tap-safe: IgnorePointer
/// - 3-second intro on fresh app launch
/// - Foreground balloon machine centered + separated (shadow + rim)
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
          final opacity =
              (t < 0.78) ? 1.0 : (1.0 - (t - 0.78) / 0.22).clamp(0.0, 1.0);

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

    // ----- COLORS (brand-safe) -----
    final sky = Paint()..color = const Color(0xFF6EC6FF); // World 1 sky
    final grass = Paint()..color = const Color(0xFF2E7D32); // deep green
    final grassShadow = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // ----- LAYOUT -----
    final hillTopY = h * 0.86; // top of hill arc
    final hillSag = h * 0.075; // how tall the arc is
    final tentBaseY = hillTopY + 2;

    // Sizes
    final bigH = h * 0.18;
    final smallH = h * 0.14;

    // 1) SKY
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sky);

    // 2) HILL (curved arc)
    final hillPath = Path()
      ..moveTo(-w * 0.15, hillTopY)
      ..quadraticBezierTo(w * 0.50, hillTopY - hillSag, w * 1.15, hillTopY)
      ..lineTo(w * 1.15, h + 2)
      ..lineTo(-w * 0.15, h + 2)
      ..close();
    canvas.drawPath(hillPath, grass);
    canvas.drawPath(
      Path()
        ..moveTo(-w * 0.15, hillTopY)
        ..quadraticBezierTo(w * 0.50, hillTopY - hillSag, w * 1.15, hillTopY),
      grassShadow,
    );

    // 3) FERRIS (background behind tents, top 2/3 visible)
    _drawFerrisWheel(
      canvas,
      size,
      center: Offset(w * 0.84, tentBaseY - bigH * 0.55),
      radius: bigH * 0.70,
      clipBottomY: hillTopY - 2,
    );

    // 4) TENTS (spread horizontally; center big, sides smaller)
    _drawTentCluster(
      canvas,
      size,
      baseY: tentBaseY,
      bigH: bigH,
      smallH: smallH,
    );

    // 5) STRING LIGHTS (lower, draped across tents)
    _drawStringLights(
      canvas,
      size,
      baseY: tentBaseY,
      tentPeakY: (tentBaseY - bigH * 1.02),
    );

    // 6) BALLOON MACHINE (foreground center; deep red + separation)
    _drawBalloonMachine(canvas, size, baseY: tentBaseY);
  }

  void _drawTentCluster(
    Canvas canvas,
    Size size, {
    required double baseY,
    required double bigH,
    required double smallH,
  }) {
    final w = size.width;

    // Muted red with stripes, lower opacity than machine
    final tentRed = const Color(0xFF7D1E22).withOpacity(0.62);
    final stripe = const Color(0xFFF5F5F5).withOpacity(0.36);
    final baseShadow = Colors.black.withOpacity(0.10);

    // left small, center big, right small (more “carnival” spacing)
    _drawTent(
      canvas,
      centerX: w * 0.28,
      baseY: baseY,
      width: w * 0.24,
      height: smallH,
      red: tentRed,
      stripe: stripe,
      baseShadow: baseShadow,
    );

    _drawTent(
      canvas,
      centerX: w * 0.52,
      baseY: baseY,
      width: w * 0.36,
      height: bigH,
      red: tentRed,
      stripe: stripe,
      baseShadow: baseShadow,
    );

    _drawTent(
      canvas,
      centerX: w * 0.76,
      baseY: baseY,
      width: w * 0.24,
      height: smallH,
      red: tentRed,
      stripe: stripe,
      baseShadow: baseShadow,
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
    required Color baseShadow,
  }) {
    final half = width / 2;
    final topY = baseY - height;

    // More “tent-like”: rounded/arched top, slight flare at bottom
    final body = Path()
      ..moveTo(centerX - half * 1.00, baseY)
      ..lineTo(centerX - half * 0.70, topY + height * 0.28)
      ..quadraticBezierTo(
        centerX,
        topY,
        centerX + half * 0.70,
        topY + height * 0.28,
      )
      ..lineTo(centerX + half * 1.00, baseY)
      ..close();

    // Fill
    canvas.drawPath(body, Paint()..color = red);

    // Grounding shadow at base
    canvas.drawRect(
      Rect.fromLTWH(centerX - half, baseY - 4, width, 6),
      Paint()..color = baseShadow,
    );

    // Stripes
    final stripeCount = 9;
    final stripePaint = Paint()..color = stripe;

    canvas.save();
    canvas.clipPath(body);
    for (int i = 0; i < stripeCount; i++) {
      final p = i / (stripeCount - 1);
      final x = centerX - half + width * p;
      final stripeW = width * 0.045;
      final r = Rect.fromLTWH(
        x - stripeW / 2,
        topY + height * 0.20,
        stripeW,
        height * 0.82,
      );
      canvas.drawRect(r, stripePaint);
    }
    canvas.restore();

    // Pennant
    final pennant = Path()
      ..moveTo(centerX, topY + height * 0.04)
      ..lineTo(centerX - 7, topY + height * 0.12)
      ..lineTo(centerX + 7, topY + height * 0.12)
      ..close();

    canvas.drawPath(pennant, Paint()..color = stripe.withOpacity(0.55));
  }

  void _drawFerrisWheel(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required double clipBottomY,
  }) {
    // More ferris-like, less “stick legs”
    final rimPaint = Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final spokePaint = Paint()
      ..color = Colors.black.withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final cabinPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    // Clip: show only top portion (distance)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, clipBottomY));

    // Rim + hub
    canvas.drawCircle(center, radius, rimPaint);
    canvas.drawCircle(center, radius * 0.10, cabinPaint);

    // Spokes + cabins
    const spokes = 12;
    for (int i = 0; i < spokes; i++) {
      final a = (i / spokes) * pi * 2;
      final p = Offset(center.dx + cos(a) * radius, center.dy + sin(a) * radius);
      canvas.drawLine(center, p, spokePaint);

      // cabins around rim
      final c = Offset(
        center.dx + cos(a) * radius * 1.02,
        center.dy + sin(a) * radius * 1.02,
      );
      canvas.drawCircle(c, 2.6, cabinPaint);
    }

    // Support frame (thicker, triangle base)
    final baseY = clipBottomY;
    final framePaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final leftBase = Offset(center.dx - radius * 0.60, baseY);
    final rightBase = Offset(center.dx + radius * 0.60, baseY);
    final mid = Offset(center.dx, center.dy + radius * 0.40);

    canvas.drawLine(leftBase, mid, framePaint);
    canvas.drawLine(rightBase, mid, framePaint);
    canvas.drawLine(leftBase, rightBase, framePaint);

    canvas.restore();
  }

  void _drawStringLights(
    Canvas canvas,
    Size size, {
    required double baseY,
    required double tentPeakY,
  }) {
    final w = size.width;

    // Poles sit closer to tents, lights drape lower
    final leftPoleX = w * 0.20;
    final rightPoleX = w * 0.84;

    final poleTopY = tentPeakY - (size.height * 0.01); // just above peaks
    final sagY = tentPeakY + (baseY - tentPeakY) * 0.18; // drape into tent zone

    // Poles
    final polePaint = Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..strokeWidth = 3.0;

    canvas.drawLine(Offset(leftPoleX, baseY), Offset(leftPoleX, poleTopY), polePaint);
    canvas.drawLine(Offset(rightPoleX, baseY), Offset(rightPoleX, poleTopY), polePaint);

    // Wire
    final midX = (leftPoleX + rightPoleX) / 2;
    final wire = Path()
      ..moveTo(leftPoleX, poleTopY)
      ..quadraticBezierTo(midX, sagY, rightPoleX, poleTopY);

    final wirePaint = Paint()
      ..color = Colors.black.withOpacity(0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawPath(wire, wirePaint);

    // Bulbs (warm yellow + glow)
    final glowPaint = Paint()
      ..color = const Color(0xFFFFE08A).withOpacity(0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final bulbPaint = Paint()
      ..color = const Color(0xFFFFD36A).withOpacity(0.95);

    const bulbs = 15;
    for (int i = 0; i < bulbs; i++) {
      final p = i / (bulbs - 1);
      final x = _lerp(leftPoleX, rightPoleX, p);
      final y = _quadBezierY(x, leftPoleX, poleTopY, midX, sagY, rightPoleX, poleTopY);

      final c = Offset(x, y);
      canvas.drawCircle(c, 5.5, glowPaint);
      canvas.drawCircle(c, 2.6, bulbPaint);
    }
  }

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

  void _drawBalloonMachine(Canvas canvas, Size size, {required double baseY}) {
    final w = size.width;
    final h = size.height;

    // Center under spawn point
    final cx = w * 0.50;

    final machineH = h * 0.20;
    final machineW = w * 0.14;

    final topY = baseY - machineH;
    final left = cx - machineW / 2;

    // Shadow separation (prevents “disappearing into tents”)
    final shadow = Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseY + 7),
        width: machineW * 1.35,
        height: 14,
      ),
      shadow,
    );

    // Body (deep classic carnival red)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, topY + machineH * 0.22, machineW, machineH * 0.78),
      const Radius.circular(12),
    );
    final bodyPaint = Paint()..color = const Color(0xFF8A1C1F).withOpacity(0.96);
    canvas.drawRRect(bodyRect, bodyPaint);

    // Body outline (subtle light edge)
    final outline = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(bodyRect, outline);

    // Glass chamber (silver bezel + light glass)
    final chamberRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + machineW * 0.12, topY, machineW * 0.76, machineH * 0.36),
      const Radius.circular(16),
    );

    final glass = Paint()..color = const Color(0xFFBFE8FF).withOpacity(0.20);
    final bezel = Paint()
      ..color = const Color(0xFFB9BFC7).withOpacity(0.86)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRRect(chamberRect, glass);
    canvas.drawRRect(chamberRect, bezel);

    // Inner highlight to suggest depth
    final inner = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left + machineW * 0.16,
          topY + machineH * 0.04,
          machineW * 0.68,
          machineH * 0.28,
        ),
        const Radius.circular(14),
      ),
      inner,
    );

    // Lever/handle (right)
    final leverPaint = Paint()
      ..color = const Color(0xFF2C2C2C).withOpacity(0.70)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final leverBase = Offset(left + machineW * 0.82, topY + machineH * 0.62);
    canvas.drawLine(leverBase, leverBase + const Offset(16, -12), leverPaint);

    canvas.drawCircle(
      leverBase + const Offset(18, -14),
      5.2,
      Paint()..color = const Color(0xFFB9BFC7).withOpacity(0.80),
    );

    // Coin slot
    final slotPaint = Paint()..color = Colors.black.withOpacity(0.22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + machineW * 0.34, topY + machineH * 0.58, machineW * 0.32, 10),
        const Radius.circular(6),
      ),
      slotPaint,
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
