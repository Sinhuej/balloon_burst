import 'package:flutter/material.dart';

import '../game/game_controller.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;

  // UI-only state
  late final List<bool> _popped;
  late final List<bool> _pressed;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.start();

    _popped = List<bool>.filled(5, false);
    _pressed = List<bool>.filled(5, false);
  }

  void _onBalloonTap(int index) {
    if (_popped[index]) return;

    // Phase 1: visual feedback
    setState(() {
      _pressed[index] = true;
    });

    // Phase 2: remove after brief delay
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;

      setState(() {
        _pressed[index] = false;
        _popped[index] = true;
      });
    });
  }

  List<Widget> _buildBalloons() {
    final balloons = <Widget>[];

    for (var i = 0; i < _popped.length; i++) {
      if (_popped[i]) continue;

      final color = _pressed[i] ? Colors.blue : Colors.red;

      balloons.add(
        GestureDetector(
          onTap: () => _onBalloonTap(i),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
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
