import '../game/game_controller.dart';

/// Domain-only debug helpers.
/// Intentionally contains no Flutter or Flame references.
class GameplayDebug {
  static String status(GameController controller) {
    if (controller.gameplayWorld == null) {
      return 'GameplayWorld: none';
    }

    return 'GameplayWorld: initialized (1 balloon)';
  }
}
