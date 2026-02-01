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

  // 🔒 Wave control
  bool _waveActive = false;
  int _activeWaveCount = 0;

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

  // Burst behavior
  static const double burstChance = 0.35;
  static const double burstSpacingY = 26.0;

  void update({
    required double dt,
    required int tier,
    required List<Balloon> balloons,
    required double viewportHeight,
  }) {
    // 🔒 Lock wave until the screen is completely clear
    if (_waveActive) {
     if (balloons.isNotEmpty) {
      return;
    }
    _waveActive = false;
    _activeWaveCount = 0;
    _timer = 0.0;
   }

    final targetInterval =
        worldSpawnInterval[currentWorld] ?? spawnInterval;

    spawnInterval += (targetInterval - spawnInterval) * 0.05;
    _timer += dt;

    if (_timer >= spawnInterval) {
      _timer = 0.0;

      final bool doBurst = _rng.nextDouble() < burstChance;
      final int count =
          doBurst ? _burstCountForWorld(currentWorld) : 1;

      final List<BalloonType> types =
          _chooseTypesForGroup(count);

      _waveActive = true;
      _activeWaveCount = count;

      for (int i = 0; i < count; i++) {
        final int index = _spawnCount;

        final double spawnY =
            viewportHeight + burstSpacingY * (count - 1 - i);

        final Balloon b = Balloon.spawnAt(
          index,
          total: index + 1,
          tier: tier,
          viewportHeight: spawnY,
          type: types[i],
        );

        balloons.add(b);
        _spawnCount++;
      }
    }
  }

  int _burstCountForWorld(int world) {
    if (world <= 1) return 2;
    return (_rng.nextDouble() < 0.70) ? 2 : 3;
  }

  List<BalloonType> _chooseTypesForGroup(int count) {
    if (count <= 1) {
      return [_chooseBalloonType()];
    }

    final List<BalloonType> out =
        List.filled(count, BalloonType.standard);

    out[0] = BalloonType.standard;

    bool hasLargeSlow = false;

    for (int i = 1; i < count; i++) {
      final BalloonType t = _chooseBalloonType();

      if (t == BalloonType.largeSlow) {
        if (hasLargeSlow) {
          out[i] = BalloonType.standard;
        } else {
          out[i] = BalloonType.largeSlow;
          hasLargeSlow = true;
        }
      } else {
        out[i] = t;
      }
    }

    out.shuffle(_rng);
    return out;
  }

  BalloonType _chooseBalloonType() {
    final entries = balloonTypeConfig.entries.toList();
    final totalWeight =
        entries.fold<double>(0, (s, e) => s + e.value.spawnWeight);

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

    return ((totalPops - start) / (end - start))
        .clamp(0.0, 1.0);
  }

  double get accuracyModifier {
    if (recentMisses == 0) return 1.0;

    final missFactor =
        (recentMisses / (recentMisses + recentHits + 1))
            .clamp(0.0, 1.0);

    final slowdown = missFactor * maxMissSlowdown;
    return (1.0 - slowdown)
        .clamp(1.0 - maxMissSlowdown, 1.0);
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

  void resetForNewRun() {
    _timer = 0.0;
    _spawnCount = 0;
    spawnInterval = worldSpawnInterval[1]!;

    totalPops = 0;
    _lastLoggedWorld = 1;
    recentHits = 0;
    recentMisses = 0;

    _waveActive = false;
    _activeWaveCount = 0;
  }
}
