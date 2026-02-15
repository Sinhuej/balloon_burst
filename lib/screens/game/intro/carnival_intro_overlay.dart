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

          final opacity =
              (t < 0.80) ? 1.0 : (1.0 - (t - 0.80) / 0.20).clamp(0.0, 1.0);

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

    final sky = Paint()..color = const Color(0xFF6EC6FF);
    final grass = Paint()..color = const Color(0xFF2E7D32);

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sky);

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

    // Tent sizes
    final bigH = h * 0.15;
    final smallH = h * 0.115;

    final bigW = w * 0.48;
    final smallW = w * 0.32;

    final bigCx = w * 0.5;
    final leftCx = w * 0.27;
    final rightCx = w * 0.73;

    final tentRedFront = const Color(0xFF7D1E22).withOpacity(0.80);
    final tentRedBack = const Color(0xFF7D1E22).withOpacity(0.60);
    final stripe = const Color(0xFFF5F5F5).withOpacity(0.40);

    // Draw back tents FIRST
    _drawTent(canvas, leftCx, baseY + 6, smallW, smallH,
        tentRedBack, stripe);
    _drawTent(canvas, rightCx, baseY + 6, smallW, smallH,
        tentRedBack, stripe);

    // Draw big tent LAST (in front)
    _drawTent(canvas, bigCx, baseY, bigW, bigH,
        tentRedFront, stripe);

    // Lights wider than tents
    _drawLights(canvas, size,
        baseY: baseY,
        leftX: w * 0.10,
        rightX: w * 0.90,
        tentTopY: baseY - bigH);
  }

  void _drawTent(Canvas canvas, double cx, double baseY,
      double width, double height,
      Color red, Color stripe) {
    final half = width * 0.5;
    final topY = baseY - height;

    final body = Path()
      ..moveTo(cx - half, baseY)
      ..lineTo(cx - half * 0.82, topY + height * 0.30)
      ..quadraticBezierTo(cx, topY, cx + half * 0.82, topY + height * 0.30)
      ..lineTo(cx + half, baseY)
      ..close();

    canvas.drawPath(body, Paint()..color = red);

    const count = 9;
    for (int i = 0; i < count; i++) {
      final t = i / (count - 1);
      final x = (cx - half) + (width * t);
      final stripeW = width * 0.05;

      final stripeRect = Rect.fromLTWH(
        x - stripeW * 0.5,
        topY + height * 0.25,
        stripeW,
        height * 0.75,
      );

      canvas.save();
      canvas.clipPath(body);
      canvas.drawRect(stripeRect, Paint()..color = stripe);
      canvas.restore();
    }
  }

  void _drawLights(Canvas canvas, Size size,
      {required double baseY,
      required double leftX,
      required double rightX,
      required double tentTopY}) {
    final h = size.height;

    final poleTopY = tentTopY - h * 0.04;

    final polePaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..strokeWidth = 3;

    canvas.drawLine(Offset(leftX, baseY),
        Offset(leftX, poleTopY), polePaint);
    canvas.drawLine(Offset(rightX, baseY),
        Offset(rightX, poleTopY), polePaint);

    final midX = (leftX + rightX) * 0.5;
    final sagY = poleTopY + h * 0.08;

    final wire = Path()
      ..moveTo(leftX, poleTopY)
      ..quadraticBezierTo(midX, sagY, rightX, poleTopY);

    canvas.drawPath(
        wire,
        Paint()
          ..color = Colors.black.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2);

    final glow = Paint()
      ..color = const Color(0xFFFFE08A).withOpacity(0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final bulb = Paint()
      ..color = const Color(0xFFFFD36A);

    const bulbs = 14;
    for (int i = 0; i < bulbs; i++) {
      final t = i / (bulbs - 1);
      final x = leftX + (rightX - leftX) * t;
      final y = sagY - 4 * sin(pi * t);

      canvas.drawCircle(Offset(x, y), 6, glow);
      canvas.drawCircle(Offset(x, y), 3, bulb);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
