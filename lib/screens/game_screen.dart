import 'package:flutter/material.dart';

import '../game/game_controller.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;

  // UI-only state: whether each balloon is popped
  late final List<bool> _popped;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.start();

    _popped = List<bool>.filled(5, false);
  }

  void _popBalloon(int index) {
    if (_popped[index]) return;

    setState(() {
      _popped[index] = true;
    });
  }

  List<Widget> _buildBalloons() {
    final balloons = <Widget>[];

    for (var i = 0; i < _popped.length; i++) {
      if (_popped[i]) continue;

      balloons.add(
        GestureDetector(
          onTap: () => _popBalloon(i),
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    if (balloons.isEmpty) {
      return const [
        Text(
          'All popped!',
          style: TextStyle(fontSize: 18),
        ),
      ];
    }

    return balloons;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: _buildBalloons(),
        ),
      ),
    );
  }
}
