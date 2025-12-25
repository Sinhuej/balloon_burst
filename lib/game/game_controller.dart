import '../gameplay/gameplay_world.dart';
import '../gameplay/balloon.dart';
import '../engine/momentum/momentum_controller.dart';

/// GameController
/// --------------
/// Owns the high-level game state and engine signals.
/// Momentum is wired here but not yet used for difficulty, speed, or tiers.
class GameController {
  GameplayWorld? gameplayWorld;

  /// TapJunkie core momentum signal (0..1).
  final MomentumController momentum = MomentumController();

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

    // Fresh run = fresh momentum
    momentum.reset();
  }

  /// Called every frame / tick by the game loop.
  void update(double dt) {
    momentum.update(dt);
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
