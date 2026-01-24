import 'package:balloon_burst/gameplay/balloon.dart';
import 'package:balloon_burst/game/game_state.dart';

class BalloonSpawner {
  double _timer = 0.0;
  int _spawnIndex = 0;

  int totalPops = 0;
  int recentMisses = 0;

  static const double baseSpawnInterval = 1.2;

  static const int world2Pops = 50;
  static const int world3Pops = 150;
  static const int world4Pops = 350;

  static const Map<int, double> worldSpawnInterval = {
    1: 1.20,
    2: 1.00,
    3: 0.85,
    4: 0.70,
  };

  int get currentWorld {
    if (totalPops >= world4Pops) return 4;
    if (totalPops >= world3Pops) return 3;
    if (totalPops >= world2Pops) return 2;
    return 1;
  }

  double get spawnIntervalValue =>
      worldSpawnInterval[currentWorld] ?? baseSpawnInterval;

  void update({
    required double dt,
    required double viewportHeight,
    required List<Balloon> balloons,
  }) {
    _timer += dt;

    if (_timer >= spawnIntervalValue) {
      _timer = 0.0;

      balloons.add(
        Balloon.spawnAt(
          _spawnIndex++,
          total: totalPops,
          tier: currentWorld,
          viewportHeight: viewportHeight,
        ),
      );
    }
  }

  void registerHit(GameState gameState) {
    totalPops++;
    recentMisses = recentMisses > 0 ? recentMisses - 1 : 0;
  }

  void registerMiss(GameState gameState) {
    recentMisses++;
  }
}
