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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Game State: ${_controller.state.name}'),

            if (_controller.gameplayWorld != null)
              const Text('GameplayWorld: initialized'),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _controller.start();
                });
              },
              child: const Text('Start'),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _controller.stop();
                });
              },
              child: const Text('Stop'),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _controller.reset();
                });
              },
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}
