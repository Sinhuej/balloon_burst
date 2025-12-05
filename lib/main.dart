import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:tapjunkie_engine/tapjunkie_engine.dart';

import 'balloon_burst_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Create the game manager FIRST
  final gameManager = GameManager();

  // Pass the manager into the game
  final game = BalloonBurstGame(gameManager: gameManager);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameWidget(
          game: game,

          // Enables overlays from TapJunkie Engine
          overlayBuilderMap: {
            'gameOver': (_, game) => _GameOverOverlay(game),
            'mainMenu': (_, game) => _MainMenuOverlay(game),
          },
        ),
      ),
    ),
  );
}

class _MainMenuOverlay extends StatelessWidget {
  final BalloonBurstGame game;

  const _MainMenuOverlay(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        child: const Text("Start Game"),
        onPressed: () {
          game.gameManager.start();
          game.overlays.remove('mainMenu');
        },
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final BalloonBurstGame game;

  const _GameOverOverlay(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        child: const Text("Game Over — Restart"),
        onPressed: () {
          game.gameManager.restart();
          game.overlays.remove('gameOver');
        },
      ),
    );
  }
}
