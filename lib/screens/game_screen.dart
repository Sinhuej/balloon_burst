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
    final balloons = _controller.gameplayWorld?.balloons ?? [];

    return Scaffold(
      body: Stack(
        children: [
          for (int i = 0; i < balloons.length; i++)
            Positioned(
              left: 40.0 + (i * 50),
              top: 200,
              child: Container(
                width: 30,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
