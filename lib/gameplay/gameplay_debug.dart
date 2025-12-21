import '../game/game_controller.dart';
import 'gameplay_world.dart';

/// Domain-only debug helpers.
/// Read-only. No Flutter. No Flame.
class GameplayDebug {
  static String status(GameController controller) {
    final world = controller.gameplayWorld;
    if (world == null) {
      return 'GameplayWorld: none';
    }

    final total = world.balloons.length;
    final popped = world.poppedCount;
    final types = world.balloons
        .map((b) => b.type.name)
        .toSet()
        .join(', ');

    return 'GameplayWorld: $total balloon(s), $popped popped [$types] | actions: popBalloonAt(index)';
  }
}
