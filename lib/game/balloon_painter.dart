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
    // Viewport truth
    gameState.viewportHeight = size.height;
    gameState.framesSinceStart++;

    // Subtle bottom danger affordance
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

    // Intro banner (first ~1.5s)
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

    // Tap feedback pulse
    if (gameState.tapPulse) {
      final pulsePaint = Paint()
        ..color = const Color.fromARGB(18, 80, 160, 255);
      canvas.drawRect(Offset.zero & size, pulsePaint);
      gameState.tapPulse = false;
    }

    // ---- BALLOONS (depth + scale + color + combo glow) ----

    final centerX = size.width / 2;

    // Sort by visual depth (background → foreground)
    final sorted = balloons.toList()
      ..sort((a, b) =>
          balloonTypeConfig[a.type]!.zLayer.compareTo(
            balloonTypeConfig[b.type]!.zLayer,
          ));

    for (final balloon in sorted) {
      if (balloon.isPopped) continue;

      final cfg = balloonTypeConfig[balloon.type]!;
      final radius = baseBalloonRadius * cfg.visualScale;

      final x = centerX + (balloon.xOffset * size.width * 0.5);
      final y = balloon.y;
      final center = Offset(x, y);

      // Combo Glow (streak power mode)
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

        canvas.drawCircle(
          center,
          glowRadius,
          glowPaint,
        );
      }

      final paint = Paint()
        ..color = _colorForWorld(currentWorld)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        center,
        radius,
        paint,
      );
    }
  }

  Color _colorForWorld(int world) {
    switch (world) {
      case 2:
        return const Color(0xFF4DA3FF); // Sky Blue
      case 3:
        return const Color(0xFFB04DFF); // Neon Purple
      case 4:
        return const Color(0xFF9FA8DA); // Deep Space glow
      default:
        return const Color(0xFFE53935); // Carnival Red
    }
  }

  @override
  bool shouldRepaint(covariant BalloonPainter oldDelegate) => true;
}
