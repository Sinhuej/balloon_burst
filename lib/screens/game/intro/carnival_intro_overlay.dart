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

    // SKY
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF6EC6FF),
    );

    // GRASS
    final hillTopY = h * 0.86;
    final hillSag = h * 0.075;

    final hillPath = Path()
      ..moveTo(-w * 0.15, hillTopY)
      ..quadraticBezierTo(w * 0.5, hillTopY - hillSag, w * 1.15, hillTopY)
      ..lineTo(w * 1.15, h)
      ..lineTo(-w * 0.15, h)
      ..close();

    canvas.drawPath(hillPath, Paint()..color = const Color(0xFF2E7D32));

    final baseY = hillTopY + 2;

    // TENT SIZES
    final smallHeight = h * 0.12;
    final bigHeight = h * 0.16;

    final smallWidth = w * 0.30;
    final bigWidth = w * 0.44;

    final leftCx = w * 0.24;
    final rightCx = w * 0.76;
    final centerCx = w * 0.50;

    // BACK TENTS
    _drawTent(canvas, leftCx, baseY, smallWidth, smallHeight);
    _drawTent(canvas, rightCx, baseY, smallWidth, smallHeight);

    // FRONT TENT
    _drawTent(canvas, centerCx, baseY, bigWidth, bigHeight);

    // -------- STRING LIGHTS FIXED --------

    final tentPeakY = baseY - bigHeight;

    final poleLeftX = w * 0.12;
    final poleRightX = w * 0.88;

    // Taller poles
    final poleTopY = tentPeakY - h * 0.08;

    final polePaint = Paint()
      ..color = const Color(0xFF2F4F4F)
      ..strokeWidth = 4;

    canvas.drawLine(Offset(poleLeftX, baseY),
        Offset(poleLeftX, poleTopY), polePaint);

    canvas.drawLine(Offset(poleRightX, baseY),
        Offset(poleRightX, poleTopY), polePaint);

    // Droop lowest point JUST above peak
    final sagY = tentPeakY - h * 0.01;

    final midX = w * 0.5;

    final wirePath = Path()
      ..moveTo(poleLeftX, poleTopY)
      ..quadraticBezierTo(midX, sagY, poleRightX, poleTopY);

    canvas.drawPath(
      wirePath,
      Paint()
        ..color = Colors.black
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Glow bulbs
    final glowPaint = Paint()
      ..color = const Color(0xFFFFE08A).withOpacity(0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final bulbPaint = Paint()
      ..color = const Color(0xFFFFD36A);

    const bulbCount = 13;

    for (int i = 0; i < bulbCount; i++) {
      final t = i / (bulbCount - 1);
      final x = poleLeftX + (poleRightX - poleLeftX) * t;
      final y = _quadBezierY(t,
          poleLeftX, poleTopY,
          midX, sagY,
          poleRightX, poleTopY);

      final pos = Offset(x, y);

      canvas.drawCircle(pos, 9, glowPaint);
      canvas.drawCircle(pos, 4, bulbPaint);
    }
  }

  void _drawTent(
      Canvas canvas,
      double cx,
      double baseY,
      double width,
      double height) {

    final half = width * 0.5;
    final topY = baseY - height;

    final body = Path()
      ..moveTo(cx - half, baseY)
      ..lineTo(cx - half * 0.78, topY + height * 0.28)
      ..quadraticBezierTo(cx, topY, cx + half * 0.78, topY + height * 0.28)
      ..lineTo(cx + half, baseY)
      ..close();

    canvas.drawPath(body, Paint()..color = const Color(0xFF8A1C1F));

    // White stripes
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

    // FLAG — anchored directly to peak
    final flag = Path()
      ..moveTo(cx, topY)
      ..lineTo(cx - 7, topY + 14)
      ..lineTo(cx + 7, topY + 14)
      ..close();

    canvas.drawPath(flag, Paint()..color = Colors.white);
  }

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
