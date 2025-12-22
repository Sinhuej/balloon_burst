import '../gameplay/gameplay_world.dart';
import '../gameplay/difficulty_curve.dart';

/// SessionRules (pure)
class SessionRules {
  static bool isGameOver(GameplayWorld w) =>
      w.balloons.length > DifficultyCurve.maxBalloonsForScore(w.score);

  static bool isWin(GameplayWorld w) => w.score >= 100;
}
