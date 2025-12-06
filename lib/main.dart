import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:tapjunkie_engine/tapjunkie_engine.dart';

import 'balloon_burst_game.dart';

void main() {
  final gameManager = GameManager();
  final game = BalloonBurstGame(gameManager: gameManager);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameWidget(
          game: game,
          overlayBuilderMap: {
            'mainMenu': (_, __) => _MainMenuOverlay(game),
            'gameOver': (_, __) => _GameOverOverlay(game),
          },
        ),
      ),
    ),
  );
}

/// --------------------------------------------------------------
/// MAIN MENU OVERLAY
/// --------------------------------------------------------------

class _MainMenuOverlay extends StatelessWidget {
  final BalloonBurstGame game;
  const _MainMenuOverlay(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: ElevatedButton(
          onPressed: () {
            game.gameManager.start();
            game.overlays.remove('mainMenu');
          },
          child: const Text(
            "START",
            style: TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }
}

/// --------------------------------------------------------------
/// GAME OVER OVERLAY
/// --------------------------------------------------------------

class _GameOverOverlay extends StatelessWidget {
  final BalloonBurstGame game;
  const _GameOverOverlay(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "GAME OVER",
              style: TextStyle(
                fontSize: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                game.gameManager.restart();
                game.overlays.remove('gameOver');
              },
              child: const Text(
                "RESTART",
                style: TextStyle(fontSize: 28),
              ),
            )
          ],
        ),
      ),
    );
  }
}

