import "../game/game_controller.dart";

/// GameplayDebug
///
/// Read-only debug helpers.
/// No mutation. No side effects.
class GameplayDebug {
  static String status(GameController controller) {
    final world = controller.gameplayWorld;
    if (world == null) {
      return "GameplayWorld: none";
    }

    final total = world.balloons.length;
    final popped = world.poppedCount;
    final hasAutoTarget =
        world.balloons.any((b) => !b.isPopped);

    return "GameplayWorld: $total balloon(s), "
        "$popped popped, "
        "autoPopAvailable=$hasAutoTarget";
  }
}
