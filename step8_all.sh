#!/usr/bin/env bash
set -e

echo "🟢 Step 8: Creating gameplay placeholder shell"

# -------------------------------------------------------------------
# Step 8-1: GameplayWorld shell
# -------------------------------------------------------------------
mkdir -p lib/gameplay

cat > lib/gameplay/gameplay_world.dart <<'EOF'
/// GameplayWorld
///
/// Placeholder shell for future gameplay systems.
/// Intentionally contains no logic.
///
/// Step 8: First gameplay wiring
class GameplayWorld {
  GameplayWorld();
}
EOF

echo "✅ GameplayWorld created"

# -------------------------------------------------------------------
# Step 8-2: GameController wiring
# -------------------------------------------------------------------
cat > lib/game/game_controller.dart <<'EOF'
import '../gameplay/gameplay_world.dart';

enum GameState {
  idle,
  running,
  ended,
}

class GameController {
  GameState _state = GameState.idle;
  GameState get state => _state;

  GameplayWorld? gameplayWorld;

  void start() {
    _state = GameState.running;
    gameplayWorld = GameplayWorld();
  }

  void stop() {
    _state = GameState.ended;
    gameplayWorld = null;
  }

  void reset() {
    _state = GameState.idle;
    gameplayWorld = null;
  }
}
EOF

echo "✅ GameController updated"

# -------------------------------------------------------------------
# Step 8-3: GameScreen placeholder surfacing
# -------------------------------------------------------------------
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Game State: ${_controller.state.name}'),

            if (_controller.gameplayWorld != null)
              const Text('GameplayWorld: initialized'),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _controller.start();
                });
              },
              child: const Text('Start'),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _controller.stop();
                });
              },
              child: const Text('Stop'),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _controller.reset();
                });
              },
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}
EOF

echo "✅ GameScreen updated"

echo "🎯 Step 8 script completed successfully"
echo "⚠️ Recommend splitting commits manually if CI safety is critical"

