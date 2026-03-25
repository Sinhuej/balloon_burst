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

  // Visual-only size. Gameplay hit logic stays elsewhere.
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

      final sizeVariance = 0.85 + ((seed % 20).abs() / 100);
      final shadeVariance = 0.92 + ((seed % 10).abs() / 100);

      final radius =
          (baseBalloonRadius * cfg.visualScale * sizeVariance).roundToDouble();

      final x =
          (centerX + (balloon.xOffset * size.width * 0.5)).roundToDouble();
      final y = balloon.y.roundToDouble();
      final center = Offset(x, y);

      _paintStreakGlow(canvas, center, radius);

      final worldColor = _colorForWorld(currentWorld);

      final baseColor = Color.lerp(
        worldColor,
        Colors.white,
        (shadeVariance - 0.92) * 0.35,
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
          break;
        case 2:
          _paintArcadeRim(canvas, center, radius);
          _paintClassicHighlights(canvas, x, y, radius);
          break;
        case 3:
          _paintCarnivalDoubleHighlight(canvas, x, y, radius);
          _paintBottomSheen(canvas, center, radius);
          break;
      }

      _paintString(canvas, balloon, x, y, radius, seed);
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
      ..color = Colors.white.withOpacity(0.28)
      ..isAntiAlias = true;

    final highlightX = (x - radius * 0.35).roundToDouble();
    final highlightY = (y - radius * 0.35).roundToDouble();

    canvas.drawCircle(
      Offset(highlightX, highlightY),
      radius * 0.25,
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
      ..color = Colors.white.withOpacity(0.34)
      ..isAntiAlias = true;

    final smallHighlight = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..isAntiAlias = true;

    canvas.drawCircle(
      Offset(
        (x - radius * 0.34).roundToDouble(),
        (y - radius * 0.36).roundToDouble(),
      ),
      radius * 0.28,
      mainHighlight,
    );

    canvas.drawCircle(
      Offset(
        (x - radius * 0.10).roundToDouble(),
        (y - radius * 0.52).roundToDouble(),
      ),
      radius * 0.11,
      smallHighlight,
    );
  }

  void _paintArcadeRim(Canvas canvas, Offset center, double radius) {
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..color = Colors.white.withOpacity(0.16)
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius - 0.8, rimPaint);
  }

  void _paintCarnivalDoubleHighlight(
    Canvas canvas,
    double x,
    double y,
    double radius,
  ) {
    final strongHighlight = Paint()
      ..color = Colors.white.withOpacity(0.30)
      ..isAntiAlias = true;

    final softHighlight = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..isAntiAlias = true;

    canvas.drawCircle(
      Offset(
        (x - radius * 0.33).roundToDouble(),
        (y - radius * 0.34).roundToDouble(),
      ),
      radius * 0.23,
      strongHighlight,
    );

    canvas.drawCircle(
      Offset(
        (x - radius * 0.02).roundToDouble(),
        (y - radius * 0.18).roundToDouble(),
      ),
      radius * 0.10,
      softHighlight,
    );
  }

  void _paintBottomSheen(Canvas canvas, Offset center, double radius) {
    final sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.08),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, sheenPaint);
  }

  void _paintString(
    Canvas canvas,
    Balloon balloon,
    double x,
    double y,
    double radius,
    int seed,
  ) {
    if (seed % 3 != 0) return;

    final stringPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..strokeWidth = 1.2
      ..isAntiAlias = true;

    final stringLength = 17.0 + ((seed % 4).abs() * 1.5);
    final swayX = sin(balloon.phase + balloon.age * 1.15) * 4.0;
    final swayY = sin(balloon.phase + balloon.age * 0.65) * 1.2;

    canvas.drawLine(
      Offset(x, y + radius),
      Offset(x + swayX, y + radius + stringLength + swayY),
      stringPaint,
    );
  }

  Color _colorForWorld(int world) {
    switch (world) {
      case 2:
        return const Color(0xFF4DA3FF);
      case 3:
        return const Color(0xFFB04DFF);
      case 4:
        return const Color(0xFF9FA8DA);
      default:
        return const Color(0xFFE53935);
    }
  }

  @override
  bool shouldRepaint(covariant BalloonPainter oldDelegate) => true;
}
