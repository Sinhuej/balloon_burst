import 'dart:math';
import 'package:balloon_burst/gameplay/balloon.dart';

/// BalloonSpawner
///
/// Rising Worlds v1:
/// - World-aware spawn density
/// - World-aware speed multipliers (read-only)
/// - Spawns balloons below the viewport
///
/// TJ-30 rules:
/// - No new mechanics
/// - No randomness added
/// - No refactors
class BalloonSpawner {
  double _timer = 0.0;
  int _spawnCount = 0;

  // --- BASE SPAWN INTERVAL (World 1) ---
  double spawnInterval = 1.2;

  // --- RISING WORLDS STATE ---
  int totalPops = 0;
  int recentMisses = 0;
  int recentHits = 0;

  // --- WORLD POP THRESHOLDS ---
  static const int world2Pops = 50;
  static const int world3Pops = 150;
  static const int world4Pops = 350;

  // --- WORLD SPEED MULTIPLIERS ---
  static const Map<int, double> worldSpeedMultiplier = {
    1: 1.00,
    2: 1.25,
    3: 1.55,
    4: 1.90,
  };

  // --- WORLD SPAWN INTERVALS ---
  static const Map<int, double> worldSpawnInterval = {
    1: 1.20, // Carnival Ascent
    2: 1.00, // Skyflare Reach
    3: 0.85, // Chroma Lift
    4: 0.70, // Ascension Run
  };

  // --- INTRA-WORLD RAMP ---
  static const double maxWorldRamp = 0.10;

  // --- MISS SLOWDOWN ---
  static const double maxMissSlowdown = 0.05;

  /// Called every frame to possibly spawn balloons.
  void update({
    required double dt,
    required int tier,
    required List<Balloon> balloons,
    required double viewportHeight,
  }) {
    // Smoothly adjust spawn interval toward current world target
    final targetInterval =
        worldSpawnInterval[currentWorld] ?? spawnInterval;

    spawnInterval += (targetInterval - spawnInterval) * 0.05;

    _timer += dt;

    if (_timer >= spawnInterval) {
      _timer = 0.0;

      final balloon = Balloon.spawnAt(
        _spawnCount,
        total: _spawnCount + 1,
        tier: tier,
        viewportHeight: viewportHeight,
      );

      balloons.add(balloon);
      _spawnCount++;
    }
  }

  // ---------------------------------------------------------------------------
  // Rising Worlds logic (unchanged)
  // ---------------------------------------------------------------------------

  void registerPop() {
    totalPops++;
    recentHits++;
    recentMisses = max(0, recentMisses - 1);
  }

  void registerMiss() {
    recentMisses++;
    recentHits = max(0, recentHits - 1);
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
}
