// lib/engine/core/spawner.dart

import 'package:flame/components.dart';

import 'tj_game.dart';
import 'game_manager.dart';
import 'difficulty_manager.dart';
import 'states.dart';

// TapJunkie progression systems
import '../tier/tier_manager.dart';

/// Generic timed spawner that calls [onSpawn] according to difficulty
/// AND TapJunkie Rising Worlds tier progression.
///
/// Attach this to a [TJGame] and plug in your own spawn callback.
class Spawner extends Component with HasGameRef<TJGame> {
  final GameManager gameManager;
  final DifficultyManager difficultyManager;
  final void Function() onSpawn;

  double _timer = 0;

  Spawner({
    required this.gameManager,
    required this.difficultyManager,
    required this.onSpawn,
  });

  @override
  void update(double dt) {
    super.update(dt);

    // Only spawn while actively playing.
    if (gameManager.state != GameState.playing) {
      return;
    }

    // Let base difficulty track elapsed time.
    difficultyManager.update(dt);

    // Get current tier-based spawn multiplier
    final tierMultiplier = tierManager.currentTier.spawnRateMultiplier;

    // Advance spawn timer with tier scaling applied
    _timer += dt * tierMultiplier;

    // When timer exceeds current difficulty interval, spawn
    if (_timer >= difficultyManager.spawnInterval) {
      _timer = 0;
      onSpawn();
    }
  }
}

