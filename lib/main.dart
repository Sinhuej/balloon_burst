import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:tapjunkie_engine/tapjunkie_engine.dart';

import 'balloon_burst_game.dart';

void main() {
  final gm = GameManager();
  final game = BalloonBurstGame(gameManager: gm);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameWidget(
        game: game,
        overlayBuilderMap: {
          'gameOver': (context, g) => _GameOverOverlay(g as BalloonBurstGame),
          'mainMenu': (context, g) => _MainMenuOverlay(g as BalloonBurstGame),
        },
      ),
    ),
  );
}

class _GameOverOverlay extends StatelessWidget {
  final BalloonBurstGame game;
  const _GameOverOverlay(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Game Over", style: TextStyle(fontSize: 32)),
          ElevatedButton(
            onPressed: () {
              game.gameManager.restart();
              game.overlays.remove('gameOver');
            },
            child: const Text("Restart"),
          ),
        ],
      ),
    );
  }
}

class _MainMenuOverlay extends StatelessWidget {
  final BalloonBurstGame game;
  const _MainMenuOverlay(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          game.gameManager.start();
          game.overlays.remove('mainMenu');
        },
        child: const Text("Start Game"),
      ),
    );
  }
}
