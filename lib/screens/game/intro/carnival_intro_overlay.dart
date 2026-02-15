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
      duration: const Duration(milliseconds: 2000),
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

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return const SizedBox.expand(
            child: CustomPaint(
              painter: _IntroPainter(),
            ),
          );
        },
      ),
    );
  }
}

class _IntroPainter extends CustomPainter {
  const _IntroPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ---------- SKY ----------
    final sky = Paint()..color = const Color(0xFF6EC6FF);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sky);

    // ---------- GRASS ----------
    final grass = Paint()..color = const Color(0xFF2E7D32);

    final hillTopY = h * 0.86;
    final hillSag = h * 0.075;

    final hillPath = Path()
      ..moveTo(-w * 0.15, hillTopY)
      ..quadraticBezierTo(w * 0.5, hillTopY - hillSag, w * 1.15, hillTopY)
      ..lineTo(w * 1.15, h)
      ..lineTo(-w * 0.15, h)
      ..close();

    canvas.drawPath(hillPath, grass);

    final baseY = hillTopY + 2;

    // ---------- BACK TENTS ----------
    final backPaint = Paint()..color = const Color(0xFF7A1518);
    final smallHeight = h * 0.12;
    final smallWidth = w * 0.30;

    final leftCx = w * 0.24;
    final rightCx = w * 0.76;

    _drawTent(canvas, leftCx, baseY, smallWidth, smallHeight, backPaint);
    _drawTent(canvas, rightCx, baseY, smallWidth, smallHeight, backPaint);

    // ---------- FRONT BIG TENT ----------
    final frontPaint = Paint()..color = const Color(0xFF8A1C1F);
    final bigHeight = h * 0.16;
    final bigWidth = w * 0.44;
    final bigCx = w * 0.50;

    _drawTent(canvas, bigCx, baseY, bigWidth, bigHeight, frontPaint);

    // ---------- STRING LIGHTS (LOWER + SHORTER POLES) ----------
    final polePaint = Paint()
      ..color = const Color(0xFF2F4F4F)
      ..strokeWidth = 4;

    final poleLeftX = w * 0.12;
    final poleRightX = w * 0.88;

    // Shorter poles
    final poleTopY = hillTopY - h * 0.12;

    canvas.drawLine(
        Offset(poleLeftX, baseY),
        Offset(poleLeftX, poleTopY),
        polePaint);

    canvas.drawLine(
        Offset(poleRightX, baseY),
        Offset(poleRightX, poleTopY),
        polePaint);

    // Lower droop — nearly touching tents
    final midX = w * 0.5;
    final sagY = hillTopY - h * 0.02;

    final wirePath = Path()
      ..moveTo(poleLeftX, poleTopY)
      ..quadraticBezierTo(midX, sagY, poleRightX, poleTopY);

    final wirePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(wirePath, wirePaint);

    // ---------- BULBS + GLOW ----------
    final glowPaint = Paint()
      ..color = const Color(0xFFFFE08A).withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final bulbPaint = Paint()
      ..color = const Color(0xFFFFD36A);

    const bulbCount = 13;

    for (int i = 0; i < bulbCount; i++) {
      final t = i / (bulbCount - 1);

      final x = _lerp(poleLeftX, poleRightX, t);
      final y = _quadBezierY(t,
          poleLeftX, poleTopY,
          midX, sagY,
          poleRightX, poleTopY);

      final pos = Offset(x, y);

      canvas.drawCircle(pos, 8, glowPaint);
      canvas.drawCircle(pos, 4, bulbPaint);
    }
  }

  void _drawTent(
    Canvas canvas,
    double cx,
    double baseY,
    double width,
    double height,
    Paint paint,
  ) {
    final half = width * 0.5;
    final topY = baseY - height;

    final body = Path()
      ..moveTo(cx - half, baseY)
      ..lineTo(cx - half * 0.78, topY + height * 0.28)
      ..quadraticBezierTo(cx, topY, cx + half * 0.78, topY + height * 0.28)
      ..lineTo(cx + half, baseY)
      ..close();

    canvas.drawPath(body, paint);

    // ---------- STRIPES ----------
    final stripePaint = Paint()..color = Colors.white;
    const stripeCount = 7;

    for (int i = 0; i < stripeCount; i++) {
      final t = i / (stripeCount - 1);
      final x = (cx - half) + (width * t);
      final stripeWidth = width * 0.06;

      final stripeRect = Rect.fromLTWH(
        x - stripeWidth * 0.5,
        topY + height * 0.22,
        stripeWidth,
        height * 0.78,
      );

      canvas.save();
      canvas.clipPath(body);
      canvas.drawRect(stripeRect, stripePaint);
      canvas.restore();
    }

    // ---------- FLAG (TOUCHING PEAK) ----------
    final flagPaint = Paint()..color = Colors.white;

    final flag = Path()
      ..moveTo(cx, topY)
      ..lineTo(cx - 6, topY + 12)
      ..lineTo(cx + 6, topY + 12)
      ..close();

    canvas.drawPath(flag, flagPaint);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double _quadBezierY(
    double t,
    double x0,
    double y0,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    final a = pow(1 - t, 2).toDouble();
    final b = 2 * (1 - t) * t;
    final c = t * t;
    return a * y0 + b * y1 + c * y2;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
