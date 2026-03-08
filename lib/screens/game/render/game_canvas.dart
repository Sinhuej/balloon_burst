import 'package:flutter/material.dart';

import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/game/balloon_painter.dart';
import 'package:balloon_burst/gameplay/balloon.dart';
import 'package:balloon_burst/screens/game/effects/pop_particle.dart';
import 'package:balloon_burst/tj_engine/juice/models/score_burst.dart';

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
  final List<PopParticle> particles;
  final List<ScoreBurst> scoreBursts;
  final double popShake;
  final GameState gameState;

  final VoidCallback onLongPress;
  final GestureTapDownCallback onTapDown;

  final bool showHud;
  final double fps;
  final double speedMultiplier;
  final double recentAccuracy;
  final int recentMisses;
  final int streak;

  const GameCanvas({
    super.key,
    required this.currentWorld,
    required this.nextWorld,
    required this.backgroundColor,
    required this.pulseColor,
    required this.surge,
    required this.balloons,
    required this.particles,
    required this.scoreBursts,
    required this.popShake,
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

class _GameCanvasState extends State<GameCanvas> {

  Color _burstColor() {
    if (widget.streak >= 30) return const Color(0xFF00E5FF);
    if (widget.streak >= 20) return const Color(0xFFFFD54F);
    if (widget.streak >= 10) return const Color(0xFFFFF176);
    return Colors.white;
  }

  List<Shadow> _burstShadows() {
    if (widget.streak >= 30) {
      return const [
        Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2)),
        Shadow(color: Color(0xFF00E5FF), blurRadius: 10, offset: Offset(0, 0)),
      ];
    }

    if (widget.streak >= 20) {
      return const [
        Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2)),
        Shadow(color: Color(0xFFFFC107), blurRadius: 10, offset: Offset(0, 0)),
      ];
    }

    if (widget.streak >= 10) {
      return const [
        Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2)),
        Shadow(color: Color(0xFFFFE082), blurRadius: 6, offset: Offset(0, 0)),
      ];
    }

    return const [
      Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2)),
    ];
  }

  Widget _buildParticlesOverlay() {
    if (widget.particles.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: Stack(
        children: widget.particles.map((p) {
          return Positioned(
            left: p.x,
            top: p.y,
            child: Opacity(
              opacity: p.opacity,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: p.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScoreBurstsOverlay() {
    if (widget.scoreBursts.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: Stack(
        children: widget.scoreBursts.map((b) {
          final t = b.t01;
          final rise = 44.0 * Curves.easeOut.transform(t);
          final fade = 1.0 - Curves.easeIn.transform(t);

          return Positioned(
            left: b.x - 10,
            top: (b.y - rise) - 18,
            child: Opacity(
              opacity: fade.clamp(0.0, 1.0),
              child: Text(
                '+${b.value}',
                style: TextStyle(
                  color: _burstColor(),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  shadows: _burstShadows(),
                ),
              ),
            ),
          );
        }).toList(),
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
        child: Stack(
          children: [

            Positioned.fill(
              child: Transform.translate(
                offset: Offset(
                  widget.popShake * ((DateTime.now().microsecond % 2 == 0) ? 1 : -1),
                  widget.popShake * ((DateTime.now().millisecond % 2 == 0) ? -1 : 1),
                ),
                child: CustomPaint(
                  painter: BalloonPainter(
                    widget.balloons,
                    widget.gameState,
                    widget.currentWorld,
                  ),
                ),
              ),
            ),

            _buildParticlesOverlay(),
            _buildScoreBurstsOverlay(),

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
        ),
      ),
    );
  }
}
