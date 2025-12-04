import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:tapjunkie_engine/tapjunkie_engine.dart';
import 'balloon_component.dart';

class BalloonBurstGame extends TJGame with TapDetector {
  final _rng = Random();
  late final Spawner spawner;

  BalloonBurstGame({required GameManager gameManager})
      : super(gameManager: gameManager);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    spawner = Spawner(
      gameManager: gameManager,
      difficultyManager: difficultyManager,
      onSpawn: _spawnBalloon,
    );

    add(spawner);
    gameManager.start();
  }

  void _spawnBalloon() {
    if (size.y == 0 || size.x == 0) return;

    final x = _rng.nextDouble() * size.x;
    final pos = Vector2(x, size.y + 120);
    add(BalloonComponent(startPosition: pos));
  }

  @override
  void onTapDown(TapDownInfo info) {
    final pos = info.eventPosition.game;
    for (final b in children.whereType<BalloonComponent>()) {
      if (b.hitTest(pos)) {
        b.pop();
        break;
      }
    }
  }
}
