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

  // Vertical stacking on entry (fine to keep)
  static const double burstSpacingY = 26.0;

  // Cluster feel (tune these)
  // Internal cluster spacing (between balloons inside the same cluster)
  static const double clusterSpread = 0.12; // try 0.10..0.16 with big counts
  static const double clusterJitter = 0.02; // tiny randomness per balloon

  // How far across the bottom clusters can originate (xOffset space)
  // Bigger = more left/right starts.
  static const double clusterOriginRangeWorld1 = 0.46;
  static const double clusterOriginRangeWorld2Plus = 0.52;

  // Clamp overall xOffset so balloons don't hug edges too hard
  static const double xClamp = 0.58;

  void update({
    required double dt,
    required int tier,
    required List<Balloon> balloons,
    required double viewportHeight,
  }) {
    // 🔒 Lock wave until no ACTIVE balloons remain (popped balloons don't block)
    if (_waveActive) {
      final hasActiveBalloon = balloons.any((b) => !b.isPopped);
      if (hasActiveBalloon) return;

      _waveActive = false;
      _timer = 0.0;
    }

    final targetInterval = worldSpawnInterval[currentWorld] ?? spawnInterval;

    spawnInterval += (targetInterval - spawnInterval) * 0.05;
    _timer += dt;

    if (_timer < spawnInterval) return;
    _timer = 0.0;

    // ✅ Frequency of clusters by world (World 1 gets more than before, scales up)
    final double burstChance = _burstChanceForWorld(currentWorld);

    final bool doBurst = _rng.nextDouble() < burstChance;
    final int count = doBurst ? _burstCountForWorld(currentWorld) : 1;

    final List<BalloonType> types = _chooseTypesForGroup(count);

    // ✅ Choose a cluster origin across the bottom (not just near center)
    final double originRange = (currentWorld <= 1)
        ? clusterOriginRangeWorld1
        : clusterOriginRangeWorld2Plus;

    final double clusterCenterX = (_rng.nextDouble() * 2 - 1) * originRange;

    // Offsets that stay centered for any count (2..6)
    final List<double> xOffsets = _xOffsetsForCount(count);

    _waveActive = true;

    for (int i = 0; i < count; i++) {
      final int index = _spawnCount;
      _spawnCount++;

      final double spawnY = viewportHeight + burstSpacingY * (count - 1 - i);

      final double jitter = (_rng.nextDouble() * 2 - 1) * clusterJitter;
      final double x =
          (clusterCenterX + xOffsets[i] + jitter).clamp(-xClamp, xClamp);

      final Balloon b = Balloon(
        id: 'balloon_$index',
        y: spawnY,
        xOffset: x,
        baseXOffset: x,
        phase: _rng.nextDouble() * pi * 2,
        type: types[i],
      );

      balloons.add(b);
    }
  }

  // ✅ Tune cluster frequency here
  double _burstChanceForWorld(int world) {
    switch (world) {
      case 1:
        return 0.40; // more clusters than before
      case 2:
        return 0.50;
      case 3:
        return 0.58;
      case 4:
        return 0.62;
      default:
        return 0.50;
    }
  }

  // ✅ Tune cluster size here (your requested targets)
  int _burstCountForWorld(int world) {
    switch (world) {
      case 1:
        return 3;
      case 2:
        return 4;
      case 3:
        return 5;
      case 4:
        return 6;
      default:
        return 4;
    }
  }

  // Centered offsets: [-k..+k] * clusterSpread (works for any count)
  List<double> _xOffsetsForCount(int count) {
    if (count <= 1) return const [0.0];

    final double mid = (count - 1) / 2.0;
    final List<double> out = <double>[];

    for (int i = 0; i < count; i++) {
      out.add((i - mid) * clusterSpread);
    }

    // Shuffle slightly so formations don't always look perfectly ordered
    // (keeps "escaped carnival" vibe without changing overall shape)
    out.shuffle(_rng);
    return out;
  }

  List<BalloonType> _chooseTypesForGroup(int count) {
    if (count <= 1) {
      return [_chooseBalloonType()];
    }

    final List<BalloonType> out = List.filled(count, BalloonType.standard);

    // Guarantee at least one standard
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

    return ((totalPops - start) / (end - start)).clamp(0.0, 1.0);
  }

  double get accuracyModifier {
    if (recentMisses == 0) return 1.0;

    final missFactor =
        (recentMisses / (recentMisses + recentHits + 1)).clamp(0.0, 1.0);

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

    _waveActive = false;
  }
}
