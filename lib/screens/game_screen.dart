import 'package:flutter/material.dart';

import '../game/game_controller.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;

  // Rising Worlds
  int _currentWorld = 1;

  final List<int> _worldBalloonCounts = [
    5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
  ];

  late List<bool> _popped;
  late List<bool> _pressed;

  // Failure v1
  int _tapsLeft = 0;
  bool _showFailure = false;

  // World intro
  bool _showWorldIntro = true;

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
    _tapsLeft = balloonCount + 2;
    _showFailure = false;
    _showWorldIntro = true;

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _showWorldIntro = false);
    });
  }

  // ---------- Layout Pressure ----------

  double _spacingForWorld(int world) {
    if (world <= 3) return 20;
    if (world <= 6) return 16;
    if (world <= 9) return 12;
    return 8;
  }

  double _maxWidthForWorld(int world, double screenWidth) {
    if (world <= 6) return screenWidth;
    if (world <= 9) return screenWidth * 0.85;
    return screenWidth * 0.7;
  }

  // ---------- Interaction ----------

  void _onBalloonTap(int index) {
    if (_showWorldIntro || _showFailure) return;
    if (_popped[index]) return;
    if (_tapsLeft <= 0) return;

    setState(() {
      _pressed[index] = true;
      _tapsLeft--;
    });

    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;

      setState(() {
        _pressed[index] = false;
        _popped[index] = true;
      });

      _checkWorldCompleteOrFail();
    });
  }

  void _checkWorldCompleteOrFail() {
    if (_popped.every((b) => b)) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;

        setState(() {
          if (_currentWorld < _worldBalloonCounts.length) {
            _currentWorld++;
          } else {
            _currentWorld = 1;
          }
          _startWorld();
        });
      });
      return;
    }

    if (_tapsLeft <= 0) {
      setState(() {
        _showFailure = true;
      });
    }
  }

  // ---------- UI Builders ----------

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

  Widget _buildWorldIntro() {
    if (!_showWorldIntro) return const SizedBox.shrink();

    return _overlay(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'World $_currentWorld',
            style: _titleStyle,
          ),
          const SizedBox(height: 8),
          Text(
            _currentWorld <= 3
                ? 'Warm up'
                : _currentWorld <= 6
                    ? 'Getting tighter'
                    : _currentWorld <= 9
                        ? 'Watch your taps'
                        : 'Maximum pressure',
            style: _subtitleStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildFailure() {
    if (!_showFailure) return const SizedBox.shrink();

    return _overlay(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Out of taps', style: _titleStyle),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              setState(_startWorld);
            },
            child: const Text('Retry World'),
          ),
        ],
      ),
    );
  }

  Widget _overlay(Widget child) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  static const _titleStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const _subtitleStyle = TextStyle(
    fontSize: 16,
    color: Colors.white70,
  );

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = _spacingForWorld(_currentWorld);
    final maxWidth = _maxWidthForWorld(_currentWorld, screenWidth);

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Taps Left: $_tapsLeft',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
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
          _buildWorldIntro(),
          _buildFailure(),
        ],
      ),
    );
  }
}
