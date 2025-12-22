import '../game/game_controller.dart';

/// CooldownUI (UI-only)
class CooldownUI {
  static bool isDisabled(GameController c) =>
      c.gameplayWorld?.powerUpOnCooldown ?? false;

  static String label(GameController c) =>
      isDisabled(c) ? 'Cooling down…' : 'Ready';
}
