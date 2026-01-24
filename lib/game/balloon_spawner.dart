import 'dart:math';
import 'package:balloon_burst/gameplay/balloon.dart';
import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/debug/dev_flags.dart';

class BalloonSpawner {
  double _timer = 0.0;
  int _spawnCount = 0;

  double spawnInterval = 1.2;

  int totalPops = 0;
  int recentMisses = 0;
  int recentHits = 0;

  int _lastLoggedWorld = 1;

  static const int world2Pops = 50;
  static const int world3Pops = 150;
  static const int world4Pops = 350;

  static const Map<int, double> worldSpeedMultiplier = {
    1: 1.00,
    2: 1.25,
    3: 1.55,
    4: 1.90,
  };

  static const Map<int, double> worldSpawnInterval = {
    1: 1.20,
    2: 1.00,
    3: 0.85,
    4: 0.70,
  };

  static const double maxWorldRamp = 0.10;
  static const double maxMissSlowdown = 0.05;

  void update({
    required double dt,
    required int tier,
    required List<Balloon> balloons,
    required double viewportHeight,
  }) {
    final targetInterval =
        worldSpawnInterval[currentWorld] ?? spawnInterval;

    spawnInterval += (targetInterval - spawnInterval) * 0.05;
    _timer += dt;

    if (_timer >= spawnInterval) {
      _timer = 0.0;

      balloons.add(
        Balloon.spawnAt(
          _spawnCount,
          total: _spawnCount + 1,
          tier: tier,
          viewportHeight: viewportHeight,
        ),
      );

      _spawnCount++;
    }
  }

  void registerPop(GameState gameState) {
    totalPops++;
    recentHits++;
    recentMisses = max(0, recentMisses - 1);

    final w = currentWorld;
if (w != _lastLoggedWorld) {
  if (DevFlags.debugLogsEnabled) {
    gameState.log('WORLD CHANGE $_lastLoggedWorld → $w at pops=$totalPops');
    gameState.log('BG COLOR → ${_worldName(w)}');
  }
  _lastLoggedWorld = w;
}    
  }

  void registerMiss(GameState gameState) {
    recentMisses++;
    recentHits = max(0, recentHits - 1);

if (DevFlags.debugLogsEnabled) {
  gameState.log(
    'MISS recentMisses=$recentMisses '
    'accuracy=${accuracyModifier.toStringAsFixed(2)}',
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
      case 4:
        start = world4Pops;
        end = world4Pops + 200;
        break;
      default:
        start = 0;
        end = world2Pops;
    }

    if (end <= start) return 1.0;
    return ((totalPops - start) / (end - start)).clamp(0.0, 1.0);
  }

  double get accuracyModifier {
    if (recentMisses == 0) return 1.0;

    final missFactor =
        (recentMisses / (recentMisses + recentHits + 1))
            .clamp(0.0, 1.0);

    final slowdown = missFactor * maxMissSlowdown;
    return (1.0 - slowdown).clamp(1.0 - maxMissSlowdown, 1.0);
  }

  double get speedMultiplier {
    final worldMult =
        worldSpeedMultiplier[currentWorld] ?? 1.0;

    final ramp = 1.0 + (worldProgress * maxWorldRamp);
    return worldMult * ramp * accuracyModifier;
  }

  String _worldName(int w) {
    switch (w) {
      case 2:
        return 'Sky Blue';
      case 3:
        return 'Neon Purple';
      case 4:
        return 'Deep Space';
      default:
        return 'Dark Carnival';
    }
  }
}
