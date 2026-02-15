import 'dart:math';
import 'package:flutter/material.dart';

class CarnivalIntroOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const CarnivalIntroOverlay({
    super.key,
    required this.onComplete,
  });

  @override
  State<CarnivalIntroOverlay> createState() =>
      _CarnivalIntroOverlayState();
}

class _CarnivalIntroOverlayState
    extends State<CarnivalIntroOverlay>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _drop;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _fade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    _drop = Tween<double>(begin: 0.0, end: 80.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Opacity(
            opacity: _fade.value,
            child: Transform.translate(
              offset: Offset(0, _drop.value),
              child: CustomPaint(
                painter: _CarnivalPainter(),
                size: Size.infinite,
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
    final groundPaint = Paint()
      ..color = const Color(0xFF2E7D32);

    final hillPath = Path()
      ..moveTo(0, size.height * 0.85)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.78,
        size.width,
        size.height * 0.85,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(hillPath, groundPaint);

    final silhouette = Paint()
      ..color = const Color(0xFF111111);

    // 🎪 Multiple Tent Peaks
    void drawTent(double x, double width, double height) {
      final path = Path()
        ..moveTo(x, size.height * 0.85)
        ..lineTo(x + width / 2, size.height * (0.85 - height))
        ..lineTo(x + width, size.height * 0.85)
        ..close();
      canvas.drawPath(path, silhouette);
    }

    drawTent(size.width * 0.10, 80, 0.12);
    drawTent(size.width * 0.22, 100, 0.15);
    drawTent(size.width * 0.36, 70, 0.10);

    // 🎡 Ferris Wheel
    final wheelCenter =
        Offset(size.width * 0.78, size.height * 0.72);
    const wheelRadius = 40.0;

    canvas.drawCircle(wheelCenter, wheelRadius, silhouette);

    final hubPaint = Paint()..color = const Color(0xFF222222);
    canvas.drawCircle(wheelCenter, 6, hubPaint);

    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 3.14159 * 2;
      final spokeEnd = Offset(
        wheelCenter.dx + wheelRadius * cos(angle),
        wheelCenter.dy + wheelRadius * sin(angle),
      );
      canvas.drawLine(wheelCenter, spokeEnd, hubPaint);
    }

    // Ferris support legs
    canvas.drawLine(
        wheelCenter.translate(-15, wheelRadius),
        Offset(wheelCenter.dx - 30, size.height * 0.85),
        silhouette);

    canvas.drawLine(
        wheelCenter.translate(15, wheelRadius),
        Offset(wheelCenter.dx + 30, size.height * 0.85),
        silhouette);

    // 🎈 Balloon Machine (left)
    final machineBase = Rect.fromLTWH(
      size.width * 0.05,
      size.height * 0.78,
      40,
      50,
    );

    canvas.drawRect(machineBase, silhouette);

    canvas.drawCircle(
      Offset(size.width * 0.07 + 20, size.height * 0.75),
      20,
      silhouette,
    );

    canvas.drawLine(
      Offset(size.width * 0.09, size.height * 0.72),
      Offset(size.width * 0.13, size.height * 0.65),
      silhouette,
    );

    // 💡 String Lights
    final lightsPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.60)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.55,
        size.width * 0.9,
        size.height * 0.60,
      );

    canvas.drawPath(lightsPath, hubPaint..strokeWidth = 2..style = PaintingStyle.stroke);

    final lightPaint = Paint()
      ..color = const Color(0xFF444444);

    for (int i = 0; i <= 12; i++) {
      final t = i / 12;
      final dx = size.width * 0.1 +
          (size.width * 0.8) * t;
      final dy = size.height * 0.60 -
          sin(t * 3.14159) * 20;
      canvas.drawCircle(Offset(dx, dy), 3, lightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
