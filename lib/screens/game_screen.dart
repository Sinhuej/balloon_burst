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
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final count = _controller.gameplayWorld?.balloons.length ?? 0;

    return Scaffold(
      body: Center(
        child: Text(
          'Balloons in world: $count',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
