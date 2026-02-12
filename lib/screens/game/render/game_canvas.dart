import 'package:flutter/material.dart';

import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/game/balloon_painter.dart';
import 'package:balloon_burst/gameplay/balloon.dart';

import '../effects/world_surge_pulse.dart';
import '../effects/lightning_painter.dart';
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
            final Color effectiveBg =
                surge.showNextWorldColor ? pulseColor : backgroundColor;

            // If GameScreen is doing parallax behind us, it will pass transparent here.
            // In that case, we must NOT paint a base background, or we’ll reintroduce
            // scaffold/white during transitions.
            final bool paintBaseBg = effectiveBg.opacity > 0.0;

            // Pulse overlay color: opposite of effectiveBg (fade-back wash).
            final Color pulseOverlayColor =
                surge.showNextWorldColor ? backgroundColor : pulseColor;

            final bool paintPulseOverlay = surge.isPulseActive &&
                surge.pulseOpacity > 0.0 &&
                pulseOverlayColor.opacity > 0.0;

            final bool lightningActive = surge.isLightningActive;

            // IMPORTANT:
            // Shake should NOT affect gameplay (balloons), only atmosphere layers.
            final double atmosphereShakeY =
                surge.shakeYOffset + surge.lightningShakeAmp;

            return Stack(
              children: [
                // -----------------------------
                // Atmosphere layer (SHAKEN)
                // background + pulse + lightning
                // -----------------------------
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(0, atmosphereShakeY),
                    child: Stack(
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

                        // Lightning pre-darken (psych bump)
                        if (lightningActive && surge.lightningDarkenOpacity > 0.0)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: surge.lightningDarkenOpacity,
                                child: const ColoredBox(color: Colors.black),
                              ),
                            ),
                          ),

                        // Lightning bolt (visual-only) — BELOW balloons
                        if (lightningActive && surge.lightningT > 0.0)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: LightningPainter(
                                  t: surge.lightningT,
                                  currentWorld: currentWorld,
                                  seed: surge.lightningSeed,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // -----------------------------
                // Gameplay layer (NOT SHAKEN)
                // This preserves tap accuracy.
                // -----------------------------
                Positioned.fill(
                  child: CustomPaint(
                    painter: BalloonPainter(balloons, gameState, currentWorld),
                  ),
                ),

                // Illuminate balloons briefly during strike (ABOVE balloons)
                // Keep this unshaken so it doesn’t “slide” relative to taps.
                if (lightningActive && surge.lightningFlashOpacity > 0.0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: surge.lightningFlashOpacity,
                        child: const ColoredBox(color: Colors.white),
                      ),
                    ),
                  ),

                // Debug HUD (dev only) — topmost
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
