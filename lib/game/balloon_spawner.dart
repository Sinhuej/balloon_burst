import 'dart:math';
import 'package:balloon_burst/gameplay/balloon.dart';
import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/game/balloon_type.dart';

class BalloonSpawner {
  double _timer = 0.0;
  int _spawnCount = 0;
  final Random _rng = Random();

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

  // Step 3: Burst spawning (Option A: occasional drama)
  // - Sometimes spawn 2–3 balloons at once
  // - Creates layered overlap moments
  // - Fairness rules prevent "unavoidable" clusters
  static const double burstChance = 0.35; // 35% burst, 65% single

  // Spacing within a burst (in world units; affects how stacked they feel)
  static const double burstSpacingY = 26.0;

  void update({
    required double dt,
    required int tier,
    required List<Balloon> balloons,
    required double viewportHeight,
  }) {
    final targetInterval = worldSpawnInterval[currentWorld] ?? spawnInterval;

    // Smoothly converge toward target interval
    spawnInterval += (targetInterval - spawnInterval) * 0.05;

    _timer += dt;

    if (_timer >= spawnInterval) {
      _timer = 0.0;

      final bool doBurst = _rng.nextDouble() < burstChance;
      final int count = doBurst ? _burstCountForWorld(currentWorld) : 1;

      // Choose types for this spawn group with fairness guarantees.
      final List<BalloonType> types = _chooseTypesForGroup(count);

      for (int i = 0; i < count; i++) {
        final int index = _spawnCount;

        // Spawn below screen with a slight extra offset so burst members
        // are stacked (creates overlap / choice moments).
        final Balloon b = Balloon.spawnAt(
          index,
          total: index + 1,
          tier: tier,
          viewportHeight: viewportHeight + (i * burstSpacingY),
          type: types[i],
        );

        balloons.add(b);
        _spawnCount++;
      }
    }
  }

  int _burstCountForWorld(int world) {
    // World 1: mostly 2-bursts (teaches layering gently)
    // World 2+: mix of 2 and 3
    if (world <= 1) return 2;

    // 70% chance 2, 30% chance 3
    return (_rng.nextDouble() < 0.70) ? 2 : 3;
  }

  List<BalloonType> _chooseTypesForGroup(int count) {
    // Fairness rules:
    // - At least 1 standard
    // - Max 1 foreground
    // - Remaining slots can be background/standard based on weights
    if (count <= 1) {
      return [_chooseBalloonType()];
    }

    final List<BalloonType> out = List.filled(count, BalloonType.standard);

    // Guarantee one standard somewhere (keeps run readable + tappable)
    out[0] = BalloonType.standard;

    bool hasForeground = false;

    for (int i = 1; i < count; i++) {
      final BalloonType t = _chooseBalloonType();

      // Clamp foreground to max 1 per group
      if (t == BalloonType.foreground) {
        if (hasForeground) {
          out[i] = BalloonType.standard;
        } else {
          out[i] = BalloonType.foreground;
          hasForeground = true;
        }
      } else {
        out[i] = t;
      }
    }

    // Shuffle so the guaranteed standard isn't always the first
    out.shuffle(_rng);

    // Ensure at least one standard remains after shuffle (should always be true)
    if (!out.contains(BalloonType.standard)) {
      out[0] = BalloonType.standard;
    }

    return out;
  }

  BalloonType _chooseBalloonType() {
    final entries = balloonTypeConfig.entries.toList();
    final totalWeight =
        entries.fold<double>(0, (sum, e) => sum + e.value.spawnWeight);

    double roll = _rng.nextDouble() * totalWeight;

    for (final e in entries) {
      roll -= e.value.spawnWeight;
      if (roll <= 0) return e.key;
    }

    return BalloonType.standard;
  }

  void registerPop(GameState gameState) {
    totalPops++;
    recentHits++;
    recentMisses = max(0, recentMisses - 1);

    final w = currentWorld;
    if (w != _lastLoggedWorld) {
      gameState.log(
        'WORLD CHANGE $_lastLoggedWorld → $w at pops=$totalPops',
      );
      gameState.log(
        'BG COLOR → ${_worldName(w)}',
      );
      _lastLoggedWorld = w;
    }
  }

  void registerMiss(GameState gameState) {
    recentMisses++;
    recentHits = max(0, recentHits - 1);

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
    final worldMult = worldSpeedMultiplier[currentWorld] ?? 1.0;
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

  void resetForNewRun() {
    _timer = 0.0;
    _spawnCount = 0;
    spawnInterval = worldSpawnInterval[1]!;

    totalPops = 0;
    _lastLoggedWorld = 1;

    recentHits = 0;
    recentMisses = 0;
  }
}
