import 'package:flutter/material.dart';

import '../game/game_controller.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;

  // Rising Worlds (UI-only)
  int _currentWorld = 1;

  // World config: world -> balloon count
  final List<int> _worldBalloonCounts = [
    5,  // World 1
    6,  // World 2
    7,  // World 3
    8,  // World 4
    9,  // World 5
    10, // World 6
    11, // World 7
    12, // World 8
    13, // World 9
    14, // World 10
    15, // World 11
    16, // World 12
  ];

  late List<bool> _popped;
  late List<bool> _pressed;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.start();
    _startWorld();
  }

  void _startWorld() {
    final balloonCount = _worldBalloonCounts[_currentWorld - 1];
    _popped = List<bool>.filled(balloonCount, false);
    _pressed = List<bool>.filled(balloonCount, false);
  }

  // -------- Layout Pressure (Secondary Axis) --------

  double _spacingForWorld(int world) {
    if (world <= 3) return 20;
    if (world <= 6) return 16;
    if (world <= 9) return 12;
    return 8;
  }

  double _maxWidthForWorld(int world, double screenWidth) {
    if (world <= 6) return screenWidth;          // no constraint
    if (world <= 9) return screenWidth * 0.85;   // mild constraint
    return screenWidth * 0.7;                    // stronger constraint
  }

  // -------- Interaction --------

  void _onBalloonTap(int index) {
    if (_popped[index]) return;

    // Phase 1: feedback
    setState(() {
      _pressed[index] = true;
    });

    // Phase 2: pop + resolve
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;

      setState(() {
        _pressed[index] = false;
        _popped[index] = true;
      });

      _checkWorldComplete();
    });
  }

  void _checkWorldComplete() {
    if (!_popped.every((b) => b)) return;

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      setState(() {
        if (_currentWorld < _worldBalloonCounts.length) {
          _currentWorld++;
        } else {
          _currentWorld = 1; // Restart after World 12
        }
        _startWorld();
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

    return balloons;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = _spacingForWorld(_currentWorld);
    final maxWidth = _maxWidthForWorld(_currentWorld, screenWidth);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'World $_currentWorld',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Wrap(
                spacing: spacing,
                runSpacing: spacing,
                alignment: WrapAlignment.center,
                children: _buildBalloons(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
