import 'dart:math';
import 'package:flutter/material.dart';

/// CarnivalIntroOverlay (Tap-safe)
/// - Paints full sky + grass + carnival elements (overlay is self-contained)
/// - 3-second intro
/// - Slight upward lift + fade, then slight downward drift as it fades
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

  double _easeOutCubic(double x) => 1.0 - pow(1.0 - x, 3).toDouble();
  double _easeInCubic(double x) => x * x * x;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final double t = _ctrl.value.clamp(0.0, 1.0);

          // Opacity: hold, then fade last ~0.60s
          final double opacity =
              (t < 0.80) ? 1.0 : (1.0 - (t - 0.80) / 0.20).clamp(0.0, 1.0);

          // Motion: slight lift early, then drift downward as it fades
          final double lift =
              -14.0 * _easeOutCubic((t / 0.30).clamp(0.0, 1.0));
          final double drop =
              24.0 * _easeInCubic(((t - 0.55) / 0.45).clamp(0.0, 1.0));
          final double y = lift + drop;

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
    final double w = size.width;
    final double h = size.height;

    // Full-screen sky + grass
    final Paint sky = Paint()..color = const Color(0xFF6EC6FF);
    final Paint grass = Paint()..color = const Color(0xFF2E7D32);

    final double hillTopY = h * 0.86;
    final double hillSag = h * 0.075;

    // SKY
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sky);

    // GRASS HILL (soft arc)
    final Path hillPath = Path()
      ..moveTo(-w * 0.15, hillTopY)
      ..quadraticBezierTo(w * 0.5, hillTopY - hillSag, w * 1.15, hillTopY)
      ..lineTo(w * 1.15, h)
      ..lineTo(-w * 0.15, h)
      ..close();

    canvas.drawPath(hillPath, grass);

    // TENTS (3 cluster)
    _drawTent(canvas, w * 0.30, hillTopY, w * 0.22, h * 0.14);
    _drawTent(canvas, w * 0.50, hillTopY, w * 0.30, h * 0.18);
    _drawTent(canvas, w * 0.70, hillTopY, w * 0.22, h * 0.14);

    // FERRIS WHEEL (background right)
    _drawFerrisWheel(
      canvas,
      Offset(w * 0.82, hillTopY - h * 0.16),
      h * 0.12,
    );

    // STRING LIGHTS (lower than before; just above tent peaks)
    _drawLights(canvas, size, hillTopY - h * 0.20);

    // BALLOON MACHINE (foreground center)
    _drawMachine(canvas, size, hillTopY);
  }

  void _drawTent(Canvas canvas, double cx, double baseY, double width, double height) {
    final Paint red = Paint()
      ..color = const Color(0xFF7D1E22).withOpacity(0.80);

    final Paint stripe = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.45);

    final double half = width / 2.0;
    final double topY = baseY - height;

    // More “tent-like” curve than a sharp triangle
    final Path body = Path()
      ..moveTo(cx - half, baseY)
      ..lineTo(cx - half * 0.72, topY + height * 0.22)
      ..quadraticBezierTo(cx, topY, cx + half * 0.72, topY + height * 0.22)
      ..lineTo(cx + half, baseY)
      ..close();

    canvas.drawPath(body, red);

    // Vertical stripes clipped to tent body
    const int stripeCount = 7;
    for (int i = 0; i < stripeCount; i++) {
      final double x = cx - half + (width * (i / (stripeCount - 1)));
      final double stripeW = width * 0.055;

      canvas.save();
      canvas.clipPath(body);
      canvas.drawRect(
        Rect.fromLTWH(x - stripeW / 2, topY + height * 0.18, stripeW, height * 0.80),
        stripe,
      );
      canvas.restore();
    }
  }

  void _drawFerrisWheel(Canvas canvas, Offset center, double radius) {
    final Paint rim = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final Paint spoke = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, rim);

    // Hub
    canvas.drawCircle(center, radius * 0.10, Paint()..color = Colors.black.withOpacity(0.22));

    // Spokes
    const int spokes = 10;
    for (int i = 0; i < spokes; i++) {
      final double a = (i / spokes) * pi * 2.0;
      final Offset p = Offset(center.dx + cos(a) * radius, center.dy + sin(a) * radius);
      canvas.drawLine(center, p, spoke);

      // Cabins as small dots
      if (i % 2 == 0) {
        final Offset c = Offset(center.dx + cos(a) * radius * 1.02, center.dy + sin(a) * radius * 1.02);
        canvas.drawCircle(c, 2.6, Paint()..color = Colors.black.withOpacity(0.25));
      }
    }
  }

  void _drawLights(Canvas canvas, Size size, double y) {
    final double w = size.width;

    final Paint wire = Paint()
      ..color = Colors.black.withOpacity(0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final Path path = Path()
      ..moveTo(w * 0.20, y)
      ..quadraticBezierTo(w * 0.50, y + 22, w * 0.80, y);

    canvas.drawPath(path, wire);

    final Paint glow = Paint()
      ..color = const Color(0xFFFFE08A).withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final Paint bulb = Paint()..color = const Color(0xFFFFD36A).withOpacity(0.95);

    const int bulbs = 12;
    for (int i = 0; i < bulbs; i++) {
      final double t = i / (bulbs - 1);
      final double x = w * 0.20 + (w * 0.60 * t);
      final double bulbY = y + 18.0 * sin(pi * t); // gentle sag

      final Offset c = Offset(x, bulbY);
      canvas.drawCircle(c, 6.0, glow);
      canvas.drawCircle(c, 3.0, bulb);
    }
  }

  void _drawMachine(Canvas canvas, Size size, double baseY) {
    final double w = size.width;
    final double cx = w * 0.50;

    final Paint body = Paint()
      ..color = const Color(0xFF8A1C1F).withOpacity(0.95);

    final RRect rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, baseY - 52),
        width: w * 0.12,
        height: 115,
      ),
      const Radius.circular(12),
    );

    canvas.drawRRect(rect, body);

    // Small highlight so it doesn’t disappear into tents later
    canvas.drawRRect(
      rect,
      Paint()
        ..color = Colors.white.withOpacity(0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
