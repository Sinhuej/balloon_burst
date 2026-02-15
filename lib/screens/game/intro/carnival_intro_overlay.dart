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
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_fired) {
          _fired = true;
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

          // IMPORTANT: NO Positioned.* here (prevents gray screen / layout issues)
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

    // Full paint: sky + grass + carnival
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

    final baseY = hillTopY + 2.0;

    // Tent layout (center tent in FRONT)
    final bigH = h * 0.16;
    final smallH = h * 0.12;

    final bigW = w * 0.44;
    final smallW = w * 0.30;

    final leftCx = w * 0.24;
    final bigCx = w * 0.50;
    final rightCx = w * 0.76;

    final tentRed = const Color(0xFF7D1E22).withOpacity(0.75);
    final stripeWhite = const Color(0xFFFFFFFF).withOpacity(0.85);

    // Back tents first
    _drawTent(canvas, leftCx, baseY, smallW, smallH, tentRed, stripeWhite);
    _drawTent(canvas, rightCx, baseY, smallW, smallH, tentRed, stripeWhite);

    // Front center tent
    _drawTent(canvas, bigCx, baseY, bigW, bigH, tentRed, stripeWhite);

    // Drooping lights (bulbs ON the wire)
    _drawLights(
      canvas,
      size,
      baseY: baseY,
      leftX: w * 0.10,
      rightX: w * 0.90,
      tentTopY: baseY - bigH,
    );
  }

  void _drawTent(Canvas canvas, double cx, double baseY, double width,
      double height, Color red, Color stripe) {
    final half = width * 0.5;
    final topY = baseY - height;

    final body = Path()
      ..moveTo(cx - half, baseY)
      ..lineTo(cx - half * 0.82, topY + height * 0.30)
      ..quadraticBezierTo(cx, topY, cx + half * 0.82, topY + height * 0.30)
      ..lineTo(cx + half, baseY)
      ..close();

    canvas.drawPath(body, Paint()..color = red);

    // Stripes (brighter white)
    final stripePaint = Paint()..color = stripe;

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
      canvas.drawRect(stripeRect, stripePaint);
      canvas.restore();
    }

    // Flag topper (helps read as “tent”)
    final flag = Path()
      ..moveTo(cx, topY)
      ..lineTo(cx - 7, topY + 10)
      ..lineTo(cx + 7, topY + 10)
      ..close();

    canvas.drawPath(
      flag,
      Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.90),
    );
  }

  void _drawLights(
    Canvas canvas,
    Size size, {
    required double baseY,
    required double leftX,
    required double rightX,
    required double tentTopY,
  }) {
    final h = size.height;
    final poleTopY = tentTopY - h * 0.04;

    final polePaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(leftX, baseY), Offset(leftX, poleTopY), polePaint);
    canvas.drawLine(
        Offset(rightX, baseY), Offset(rightX, poleTopY), polePaint);

    final midX = (leftX + rightX) * 0.5;
    final sagY = poleTopY + h * 0.09;

    final wire = Path()
      ..moveTo(leftX, poleTopY)
      ..quadraticBezierTo(midX, sagY, rightX, poleTopY);

    final wirePaint = Paint()
      ..color = Colors.black.withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawPath(wire, wirePaint);

    // Glow improved (like your earlier “better glow”)
    final glow = Paint()
      ..color = const Color(0xFFFFE08A).withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final bulb = Paint()..color = const Color(0xFFFFD36A);

    const bulbs = 14;
    for (int i = 0; i < bulbs; i++) {
      final t = i / (bulbs - 1);

      // Quadratic Bezier point (bulbs sit ON the drooping wire)
      final x = (1 - t) * (1 - t) * leftX +
          2 * (1 - t) * t * midX +
          t * t * rightX;

      final y = (1 - t) * (1 - t) * poleTopY +
          2 * (1 - t) * t * sagY +
          t * t * poleTopY;

      final p = Offset(x, y);
      canvas.drawCircle(p, 6, glow);
      canvas.drawCircle(p, 3, bulb);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
