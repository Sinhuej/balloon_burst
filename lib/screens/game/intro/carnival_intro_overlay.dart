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
              painter: _SkyGrassTentPainter(),
            ),
          );
        },
      ),
    );
  }
}

class _SkyGrassTentPainter extends CustomPainter {
  const _SkyGrassTentPainter();

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
      ..quadraticBezierTo(
        w * 0.5,
        hillTopY - hillSag,
        w * 1.15,
        hillTopY,
      )
      ..lineTo(w * 1.15, h)
      ..lineTo(-w * 0.15, h)
      ..close();

    canvas.drawPath(hillPath, grass);

    final baseY = hillTopY + 2;

    // ---------- BACK TENTS ----------
    final backPaint = Paint()
      ..color = const Color(0xFF7A1518);

    final smallHeight = h * 0.12;
    final smallWidth = w * 0.30;

    final leftCx = w * 0.24;
    final rightCx = w * 0.76;

    _drawTent(canvas, leftCx, baseY, smallWidth, smallHeight, backPaint);
    _drawTent(canvas, rightCx, baseY, smallWidth, smallHeight, backPaint);

    // ---------- FRONT BIG TENT ----------
    final frontPaint = Paint()
      ..color = const Color(0xFF8A1C1F);

    final bigHeight = h * 0.16;
    final bigWidth = w * 0.44;
    final bigCx = w * 0.50;

    _drawTent(canvas, bigCx, baseY, bigWidth, bigHeight, frontPaint);
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

    final path = Path()
      ..moveTo(cx - half, baseY)
      ..lineTo(cx - half * 0.78, topY + height * 0.28)
      ..quadraticBezierTo(cx, topY, cx + half * 0.78, topY + height * 0.28)
      ..lineTo(cx + half, baseY)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
