import '../game/game_controller.dart';
import 'balloon.dart';

/// Domain-only debug helpers.
/// Read-only. No Flutter. No Flame.
class GameplayDebug {
  static String status(GameController controller) {
    final world = controller.gameplayWorld;
    if (world == null) {
      return 'GameplayWorld: none';
    }

    final count = world.balloons.length;
    final types = world.balloons
        .map((b) => b.type.name)
        .toSet()
        .join(', ');

    return 'GameplayWorld: $count balloon(s) [$types]';
  }
}
