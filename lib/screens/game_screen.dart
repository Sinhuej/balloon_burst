import 'package:flutter/material.dart';
import 'package:balloon_burst/tj_engine/engine/core/tj_game.dart';
import 'package:balloon_burst/game/game_controller.dart';
import 'package:balloon_burst/tj_engine/engine/audio/sound_manager.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _showIntro = true;
  Offset? _tapPoint;

  @override
  void initState() {
    super.initState();
    SoundManager.warmUp();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showIntro = false);
    });
  }

  void _handleTap(TapDownDetails details, GameplayWorld world, Size size) {
    setState(() => _tapPoint = details.localPosition);
    SoundManager.ensureReady();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _tapPoint = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return GestureDetector(
        onTapDown: (details) =>
            _handleTap(details, world, constraints.biggest),
        child: Stack(
          children: [
            GameWidget(game: world.game),

            // Bottom danger zone affordance
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 48,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.red.withOpacity(0.12),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Blue tap feedback
            if (_tapPoint != null)
              Positioned(
                left: _tapPoint!.dx - 16,
                top: _tapPoint!.dy - 16,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.25),
                  ),
                ),
              ),

            // Minimal intro banner
            if (_showIntro)
              Center(
                child: AnimatedOpacity(
                  opacity: _showIntro ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Tap to burst',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
