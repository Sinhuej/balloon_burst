import 'package:balloon_burst/gameplay/balloon.dart';

/// Simple Flutter-only spawner.
/// Replaces Flame-based Spawner for the active game loop.
class BalloonSpawner {
  double _timer = 0.0;
  int _spawnCount = 0;

  // Conservative starting interval (seconds)
  double spawnInterval = 1.2;

  void update({
    required double dt,
    required int tier,
    required List<Balloon> balloons,
  }) {
    _timer += dt;

    if (_timer >= spawnInterval) {
      _timer = 0.0;

      final balloon = Balloon.spawnAt(
        _spawnCount,
        total: _spawnCount + 1,
        tier: tier,
      );

      balloons.add(balloon);
      _spawnCount++;
    }
  }

  void reset() {
    _timer = 0.0;
    _spawnCount = 0;
  }
}
