import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_controller.dart';
import '../game/balloon_painter.dart';
import '../ui/skins.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final GameController _controller;
  late final AudioPlayer _audioPlayer;
  late final Ticker _ticker;

  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();

    _controller = GameController();
    _controller.start();

    _audioPlayer = AudioPlayer();
    _audioPlayer.setSource(AssetSource('sfx/pop.wav'));

    _loadSoundPreference();

    // 🔑 Drive the engine every frame
    _ticker = createTicker((elapsed) {
      _controller.update(1 / 60);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSoundPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: _controller.world,
        builder: (context, world, _) {
          if (world == null) {
            return const SizedBox.shrink();
          }

          return CustomPaint(
            painter: BalloonPainter(
              balloons: world.balloons,
              skin: Skins.defaultSkin,
              frenzy: false,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}
