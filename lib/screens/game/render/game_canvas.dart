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

  // 🔥 NEW — Competitive Precision Tracking
  final int streak;
  final int bestStreak;

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
    required this.streak,
    required this.bestStreak,
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

            final bool paintBaseBg = effectiveBg.opacity > 0.0;

            final Color pulseOverlayColor =
                surge.showNextWorldColor ? backgroundColor : pulseColor;

            final bool paintPulseOverlay = surge.isPulseActive &&
                surge.pulseOpacity > 0.0 &&
                pulseOverlayColor.opacity > 0.0;

            final bool lightningActive = surge.isLightningActive;

            final double atmosphereShakeY =
                surge.shakeYOffset + surge.lightningShakeAmp;

            return Stack(
              children: [
                // -----------------------------
                // Atmosphere layer (SHAKEN)
                // -----------------------------
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(0, atmosphereShakeY),
                    child: Stack(
                      children: [
                        if (paintBaseBg)
                          Positioned.fill(
                            child: ColoredBox(color: effectiveBg),
                          ),

                        if (paintPulseOverlay)
                          Positioned.fill(
                            child: Opacity(
                              opacity: surge.pulseOpacity,
                              child: ColoredBox(color: pulseOverlayColor),
                            ),
                          ),

                        if (lightningActive && surge.lightningDarkenOpacity > 0.0)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: surge.lightningDarkenOpacity,
                                child: const ColoredBox(color: Colors.black),
                              ),
                            ),
                          ),

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
                // -----------------------------
                Positioned.fill(
                  child: CustomPaint(
                    painter: BalloonPainter(balloons, gameState, currentWorld),
                  ),
                ),

                if (lightningActive && surge.lightningFlashOpacity > 0.0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: surge.lightningFlashOpacity,
                        child: const ColoredBox(color: Colors.white),
                      ),
                    ),
                  ),

                // 🔥 Subtle Streak HUD (earned prestige)
                if (streak > 0)
                  Positioned(
                    top: 32,
                    right: 24,
                    child: Opacity(
                      opacity: 0.75,
                      child: Text(
                        'STREAK ×$streak',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),

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
