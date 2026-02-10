import 'package:flutter/material.dart';

import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/game/balloon_painter.dart';
import 'package:balloon_burst/gameplay/balloon.dart';

import '../effects/world_surge_pulse.dart';
import '../debug/debug_hud.dart';

class GameCanvas extends StatelessWidget {
  final int currentWorld;
  final int nextWorld;

  final Color backgroundColor;
  final Color pulseColor;

  final WorldSurgePulse surge;
  final List<Balloon> balloons;
  final GameState gameState;

  final VoidCallback onLongPress;
  final GestureTapDownCallback onTapDown;

  final bool showHud;
  final double fps;
  final double speedMultiplier;
  final double recentAccuracy;
  final int recentMisses;

  const GameCanvas({
    super.key,
    required this.currentWorld,
    required this.nextWorld,
    required this.backgroundColor,
    required this.pulseColor,
    required this.surge,
    required this.balloons,
    required this.gameState,
    required this.onLongPress,
    required this.onTapDown,
    required this.showHud,
    required this.fps,
    required this.speedMultiplier,
    required this.recentAccuracy,
    required this.recentMisses,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: onTapDown,
        onLongPress: onLongPress,
        child: AnimatedBuilder(
          animation: surge.listenable,
          builder: (context, _) {
            // Decide which background color should be dominant
            final Color effectiveBg =
                surge.showNextWorldColor ? pulseColor : backgroundColor;

            // If GameScreen is doing parallax behind us, it will pass transparent here.
            // In that case, we must NOT paint a base background, or we'll reveal
            // scaffold/white during transitions.
            final bool paintBaseBg = effectiveBg.opacity > 0.0;

            // Pulse overlay color: opposite of effectiveBg (fade-back wash).
            final Color pulseOverlayColor =
                surge.showNextWorldColor ? backgroundColor : pulseColor;

            final bool paintPulseOverlay = surge.isActive &&
                surge.pulseOpacity > 0.0 &&
                pulseOverlayColor.opacity > 0.0;

            return Stack(
              children: [
                // Base background (ONLY if not transparent)
                if (paintBaseBg)
                  Positioned.fill(
                    child: ColoredBox(color: effectiveBg),
                  ),

                // Pulse fade-back layer (subtle energy wash)
                if (paintPulseOverlay)
                  Positioned.fill(
                    child: Opacity(
                      opacity: surge.pulseOpacity,
                      child: ColoredBox(color: pulseOverlayColor),
                    ),
                  ),

                // Gameplay (balloons) ALWAYS on top
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(0, surge.shakeYOffset),
                    child: CustomPaint(
                      painter: BalloonPainter(balloons, gameState, currentWorld),
                    ),
                  ),
                ),

                // Debug HUD (dev only)
                if (showHud)
                  DebugHud(
                    fps: fps,
                    speedMultiplier: speedMultiplier,
                    world: currentWorld,
                    balloonCount: balloons.length,
                    recentAccuracy: recentAccuracy,
                    recentMisses: recentMisses,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
