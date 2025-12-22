/// RarityLabel (UI-only)
class RarityLabel {
  static String labelForScore(int score) {
    if (score >= 50) return 'Epic';
    if (score >= 20) return 'Rare';
    return 'Common';
  }
}
