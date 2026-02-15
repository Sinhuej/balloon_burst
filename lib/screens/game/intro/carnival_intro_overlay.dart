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
              painter: _SkyGrassPainter(),
            ),
          );
        },
      ),
    );
  }
}

class _SkyGrassPainter extends CustomPainter {
  const _SkyGrassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // SKY
    final sky = Paint()..color = const Color(0xFF6EC6FF);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sky);

    // GRASS HILL (matches your preferred soft arc)
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
