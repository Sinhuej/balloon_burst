#!/bin/sh
set -e

echo "🚀 Setting up Start Screen + Game Flow"

# ----------------------------
# App State
# ----------------------------
mkdir -p lib/state
cat > lib/state/app_state.dart <<'EOF'
enum AppView {
  start,
  game,
}
EOF

# ----------------------------
# Start Screen
# ----------------------------
mkdir -p lib/screens
cat > lib/screens/start_screen.dart <<'EOF'
import 'package:flutter/material.dart';
import '../state/app_state.dart';

class StartScreen extends StatelessWidget {
  final void Function() onStart;

  const StartScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: onStart,
          child: const Text('START'),
        ),
      ),
    );
  }
}
EOF

# ----------------------------
# Update main.dart
# ----------------------------
cat > lib/main.dart <<'EOF'
import 'package:flutter/material.dart';
import 'state/app_state.dart';
import 'screens/start_screen.dart';
import 'screens/game_screen.dart';

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
      home: _view == AppView.start
          ? StartScreen(onStart: _startGame)
          : const GameScreen(),
    );
  }
}
EOF

# ----------------------------
# Update GameScreen
# ----------------------------
cat > lib/screens/game_screen.dart <<'EOF'
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
EOF

echo "✅ Start flow installed"

