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
    _controller.start(); // <-- THIS is what was missing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 40),
          Text('Score: ${_controller.score}'),
          const Expanded(
            child: Center(
              child: Text('Gameplay Area'),
            ),
          ),
        ],
      ),
    );
  }
}
