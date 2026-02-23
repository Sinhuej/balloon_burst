import 'package:flutter/material.dart';

import 'state/app_state.dart';
import 'screens/start_screen.dart';
import 'app_root.dart';

import 'package:balloon_burst/tj_engine/engine/tj_engine.dart';

void main() {
  runApp(const BalloonBurstApp());
}

class BalloonBurstApp extends StatefulWidget {
  const BalloonBurstApp({super.key});

  @override
  State<BalloonBurstApp> createState() => _BalloonBurstAppState();
}

class _BalloonBurstAppState extends State<BalloonBurstApp> {
  AppView _view = AppView.start;

  // ✅ Single shared engine across Start + Game.
  late final TJEngine _engine;

  bool _engineReady = false;

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  Future<void> _initEngine() async {
    _engine = TJEngine();
    await _engine.leaderboard.load();
    await _engine.loadDailyReward();

    if (!mounted) return;
    setState(() {
      _engineReady = true;
    });
  }

  void _startGame() {
    setState(() {
      _view = AppView.game;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_engineReady) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _view == AppView.start
          ? StartScreen(
              onStart: _startGame,
              engine: _engine,
            )
          : AppRoot(), // AppRoot uses its own engine currently; OK for now.
    );
  }
}
