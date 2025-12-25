import '../gameplay/gameplay_world.dart';
import '../gameplay/balloon.dart';
import '../engine/momentum/momentum_controller.dart';
import '../engine/tier/tier_controller.dart';

/// GameController
/// --------------
/// Owns high-level game state and engine signals.
/// Momentum and Tier are wired but not yet used for gameplay.
class GameController {
  GameplayWorld? gameplayWorld;

  /// Core TapJunkie systems
  final MomentumController momentum = MomentumController();
  final TierController tier = TierController();

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
    tier.reset();
    _logTimer = 0.0;
  }

  /// Called every frame / tick by the game loop.
  void update(double dt) {
    momentum.update(dt);
    tier.update(momentum.momentum);

    // Temporary debug logging (safe, removable)
    _logTimer += dt;
    if (_logTimer >= 1.0) {
      _logTimer = 0.0;
      // ignore: avoid_print
      print(
        '[Progress] momentum=${momentum.momentum.toStringAsFixed(2)} '
        'tier=${tier.currentTier}',
      );
    }
  }

  /// Successful balloon hit.
  void onBalloonHit({double accuracyWeight = 1.0}) {
    momentum.registerTap(
      hit: true,
      accuracyWeight: accuracyWeight,
    );
  }

  /// Missed or incorrect tap.
  void onMiss() {
    momentum.registerTap(hit: false);
  }
}
