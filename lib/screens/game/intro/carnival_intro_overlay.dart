import 'dart:math' as math;
import 'package:flutter/material.dart';

/// CarnivalIntroOverlay
/// - Visual-only intro layer (tap-safe): IgnorePointer always.
/// - Designed to sit ABOVE world-1 sky background, BELOW gameplay (balloons).
/// - 3s-ish fade with slight downward drift (carnival "falls away" as we ascend).
///
/// Constructor is intentionally tolerant:
/// - supports either onComplete or onFinished callback names (optional).
class CarnivalIntroOverlay extends StatefulWidget {
  final VoidCallback? onComplete;
  final VoidCallback? onFinished;

  /// If false, widget paints nothing.
  final bool enabled;

  const CarnivalIntroOverlay({
    super.key,
    this.onComplete,
    this.onFinished,
    this.enabled = true,
  }) : assert(!(onComplete != null && onFinished != null),
            'Provide only one of onComplete or onFinished.');

  @override
  State<CarnivalIntroOverlay> createState() => _CarnivalIntroOverlayState();
}

class _CarnivalIntroOverlayState extends State<CarnivalIntroOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _duration = Duration(milliseconds: 3000);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _duration)
      ..forward();

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        (widget.onComplete ?? widget.onFinished)?.call();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    return IgnorePointer(
      ignoring: true,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          // t: 0..1
          final t = _ctrl.value.clamp(0.0, 1.0);

          // Ease for fade
          final fade = _easeOutCubic(1.0 - t); // starts 1, ends 0

          // Carnival drifts DOWN slightly as it fades (leaving the ground behind)
          final driftY = _lerpDouble(0.0, 26.0, _easeInCubic(t));

          return Opacity(
            opacity: fade,
            child: Transform.translate(
              offset: Offset(0, driftY),
              child: CustomPaint(
                painter: _CarnivalPainter(t: t),
                size: Size.infinite,
              ),
            ),
          );
        },
      ),
    );
  }

  double _easeOutCubic(double x) {
    final p = (1.0 - x);
    return 1.0 - p * p * p;
  }

  double _easeInCubic(double x) => x * x * x;

  double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

class _CarnivalPainter extends CustomPainter {
  final double t; // 0..1 (not currently used heavily; reserved for subtle motion)

  _CarnivalPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // --- Palette (locked by your approvals) ---
    // Silhouette (softened): not pure black.
    final silhouette = const Color(0xFF0B0B0E).withOpacity(0.78);

    // Muted tent red (background accent; lower priority than machine).
    final tentRed = const Color(0xFF8B2E2E).withOpacity(0.80);

    // Soft stripe white (low contrast; vintage).
    final stripeWhite = const Color(0xFFECECEC).withOpacity(0.55);

    // Warm string lights
    final bulbCore = const Color(0xFFFFD36A).withOpacity(0.95);
    final bulbGlow = const Color(0xFFFFE3A8).withOpacity(0.28);

    // Machine red (distinct, deeper, more “object” than silhouette).
    final machineRed = const Color(0xFF9C1B1B); // deep classic carnival red
    final machineShadow = const Color(0xFF6E1111);
    final machineHighlight = const Color(0xFFC74A4A);

    // Machine trim / metal
    final metal = const Color(0xFFB9BDC7).withOpacity(0.75);

    // --- Layout anchors ---
    final w = size.width;
    final h = size.height;

    // Soft hill arc (green is already behind in world; but we add a subtle foreground hill mask)
    final hillTopY = h * 0.80;
    final hill = Path()
      ..moveTo(0, h)
      ..quadraticBezierTo(w * 0.50, hillTopY, w, h)
      ..close();

    // Draw a slightly darker green “foreground hill” so silhouettes read.
    final hillPaint = Paint()
      ..color = const Color(0xFF2C6B2E).withOpacity(0.92)
      ..style = PaintingStyle.fill;
    canvas.drawPath(hill, hillPaint);

    // Baseline where carnival sits
    final groundY = h * 0.86;

    // --- String lights (lowered; warm bulbs; slight arc) ---
    _drawStringLights(
      canvas,
      size,
      y: h * 0.66,
      colorLine: silhouette.withOpacity(0.55),
      bulbCore: bulbCore,
      bulbGlow: bulbGlow,
    );

    // --- Tents (multiple classic tops, with muted red + stripes) ---
    _drawTents(
      canvas,
      size,
      baseY: groundY,
      tentRed: tentRed,
      stripeWhite: stripeWhite,
      silhouette: silhouette,
    );

    // --- Ferris wheel (proper read: rim + spokes + gondolas + sturdy legs) ---
    _drawFerrisWheel(
      canvas,
      size,
      center: Offset(w * 0.82, h * 0.78),
      wheelRadius: w * 0.085,
      color: silhouette,
    );

    // --- Balloon machine (centered to match spawn center; distinct red object) ---
    _drawBalloonMachine(
      canvas,
      size,
      center: Offset(w * 0.50, h * 0.84),
      machineRed: machineRed,
      shadow: machineShadow,
      highlight: machineHighlight,
      metal: metal,
    );

    // Optional: faint “balloon silhouettes” rising from machine (very subtle so it
    // doesn’t compete with real balloons that spawn).
    _drawFaintBalloonPuffs(canvas, size, origin: Offset(w * 0.50, h * 0.72));
  }

  void _drawStringLights(
    Canvas canvas,
    Size size, {
    required double y,
    required Color colorLine,
    required Color bulbCore,
    required Color bulbGlow,
  }) {
    final w = size.width;

    final start = Offset(w * 0.18, y);
    final end = Offset(w * 0.92, y);

    final arc = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(w * 0.55, y - size.height * 0.04, end.dx, end.dy);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = colorLine;

    canvas.drawPath(arc, linePaint);

    // Place bulbs along arc
    final bulbs = 13;
    for (int i = 0; i < bulbs; i++) {
      final p = i / (bulbs - 1);
      final pt = _quadBezierPoint(start, Offset(w * 0.55, y - size.height * 0.04), end, p);

      // glow
      final glowPaint = Paint()..color = bulbGlow;
      canvas.drawCircle(pt, 6.0, glowPaint);

      // core
      final corePaint = Paint()..color = bulbCore;
      canvas.drawCircle(pt, 2.3, corePaint);
    }
  }

  Offset _quadBezierPoint(Offset a, Offset b, Offset c, double t) {
    final ab = Offset.lerp(a, b, t)!;
    final bc = Offset.lerp(b, c, t)!;
    return Offset.lerp(ab, bc, t)!;
  }

  void _drawTents(
    Canvas canvas,
    Size size, {
    required double baseY,
    required Color tentRed,
    required Color stripeWhite,
    required Color silhouette,
  }) {
    final w = size.width;

    // A row of tent “modules” (classic peaks, not mountains)
    final modules = <Rect>[
      Rect.fromLTWH(w * 0.18, baseY - size.height * 0.14, w * 0.16, size.height * 0.14),
      Rect.fromLTWH(w * 0.32, baseY - size.height * 0.18, w * 0.22, size.height * 0.18),
      Rect.fromLTWH(w * 0.50, baseY - size.height * 0.16, w * 0.20, size.height * 0.16),
    ];

    for (final r in modules) {
      final tentPath = Path()
        ..moveTo(r.left, baseY)
        ..quadraticBezierTo(r.left + r.width * 0.18, r.top + r.height * 0.55, r.left + r.width * 0.33, r.top + r.height * 0.35)
        ..quadraticBezierTo(r.left + r.width * 0.50, r.top, r.left + r.width * 0.67, r.top + r.height * 0.35)
        ..quadraticBezierTo(r.left + r.width * 0.82, r.top + r.height * 0.55, r.right, baseY)
        ..lineTo(r.right, baseY)
        ..lineTo(r.left, baseY)
        ..close();

      // Base muted red fill
      final redPaint = Paint()..color = tentRed;
      canvas.drawPath(tentPath, redPaint);

      // Stripes clipped inside tent shape
      canvas.save();
      canvas.clipPath(tentPath);

      final stripePaint = Paint()..color = stripeWhite;
      final stripeW = r.width / 7.0;

      for (int i = -2; i < 12; i++) {
        final x0 = r.left + i * stripeW;
        final stripe = Path()
          ..moveTo(x0, r.top - 30)
          ..lineTo(x0 + stripeW * 0.55, r.top - 30)
          ..lineTo(x0 + stripeW * 1.15, baseY + 30)
          ..lineTo(x0 + stripeW * 0.60, baseY + 30)
          ..close();
        canvas.drawPath(stripe, stripePaint);
      }

      canvas.restore();

      // Subtle outline so tents read as silhouette layer
      final outline = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = silhouette.withOpacity(0.35);
      canvas.drawPath(tentPath, outline);
    }
  }

  void _drawFerrisWheel(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double wheelRadius,
    required Color color,
  }) {
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.72);

    final spokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.45);

    final gondolaPaint = Paint()..color = color.withOpacity(0.70);

    // Rim
    canvas.drawCircle(center, wheelRadius, rimPaint);

    // Spokes
    const spokes = 10;
    for (int i = 0; i < spokes; i++) {
      final a = (i / spokes) * math.pi * 2;
      final p = Offset(
        center.dx + wheelRadius * math.cos(a),
        center.dy + wheelRadius * math.sin(a),
      );
      canvas.drawLine(center, p, spokePaint);

      // Gondola
      final g = Offset(
        center.dx + (wheelRadius + 6) * math.cos(a),
        center.dy + (wheelRadius + 6) * math.sin(a),
      );
      canvas.drawCircle(g, 2.6, gondolaPaint);
    }

    // Hub
    canvas.drawCircle(center, 3.2, Paint()..color = color.withOpacity(0.70));

    // Legs (sturdier)
    final legPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.65);

    final baseY = size.height * 0.88;
    canvas.drawLine(center + const Offset(-10, wheelRadius * 0.75), Offset(center.dx - wheelRadius * 0.55, baseY), legPaint);
    canvas.drawLine(center + const Offset(10, wheelRadius * 0.75), Offset(center.dx + wheelRadius * 0.55, baseY), legPaint);

    // Small base bar
    canvas.drawLine(Offset(center.dx - wheelRadius * 0.62, baseY), Offset(center.dx + wheelRadius * 0.62, baseY), legPaint);
  }

  void _drawBalloonMachine(
    Canvas canvas,
    Size size, {
    required Offset center,
    required Color machineRed,
    required Color shadow,
    required Color highlight,
    required Color metal,
  }) {
    // Machine sits on ground; keep it readable and distinct from silhouette tents.
    final w = size.width;

    final bodyW = w * 0.12;
    final bodyH = size.height * 0.10;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - bodyH * 0.35),
        width: bodyW,
        height: bodyH,
      ),
      const Radius.circular(12),
    );

    // Shadow base
    final shadowPaint = Paint()..color = shadow.withOpacity(0.95);
    canvas.drawRRect(bodyRect, shadowPaint);

    // Main body (with subtle gradient-like highlight strip)
    final bodyPaint = Paint()..color = machineRed.withOpacity(0.98);
    canvas.drawRRect(bodyRect, bodyPaint);

    // Highlight strip
    final hiRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        bodyRect.left + bodyW * 0.10,
        bodyRect.top + bodyH * 0.12,
        bodyW * 0.18,
        bodyH * 0.76,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(hiRect, Paint()..color = highlight.withOpacity(0.35));

    // Glass chamber (top)
    final chamberW = bodyW * 0.86;
    final chamberH = bodyH * 0.75;
    final chamber = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, bodyRect.top - chamberH * 0.25),
        width: chamberW,
        height: chamberH,
      ),
      const Radius.circular(14),
    );

    final glassPaint = Paint()
      ..color = const Color(0xFFBBD7FF).withOpacity(0.22)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(chamber, glassPaint);

    // Chamber outline / metal frame
    final framePaint = Paint()
      ..color = metal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(chamber, framePaint);

    // Dispenser chute
    final chute = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, bodyRect.bottom - bodyH * 0.05),
        width: bodyW * 0.54,
        height: bodyH * 0.22,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(chute, Paint()..color = shadow.withOpacity(0.80));
    canvas.drawRRect(chute, Paint()
      ..color = metal.withOpacity(0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6);

    // Crank/lever (right side)
    final leverPaint = Paint()
      ..color = metal.withOpacity(0.85)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final leverBase = Offset(bodyRect.right - 6, bodyRect.top + bodyH * 0.62);
    final leverTip = leverBase + Offset(bodyW * 0.22, -bodyH * 0.22);
    canvas.drawLine(leverBase, leverTip, leverPaint);
    canvas.drawCircle(leverTip, 4.0, Paint()..color = metal.withOpacity(0.90));

    // Tiny “label plate”
    final plate = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, bodyRect.top + bodyH * 0.58),
        width: bodyW * 0.44,
        height: bodyH * 0.20,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(plate, Paint()..color = const Color(0xFFF3E7B3).withOpacity(0.35));
  }

  void _drawFaintBalloonPuffs(Canvas canvas, Size size, {required Offset origin}) {
    // Very subtle so it doesn't compete with real balloons.
    final p = Paint()..color = const Color(0xFF0B0B0E).withOpacity(0.08);

    final count = 6;
    for (int i = 0; i < count; i++) {
      final dx = (i - (count - 1) / 2) * 18.0;
      final dy = -i * 14.0;
      canvas.drawCircle(origin + Offset(dx, dy), 10.0, p);
    }
  }

  @override
  bool shouldRepaint(covariant _CarnivalPainter oldDelegate) => oldDelegate.t != t;
}
