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

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value.clamp(0.0, 1.0);

          final opacity =
              (t < 0.80) ? 1.0 : (1.0 - (t - 0.80) / 0.20).clamp(0.0, 1.0);

          final lift = -14.0 * (1 - pow(1 - (t / 0.30).clamp(0.0, 1.0), 3));
          final drop =
              24.0 * pow(((t - 0.55) / 0.45).clamp(0.0, 1.0), 3).toDouble();

          final y = lift + drop;

          return Positioned.fill(
            child: Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, y),
                child: const SizedBox.expand(
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

    final sky = Paint()..color = const Color(0xFF6EC6FF);
    final grass = Paint()..color = const Color(0xFF2E7D32);

    final hillTopY = h * 0.86;
    final hillSag = h * 0.075;

    // SKY
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sky);

    // GRASS HILL
    final hillPath = Path()
      ..moveTo(-w * 0.15, hillTopY)
      ..quadraticBezierTo(w * 0.5, hillTopY - hillSag, w * 1.15, hillTopY)
      ..lineTo(w * 1.15, h)
      ..lineTo(-w * 0.15, h)
      ..close();

    canvas.drawPath(hillPath, grass);

    // TENTS
    _drawTent(canvas, w * 0.30, hillTopY, w * 0.22, h * 0.14);
    _drawTent(canvas, w * 0.50, hillTopY, w * 0.30, h * 0.18);
    _drawTent(canvas, w * 0.70, hillTopY, w * 0.22, h * 0.14);

    // FERRIS WHEEL (background right)
    _drawFerrisWheel(canvas, size,
        Offset(w * 0.82, hillTopY - h * 0.16), h * 0.12);

    // STRING LIGHTS
    _drawLights(canvas, size, hillTopY - h * 0.18);

    // BALLOON MACHINE (foreground center)
    _drawMachine(canvas, size, hillTopY);
  }

  void _drawTent(Canvas canvas, double cx, double baseY, double width,
      double height) {
    final red = Paint()
      ..color = const Color(0xFF7D1E22).withOpacity(0.80);

    final stripe = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.45);

    final half = width / 2;
    final topY = baseY - height;

    final body = Path()
      ..moveTo(cx - half, baseY)
      ..quadraticBezierTo(cx, topY, cx + half, baseY)
      ..close();

    canvas.drawPath(body, red);

    for (int i = 0; i < 7; i++) {
      final x = cx - half + (width * (i / 6));
      canvas.save();
      canvas.clipPath(body);
      canvas.drawRect(
          Rect.fromLTWH(x - width * 0.04, topY, width * 0.06, height), stripe);
      canvas.restore();
    }
  }

  void _drawFerrisWheel(
      Canvas canvas, Size size, Offset center, double radius) {
    final rim = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final spoke = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, rim);

    for (int i = 0; i < 10; i++) {
      final a = (i / 10) * pi * 2;
      final p =
          Offset(center.dx + cos(a) * radius, center.dy + sin(a) * radius);
      canvas.drawLine(center, p, spoke);
    }
  }

  void _drawLights(Canvas canvas, Size size, double y) {
    final w = size.width;

    final wire = Paint()
      ..color = Colors.black.withOpacity(0.30)
      ..strokeWidth = 2;

    final path = Path()
      ..moveTo(w * 0.2, y)
      ..quadraticBezierTo(w * 0.5, y + 20, w * 0.8, y);

    canvas.drawPath(path, wire);

    final glow = Paint()
      ..color = const Color(0xFFFFE08A).withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final bulb = Paint()..color = const Color(0xFFFFD36A);

    for (int i = 0; i < 12; i++) {
      final t = i / 11;
      final x = w * 0.2 + (w * 0.6 * t);
      final bulbY = y + 20 * sin(pi * t);
      canvas.drawCircle(Offset(x, bulbY), 6, glow);
      canvas.drawCircle(Offset(x, bulbY), 3, bulb);
    }
  }

  void _drawMachine(Canvas canvas, Size size, double baseY) {
    final w = size.width;
    final cx = w * 0.5;

    final body = Paint()
      ..color = const Color(0xFF8A1C1F).withOpacity(0.95);

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(cx, baseY - 50), width: w * 0.12, height: 110),
      const Radius.circular(12),
    );

    canvas.drawRRect(rect, body);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
