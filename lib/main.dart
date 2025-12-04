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
      home: Scaffold(
        body: GameWidget(game: game),
      ),
    ),
  );
}
