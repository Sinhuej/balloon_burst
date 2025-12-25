import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_controller.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;
  late final AudioPlayer _audioPlayer;

  bool _soundEnabled = true;

  int _currentWorld = 1;

  final List<int> _worldBalloonCounts = [
    5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
  ];

  late List<bool> _popped;
  late List<bool> _pressed;

  int _tapsLeft = 0;
  bool _showFailure = false;
  bool _showWorldIntro = true;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.start();

    _audioPlayer = AudioPlayer();
    _audioPlayer.setVolume(1.0);
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _audioPlayer.setSource(AssetSource('sfx/pop.wav'));

    _loadSoundPreference();
    _startWorld();
  }

  Future<void> _loadSoundPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    });
  }

  Future<void> _toggleSound() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = !_soundEnabled;
    });
    await prefs.setBool('sound_enabled', _soundEnabled);
  }

  void _playPopSound() {
    if (!_soundEnabled) return;
    _audioPlayer.seek(Duration.zero);
    _audioPlayer.resume();
  }

  void _startWorld() {
    final count = _worldBalloonCounts[_currentWorld - 1];
    _popped = List<bool>.filled(count, false);
    _pressed = List<bool>.filled(count, false);
    _tapsLeft = count + 2;
    _showFailure = false;
    _showWorldIntro = true;

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _showWorldIntro = false);
    });
  }

  void _onBalloonTap(int index) {
    if (_showWorldIntro || _showFailure) return;
    if (_popped[index] || _tapsLeft <= 0) return;

    setState(() {
      _pressed[index] = true;
      _tapsLeft--;
    });

    Future.delayed(const Duration(milliseconds: 90), () {
      if (!mounted) return;

      _playPopSound();

      setState(() {
        _pressed[index] = false;
        _popped[index] = true;
      });

      _checkWorldCompleteOrFail();
    });
  }

  void _checkWorldCompleteOrFail() {
    if (_popped.every((b) => b)) {
      Future.delayed(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        setState(() {
          _currentWorld =
              _currentWorld < _worldBalloonCounts.length ? _currentWorld + 1 : 1;
          _startWorld();
        });
      });
      return;
    }

    if (_tapsLeft <= 0) {
      setState(() => _showFailure = true);
    }
  }

  List<Widget> _buildBalloons() {
    final balloons = <Widget>[];

    for (var i = 0; i < _popped.length; i++) {
      if (_popped[i]) continue;

      final isPressed = _pressed[i];
      final color = isPressed ? Colors.blue : Colors.red;

      balloons.add(
        GestureDetector(
          onTap: () => _onBalloonTap(i),
          child: AnimatedScale(
            scale: isPressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 90),
            child: AnimatedOpacity(
              opacity: isPressed ? 0.85 : 1.0,
              duration: const Duration(milliseconds: 90),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return balloons;
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(
                _soundEnabled ? Icons.volume_up : Icons.volume_off,
                color: Colors.black,
              ),
              onPressed: _toggleSound,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Taps Left: $_tapsLeft'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: _buildBalloons(),
                ),
              ],
            ),
          ),
          if (_showWorldIntro)
            _overlay(
              Text(
                'World $_currentWorld',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          if (_showFailure)
            _overlay(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Out of taps',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(_startWorld),
                    child: const Text('Retry World'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
