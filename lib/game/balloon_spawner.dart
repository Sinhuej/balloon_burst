import 'dart:math';

import 'package:balloon_burst/gameplay/balloon.dart';

class BalloonSpawner {
  double _timer = 0.0;
  int _spawnCount = 0;

  int totalPops = 0;
  int recentMisses = 0;
  int recentHits = 0;

  int _lastLoggedWorld = 1;

  // World thresholds (pops)
  static const int world2Pops = 50;
  static const int world3Pops = 150;
  static const int world4Pops = 350;

  // Base spawn timing
  static const double _baseSpawnInterval = 1.2;

  // World-based spawn interval (lower = faster spawns)
  static const Map<int, double> worldSpawnInterval = {
    1: 1.20,
    2: 1.00,
    3: 0.85,
    4: 0.70,
  };

  // World-based speed multiplier
  static const Map<int, double> worldSpeedMultiplier = {
    1: 1.00,
    2: 1.25,
    3: 1.55,
    4: 1.90,
  };

  // How much "ramp" happens inside a world
  static const double _maxWorldRamp = 0.20;

  int get currentWorld {
    if (totalPops >= world4Pops) return 4;
    if (totalPops >= world3Pops) return 3;
    if (totalPops >= world2Pops) return 2;
    return 1;
  }

  double get worldProgress {
    final w = currentWorld;

    int start;
    int end;

    switch (w) {
      case 1:
        start = 0;
        end = world2Pops;
        break;
      case 2:
        start = world2Pops;
        end = world3Pops;
        break;
      case 3:
        start = world3Pops;
        end = world4Pops;
        break;
      default:
        return 1.0;
    }

    if (end <= start) return 1.0;
    return ((totalPops - start) / (end - start)).clamp(0.0, 1.0);
  }

  /// Telemetry-only accuracy modifier (NO gameplay effect)
  double get accuracyModifier {
    if (recentMisses <= 0) return 1.0;
    final penalty = (recentMisses * 0.04).clamp(0.0, 0.25);
    return (1.0 - penalty).clamp(0.75, 1.0);
  }

  /// Used by GameScreen to scale rise speed.
  /// NOTE: Accuracy does NOT affect motion.
  double get speedMultiplier {
    final worldMult = worldSpeedMultiplier[currentWorld] ?? 1.0;
    final ramp = 1.0 + (worldProgress * _maxWorldRamp);
    return worldMult * ramp;
  }

  double get spawnIntervalValue {
    return worldSpawnInterval[currentWorld] ?? _baseSpawnInterval;
  }

  void registerHit() {
    totalPops++;
    recentHits++;
    recentMisses = max(0, recentMisses - 1);
  }

  void registerMiss() {
    recentMisses++;
    recentHits = max(0, recentHits - 1);
  }

  void update({
    required double dt,
    required double viewportHeight,
    required List<Balloon> balloons,
    int tier = 0,
  }) {
    _timer += dt;
    final interval = spawnIntervalValue;

    while (_timer >= interval) {
      _timer -= interval;
      final spawnIndex = _spawnCount++;

      balloons.add(
        Balloon.spawnAt(
          spawnIndex,
          total: 1,
          tier: tier,
          viewportHeight: viewportHeight,
        ),
      );
    }

    final w = currentWorld;
    if (w != _lastLoggedWorld) {
      _lastLoggedWorld = w;
    }
  }
}
