import 'package:flutter/material.dart';
import '../game/game_controller.dart';
import '../gameplay/gameplay_debug.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final world = _controller.gameplayWorld;
    final stateLabel = world == null ? 'stopped' : 'running';

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Game State: $stateLabel'),
            const SizedBox(height: 8),
            Text(GameplayDebug.status(_controller)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _controller.stop();
                });
              },
              child: const Text('Stop Game'),
            ),
          ],
        ),
      ),
    );
  }
}
