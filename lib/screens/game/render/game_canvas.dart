import 'package:flutter/material.dart';

import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/game/balloon_painter.dart';
import 'package:balloon_burst/gameplay/balloon.dart';

import '../effects/world_surge_pulse.dart';
import '../effects/lightning_painter.dart';
import '../debug/debug_hud.dart';

class GameCanvas extends StatefulWidget {
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

  // 🔥 NEW: streak display input
  final int streak;

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
  });

  @override
  State<GameCanvas> createState() => _GameCanvasState();
}

class _GameCanvasState extends State<GameCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _milestoneController;
  late final Animation<double> _milestoneScale;

  int _currentMilestone = 0;

  @override
  void initState() {
    super.initState();

    _currentMilestone = _milestoneFor(widget.streak);

    _milestoneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0, // idle at end (scale = 1.0)
    );

    _milestoneScale = Tween<double>(begin: 1.25, end: 1.0).animate(
      CurvedAnimation(
        parent: _milestoneController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant GameCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    final prevMilestone = _milestoneFor(oldWidget.streak);
    final nextMilestone = _milestoneFor(widget.streak);

    // Reset visuals on streak reset.
    if (widget.streak <= 0) {
      _currentMilestone = 0;
      _milestoneController.value = 1.0;
      return;
    }

    _currentMilestone = nextMilestone;

    // Trigger ONLY once when crossing 10/20/30 upward.
    if (nextMilestone > prevMilestone) {
      _milestoneController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _milestoneController.dispose();
    super.dispose();
  }

  int _milestoneFor(int streak) {
    if (streak >= 30) return 3; // “you are locked in”
    if (streak >= 20) return 2; // dramatic
    if (streak >= 10) return 1; // noticeable but controlled
    return 0;
  }

  TextStyle _streakStyleFor(int milestone) {
    // Keep it consistent across worlds. Escalate by milestone only.
    switch (milestone) {
      case 3:
       return const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
        color: Colors.white,
        shadows: [
         // Depth shadow (crisp)
         Shadow(
          color: Colors.black,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
         // Thin cyan edge (brand accent, not flood)
         Shadow(
          color: Color(0xFF00E5FF),
          blurRadius: 6,
          offset: Offset(0, 0),
        ),
      ],
    );
      case 2:
        return const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Color(0xFFFFE28A),
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 2)),
            Shadow(color: Color(0xFFFFC107), blurRadius: 12, offset: Offset(0, 0)),
          ],
        );
      case 1:
        return const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Color(0xFFFFE9A6),
          shadows: [
            Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 2)),
            Shadow(color: Color(0xFFFFD54F), blurRadius: 8, offset: Offset(0, 0)),
          ],
        );
      default:
        return const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: Colors.white,
          shadows: [
            Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
          ],
        );
    }
  }

  Widget _buildStreakOverlay() {
    if (widget.streak <= 0) return const SizedBox.shrink();

    final style = _streakStyleFor(_currentMilestone);

    return Positioned(
      top: 18,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: ScaleTransition(
          scale: _milestoneScale,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
               color: Colors.black.withOpacity(_currentMilestone >= 3 ? 0.55 : 0.22),
               borderRadius: BorderRadius.circular(14),
               border: _currentMilestone >= 3
                ? Border.all(
                 color: const Color(0xFF00E5FF),
                 width: 1.8,
                )
               : null,
              ),
              child: Text(
                'STREAK ×${widget.streak}',
                style: style,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTapDown,
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: widget.surge.listenable,
          builder: (context, _) {
            final Color effectiveBg = widget.surge.showNextWorldColor
                ? widget.pulseColor
                : widget.backgroundColor;

            // If GameScreen is doing parallax behind us, it will pass transparent here.
            // In that case, we must NOT paint a base background, or we’ll reintroduce
            // scaffold/white during transitions.
            final bool paintBaseBg = effectiveBg.opacity > 0.0;

            // Pulse overlay color: opposite of effectiveBg (fade-back wash).
            final Color pulseOverlayColor = widget.surge.showNextWorldColor
                ? widget.backgroundColor
                : widget.pulseColor;

            final bool paintPulseOverlay = widget.surge.isPulseActive &&
                widget.surge.pulseOpacity > 0.0 &&
                pulseOverlayColor.opacity > 0.0;

            final bool lightningActive = widget.surge.isLightningActive;

            // IMPORTANT:
            // Shake should NOT affect gameplay (balloons), only atmosphere layers.
            final double atmosphereShakeY =
                widget.surge.shakeYOffset + widget.surge.lightningShakeAmp;

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
                              opacity: widget.surge.pulseOpacity,
                              child: ColoredBox(color: pulseOverlayColor),
                            ),
                          ),

                        // Lightning pre-darken (psych bump)
                        if (lightningActive &&
                            widget.surge.lightningDarkenOpacity > 0.0)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: widget.surge.lightningDarkenOpacity,
                                child: const ColoredBox(color: Colors.black),
                              ),
                            ),
                          ),

                        // Lightning bolt (visual-only) — BELOW balloons
                        if (lightningActive && widget.surge.lightningT > 0.0)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: LightningPainter(
                                  t: widget.surge.lightningT,
                                  currentWorld: widget.currentWorld,
                                  seed: widget.surge.lightningSeed,
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
                    painter: BalloonPainter(
                      widget.balloons,
                      widget.gameState,
                      widget.currentWorld,
                    ),
                  ),
                ),

                // Illuminate balloons briefly during strike (ABOVE balloons)
                // Keep this unshaken so it doesn’t “slide” relative to taps.
                if (lightningActive && widget.surge.lightningFlashOpacity > 0.0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: widget.surge.lightningFlashOpacity,
                        child: const ColoredBox(color: Colors.white),
                      ),
                    ),
                  ),

                // -----------------------------
                // STREAK overlay (prestige-only)
                // Trigger + persistent milestone styling
                // -----------------------------
                _buildStreakOverlay(),

                // Debug HUD (dev only) — topmost
                if (widget.showHud)
                  DebugHud(
                    fps: widget.fps,
                    speedMultiplier: widget.speedMultiplier,
                    world: widget.currentWorld,
                    balloonCount: widget.balloons.length,
                    recentAccuracy: widget.recentAccuracy,
                    recentMisses: widget.recentMisses,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
