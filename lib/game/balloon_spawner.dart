import 'package:balloon_burst/gameplay/balloon.dart';

/// Simple Flutter-only spawner.
/// Rising Worlds version: balloons spawn below viewport.
class BalloonSpawner {
  double _timer = 0.0;
  int _spawnCount = 0;

  // Conservative starting interval (seconds)
  double spawnInterval = 1.2;

  void update({
    required double dt,
    required int tier,
    required List<Balloon> balloons,
    required double viewportHeight,
  }) {
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

  void reset() {
    _timer = 0.0;
    _spawnCount = 0;
  }
}
