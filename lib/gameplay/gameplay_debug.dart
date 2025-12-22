import "../game/game_controller.dart";

class GameplayDebug {
  static String status(GameController c) {
    final w = c.gameplayWorld;
    if (w == null) return "GameplayWorld: none";

    final next =
        w.suggestedCommands.isEmpty ? "none" : w.suggestedCommands.first.runtimeType.toString();

    return "balloons=${w.balloons.length}, "
        "popped=${w.poppedCount}, "
        "score=${w.score}, "
        "cooldown=${w.powerUpOnCooldown}, "
        "next=$next";
  }
}
