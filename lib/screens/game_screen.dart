import 'package:flutter/material.dart';

import '../game/game_controller.dart';

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

    // Step 7B behavior: auto-start game
    _controller.start();
  }

  void _endGame() {
    setState(() {
      _controller.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Game State: ${_controller.state.name}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _controller.state == GameState.running
                  ? _endGame
                  : null,
              child: const Text('End Game (Debug)'),
            ),
          ],
        ),
      ),
    );
  }
}
