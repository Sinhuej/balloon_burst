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

  void _resetGame() {
    setState(() {
      _controller.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Game State: ${state.name}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: state == GameState.running ? _endGame : null,
              child: const Text('End Game (Debug)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: state == GameState.ended ? _resetGame : null,
              child: const Text('Reset Game (Debug)'),
            ),
          ],
        ),
      ),
    );
  }
}
