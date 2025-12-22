import '../game/game_controller.dart';

/// VisualFeedback (UI-only)
/// Derived, stateless helpers for feedback text.
class VisualFeedback {
  static String popLabel(GameController c) {
    final w = c.gameplayWorld;
    if (w == null) return '';
    if (w.powerUpOnCooldown) return 'COOLDOWN';
    if (w.poppedCount >= 2) return 'COMBO!';
    if (w.poppedCount == 1) return 'POP!';
    return '';
  }
}
