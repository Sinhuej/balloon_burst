import 'dart:math';
import 'package:balloon_burst/gameplay/balloon.dart';
import 'package:balloon_burst/game/game_state.dart';

class BalloonSpawner {
  double _timer = 0.0;

  int totalPops = 0;
  int recentMisses = 0;

  static const int world2Pops = 50;
  static const int world3Pops = 150;
  static const int world4Pops = 350;

  static const double spawnInterval = 1.2;

  static const Map<int, double> worldSpawnInterval = {
    1: 1.20,
    2: 1.00,
    3: 0.85,
    4: 0.70,
  };

  static const Map<int, double> worldSpeedMultiplier = {
    1: 1.00,
    2: 1.25,
    3: 1.55,
    4: 1.90,
  };

  void update({
    required double dt,
    required int tier,
    required List<Balloon> balloons,
    required double viewportHeight,
  }) {
    _timer += dt;

    final interval =
        worldSpawnInterval[currentWorld] ?? spawnInterval;

    if (_timer >= interval) {
      _timer = 0.0;
      balloons.add(Balloon(viewportHeight));
    }
  }

  void registerHit(GameState gameState) {
    totalPops++;
    recentMisses = max(0, recentMisses - 1);

    final w = currentWorld;
    gameState.log('WORLD CHANGE → $w at pops=$totalPops');
  }

  void registerMiss(GameState gameState) {
    recentMisses++;
    gameState.log(
      'MISS recentMisses=$recentMisses accuracy=${accuracyModifier.toStringAsFixed(2)}',
    );
  }

  int get currentWorld {
    if (totalPops >= world4Pops) return 4;
    if (totalPops >= world3Pops) return 3;
    if (totalPops >= world2Pops) return 2;
    return 1;
  }

  double get worldProgress {
    int start;
    int end;

    switch (currentWorld) {
      case 2:
        start = world2Pops;
        end = world3Pops;
        break;
      case 3:
        start = world3Pops;
        end = world4Pops;
        break;
      default:
        return 0.0;
    }

    if (end <= start) return 1.0;
    return ((totalPops - start) / (end - start))
        .clamp(0.0, 1.0);
  }

  double get accuracyModifier {
    if (recentMisses == 0) return 1.0;
    const maxMissSlowdown = 0.35;
    final slowdown = min(recentMisses * 0.05, maxMissSlowdown);
    return (1.0 - slowdown).clamp(0.65, 1.0);
  }

  double get speedMultiplier {
    final worldMult =
        worldSpeedMultiplier[currentWorld] ?? 1.0;
    final ramp = 1.0 + (worldProgress * 0.25);
    return worldMult * ramp * accuracyModifier;
  }
}

  double get spawnIntervalValue =>
      worldSpawnInterval[currentWorld] ?? spawnInterval;
