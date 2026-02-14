import 'dart:math';
import 'package:flutter/material.dart';

class CarnivalIntroOverlay extends StatefulWidget {
  final VoidCallback onFinished;

  const CarnivalIntroOverlay({
    super.key,
    required this.onFinished,
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
    )..forward();

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinished();
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
    final fade = 1.0 - _ctrl.value;
    final dropOffset = _ctrl.value * 40.0;

    return IgnorePointer(
      ignoring: true,
      child: Opacity(
        opacity: fade,
        child: Transform.translate(
          offset: Offset(0, dropOffset),
          child: CustomPaint(
            painter: _CarnivalPainter(),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _CarnivalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final groundHeight = size.height * 0.18;

    // ---- Green Curved Hill ----
    final hillPath = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height - groundHeight * 1.4,
        size.width,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final hillPaint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawPath(hillPath, hillPaint);

    final silhouettePaint = Paint()..color = Colors.black;

    final baseY = size.height - groundHeight;

    // ---- Tent Peaks ----
    _drawTent(canvas, size.width * 0.25, baseY, silhouettePaint);
    _drawTent(canvas, size.width * 0.38, baseY, silhouettePaint);

    // ---- Ferris Wheel ----
    final wheelRadius = size.width * 0.08;
    final wheelCenter = Offset(size.width * 0.65, baseY - wheelRadius);
    canvas.drawCircle(wheelCenter, wheelRadius, silhouettePaint);

    // ---- Balloon Machine (slightly left) ----
    final machineRect = Rect.fromCenter(
      center: Offset(size.width * 0.18, baseY - 25),
      width: 40,
      height: 50,
    );
    canvas.drawRect(machineRect, silhouettePaint);

    // ---- Static Balloon Silhouettes ----
    _drawBalloon(canvas, Offset(size.width * 0.16, baseY - 80), silhouettePaint);
    _drawBalloon(canvas, Offset(size.width * 0.20, baseY - 110), silhouettePaint);
    _drawBalloon(canvas, Offset(size.width * 0.23, baseY - 95), silhouettePaint);
  }

  void _drawTent(Canvas canvas, double x, double baseY, Paint paint) {
    final path = Path()
      ..moveTo(x - 30, baseY)
      ..lineTo(x, baseY - 60)
      ..lineTo(x + 30, baseY)
      ..close();

    canvas.drawPath(path, paint);
  }

  void _drawBalloon(Canvas canvas, Offset center, Paint paint) {
    canvas.drawCircle(center, 12, paint);

    final stringPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5;

    canvas.drawLine(
      center + const Offset(0, 12),
      center + const Offset(0, 28),
      stringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
