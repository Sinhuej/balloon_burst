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

  static const double baseBalloonRadius = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    gameState.viewportHeight = size.height;
    gameState.framesSinceStart++;

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
      gameState.tapPulse = false;
    }

    final centerX = size.width / 2;

    final sorted = balloons.toList()
      ..sort((a, b) =>
          balloonTypeConfig[a.type]!.zLayer.compareTo(
            balloonTypeConfig[b.type]!.zLayer,
          ));

    for (final balloon in sorted) {
      if (balloon.isPopped) continue;

      final cfg = balloonTypeConfig[balloon.type]!;

      final seed = balloon.hashCode;

      final sizeVariance = 0.85 + ((seed % 20) / 100);
      final shadeVariance = 0.92 + ((seed % 10) / 100);

      final radius =
      (baseBalloonRadius * cfg.visualScale * sizeVariance).roundToDouble();

      final x = (centerX + (balloon.xOffset * size.width * 0.5)).roundToDouble();
      final y = balloon.y.roundToDouble();
      final center = Offset(x, y);

      if (streak >= 10) {
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

      final worldColor = _colorForWorld(currentWorld);

final baseColor = Color.lerp(
  worldColor,
  Colors.white,
  (shadeVariance - 0.92) * 0.35,
)!;

final paint = Paint()
  ..color = baseColor
  ..style = PaintingStyle.fill
  ..isAntiAlias = true
  ..filterQuality = FilterQuality.medium
  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.01);

      canvas.drawCircle(center, radius, paint);

      final shadowPaint = Paint()
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

      canvas.drawCircle(center, radius, shadowPaint);

      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.35);

      canvas.drawCircle(
        Offset(x - radius * 0.35, y - radius * 0.35),
        radius * 0.25,
        highlightPaint,
      );

      if (seed % 3 == 0) {
        final stringPaint = Paint()
          ..color = Colors.black.withOpacity(0.35)
          ..strokeWidth = 1.2;

        canvas.drawLine(
          Offset(x, y + radius),
          Offset(x + sin(y) * 6, y + radius + 18),
          stringPaint,
        );
      }
    }
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
