/// DifficultyCurve (pure)
class DifficultyCurve {
  static int maxBalloonsForScore(int score) {
    if (score >= 50) return 5;
    if (score >= 20) return 4;
    return 3;
  }
}
