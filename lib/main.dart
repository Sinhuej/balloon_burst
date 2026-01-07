import 'package:flutter/material.dart';

import 'state/app_state.dart';
import 'screens/start_screen.dart';
import 'app_root.dart';

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

  void _startGame() {
    setState(() {
      _view = AppView.game;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _view == AppView.start
          ? StartScreen(onStart: _startGame)
          : AppRoot(), // ✅ non-const StatefulWidget
    );
  }
}
