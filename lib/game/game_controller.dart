import '../gameplay/gameplay_world.dart';
import '../gameplay/balloon.dart';
import '../engine/momentum/momentum_controller.dart';

/// GameController
/// --------------
/// Owns the high-level game state and engine signals.
/// Momentum is wired here and logged for validation only.
class GameController {
  GameplayWorld? gameplayWorld;

  /// TapJunkie core momentum signal (0..1).
  final MomentumController momentum = MomentumController();

  double _logTimer = 0.0;

  void start() {
    final List<Balloon> balloons = List.generate(
      5,
      (i) => Balloon(
        id: 'balloon_$i',
      ),
    );

    gameplayWorld = GameplayWorld(
      balloons: balloons,
    );

    momentum.reset();
    _logTimer = 0.0;
  }

  /// Called every frame / tick by the game loop.
  void update(double dt) {
    momentum.update(dt);

    // Debug logging once per second (temporary, safe)
    _logTimer += dt;
    if (_logTimer >= 1.0) {
      _logTimer = 0.0;
      // ignore: avoid_print
      print(
        '[Momentum] value=${momentum.momentum.toStringAsFixed(2)} '
        'rate=${momentum.tapRate01.toStringAsFixed(2)} '
        'acc=${momentum.accuracy01.toStringAsFixed(2)}',
      );
    }
  }

  /// Call when the player successfully pops a balloon.
  void onBalloonHit({double accuracyWeight = 1.0}) {
    momentum.registerTap(
      hit: true,
      accuracyWeight: accuracyWeight,
    );
  }

  /// Call when the player taps incorrectly or misses.
  void onMiss() {
    momentum.registerTap(hit: false);
  }
}
