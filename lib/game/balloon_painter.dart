import 'dart:math';

import 'package:flutter/material.dart';
import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/gameplay/balloon.dart';
import 'package:balloon_burst/game/balloon_type.dart';

class BalloonPainter extends CustomPainter {
  final List<Balloon> balloons;
  final GameState gameState;
  final int currentWorld;
  final int streak;

  BalloonPainter(
    this.balloons,
    this.gameState,
    this.currentWorld, {
    required this.streak,
  });

  static const double baseBalloonRadius = 17.5;

  @override
  void paint(Canvas canvas, Size size) {
    final dangerHeight = 40.0;
    final dangerRect = Rect.fromLTWH(
      0,
      size.height - dangerHeight,
      size.width,
      dangerHeight,
    );

    final dangerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Color.fromARGB(20, 255, 0, 0),
        ],
      ).createShader(dangerRect);

    canvas.drawRect(dangerRect, dangerPaint);

    if (gameState.framesSinceStart < 90) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Tap to Burst',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(
        (size.width - textPainter.width) / 2,
        size.height * 0.25,
      );

      textPainter.paint(canvas, offset);
    }

    if (gameState.tapPulse) {
      final pulsePaint = Paint()
        ..color = const Color.fromARGB(28, 80, 160, 255);
      canvas.drawRect(Offset.zero & size, pulsePaint);
    }

    final centerX = size.width / 2;

    for (final balloon in balloons) {
      if (balloon.isPopped) continue;

      final cfg = balloonTypeConfig[balloon.type]!;
      final seed = balloon.id.hashCode;
      final styleVariant = seed.abs() % 4;
      final paletteIndex = (seed.abs() ~/ 7) % _paletteForWorld(currentWorld).length;

      final sizeVariance = 0.85 + ((seed % 20).abs() / 100);
      final shadeVariance = 0.92 + ((seed % 10).abs() / 100);

      final radius =
          (baseBalloonRadius * cfg.visualScale * sizeVariance).roundToDouble();

      final x =
          (centerX + (balloon.xOffset * size.width * 0.5)).roundToDouble();
      final y = balloon.y.roundToDouble();
      final center = Offset(x, y);

      _paintStreakGlow(canvas, center, radius);

      final paletteColor = _paletteForWorld(currentWorld)[paletteIndex];
      final baseColor = Color.lerp(
        paletteColor,
        Colors.white,
        (shadeVariance - 0.92) * 0.16,
      )!;

      final bodyPaint = Paint()
        ..color = baseColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.medium;

      canvas.drawCircle(center, radius, bodyPaint);

      final bodyShadowPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.4, 0.4),
          radius: 1.0,
          colors: [
            Colors.black.withOpacity(0.18),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: radius),
        );

      canvas.drawCircle(center, radius, bodyShadowPaint);

      switch (styleVariant) {
        case 0:
          _paintClassicHighlights(canvas, x, y, radius);
          break;
        case 1:
          _paintGlossyHighlights(canvas, x, y, radius);
          _paintSpecDot(canvas, x, y, radius);
          break;
        case 2:
          _paintArcadeRim(canvas, center, radius);
          _paintSideSheen(canvas, x, y, radius);
          _paintClassicHighlights(canvas, x, y, radius);
          break;
        case 3:
          _paintCarnivalStripe(canvas, center, radius);
          _paintCarnivalDoubleHighlight(canvas, x, y, radius);
          _paintBottomSheen(canvas, center, radius);
          break;
      }

      _paintKnot(canvas, x, y, radius, styleVariant);
      _paintString(canvas, balloon, x, y, radius, seed, styleVariant);
    }
  }

  void _paintStreakGlow(Canvas canvas, Offset center, double radius) {
    if (streak < 10) return;

    final glowOpacity = streak >= 30
        ? 0.42
        : streak >= 20
            ? 0.30
            : 0.18;

    final glowBlur = streak >= 30
        ? 18.0
        : streak >= 20
            ? 14.0
            : 10.0;

    final glowRadius = streak >= 30
        ? radius + 10
        : streak >= 20
            ? radius + 8
            : radius + 6;

    final glowColor = streak >= 30
        ? const Color(0xFF00E5FF)
        : streak >= 20
            ? const Color(0xFFFFD54F)
            : Colors.white;

    final glowPaint = Paint()
      ..color = glowColor.withOpacity(glowOpacity)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlur);

    canvas.drawCircle(center, glowRadius, glowPaint);
  }

  void _paintClassicHighlights(
    Canvas canvas,
    double x,
    double y,
    double radius,
  ) {
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.34)
      ..isAntiAlias = true;

    canvas.drawCircle(
      Offset(
        (x - radius * 0.34).roundToDouble(),
        (y - radius * 0.34).roundToDouble(),
      ),
      radius * 0.24,
      highlightPaint,
    );
  }

  void _paintGlossyHighlights(
    Canvas canvas,
    double x,
    double y,
    double radius,
  ) {
    final mainHighlight = Paint()
      ..color = Colors.white.withOpacity(0.46)
      ..isAntiAlias = true;

    final elongatedHighlight = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..isAntiAlias = true;

    canvas.drawCircle(
      Offset(
        (x - radius * 0.32).roundToDouble(),
        (y - radius * 0.38).roundToDouble(),
      ),
      radius * 0.30,
      mainHighlight,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          (x - radius * 0.05).roundToDouble(),
          (y - radius * 0.48).roundToDouble(),
        ),
        width: radius * 0.26,
        height: radius * 0.12,
      ),
      elongatedHighlight,
    );
  }

  void _paintSpecDot(Canvas canvas, double x, double y, double radius) {
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.30)
      ..isAntiAlias = true;

    canvas.drawCircle(
      Offset(
        (x + radius * 0.10).roundToDouble(),
        (y - radius * 0.52).roundToDouble(),
      ),
      radius * 0.07,
      dotPaint,
    );
  }

  void _paintArcadeRim(Canvas canvas, Offset center, double radius) {
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withOpacity(0.22)
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius - 1.0, rimPaint);
  }

  void _paintSideSheen(Canvas canvas, double x, double y, double radius) {
    final sheenPaint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..isAntiAlias = true;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          (x + radius * 0.22).roundToDouble(),
          y.roundToDouble(),
        ),
        width: radius * 0.18,
        height: radius * 0.62,
      ),
      sheenPaint,
    );
  }

  void _paintCarnivalDoubleHighlight(
    Canvas canvas,
    double x,
    double y,
    double radius,
  ) {
    final strongHighlight = Paint()
      ..color = Colors.white.withOpacity(0.34)
      ..isAntiAlias = true;

    final softHighlight = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..isAntiAlias = true;

    canvas.drawCircle(
      Offset(
        (x - radius * 0.32).roundToDouble(),
        (y - radius * 0.34).roundToDouble(),
      ),
      radius * 0.22,
      strongHighlight,
    );

    canvas.drawCircle(
      Offset(
        (x + radius * 0.08).roundToDouble(),
        (y - radius * 0.16).roundToDouble(),
      ),
      radius * 0.11,
      softHighlight,
    );
  }

  void _paintCarnivalStripe(Canvas canvas, Offset center, double radius) {
    final stripePaint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..isAntiAlias = true;

    final stripeRect = Rect.fromCenter(
      center: center,
      width: radius * 0.34,
      height: radius * 1.65,
    );

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawRect(stripeRect, stripePaint);
    canvas.restore();
  }

  void _paintBottomSheen(Canvas canvas, Offset center, double radius) {
    final sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.14),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, sheenPaint);
  }

  void _paintKnot(
    Canvas canvas,
    double x,
    double y,
    double radius,
    int styleVariant,
  ) {
    final knotPaint = Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..isAntiAlias = true;

    final knotWidth = styleVariant == 3 ? 6.0 : 5.0;
    final knotHeight = styleVariant == 3 ? 4.0 : 3.0;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, y + radius + 1.5),
        width: knotWidth,
        height: knotHeight,
      ),
      knotPaint,
    );
  }

  void _paintString(
    Canvas canvas,
    Balloon balloon,
    double x,
    double y,
    double radius,
    int seed,
    int styleVariant,
  ) {
    if (seed % 3 != 0) return;

    final stringPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..strokeWidth = styleVariant == 2 ? 1.35 : 1.2
      ..isAntiAlias = true;

    final stringLength =
        18.0 + ((seed % 4).abs() * 1.8) + (styleVariant == 3 ? 2.0 : 0.0);

    final swayX =
        sin(balloon.phase + balloon.age * 1.10) * (styleVariant == 2 ? 4.8 : 4.0);
    final swayY = sin(balloon.phase + balloon.age * 0.62) * 1.2;

    canvas.drawLine(
      Offset(x, y + radius + 1.5),
      Offset(x + swayX, y + radius + stringLength + swayY),
      stringPaint,
    );
  }

  List<Color> _paletteForWorld(int world) {
    switch (world) {
      case 2:
        return const [
          Color(0xFF2EA8FF),
          Color(0xFFFF4FA3),
          Color(0xFFFFC928),
          Color(0xFF3DDB7A),
          Color(0xFF9B6BFF),
          Color(0xFFFF8A2B),
          Color(0xFF00D9C0),
        ];
      case 3:
        return const [
          Color(0xFFB04DFF),
          Color(0xFFFF5AA5),
          Color(0xFFFFC400),
          Color(0xFF39D98A),
          Color(0xFF45C2FF),
          Color(0xFFFF7A59),
          Color(0xFFE86BFF),
        ];
      case 4:
        return const [
          Color(0xFF82B1FF),
          Color(0xFFFFC400),
          Color(0xFFFF6E6E),
          Color(0xFF4DE1FF),
          Color(0xFFF08CFF),
          Color(0xFF7CFFB2),
        ];
      default:
        return const [
          Color(0xFFFF3B30),
          Color(0xFFFF8C1A),
          Color(0xFFFFE600),
          Color(0xFF2ED573),
          Color(0xFF1E90FF),
          Color(0xFFFF4FA3),
        ];
    }
  }

  @override
  bool shouldRepaint(covariant BalloonPainter oldDelegate) => true;
}
