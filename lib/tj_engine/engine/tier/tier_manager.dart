/// TJ Engine TierManager (façade)
/// - Keeps a stable API for all TapJunkie games
/// - Can later grow into tier-based rewards, unlock cadence, multipliers, etc.
class TierManager {
  TierManager._();

  static final TierManager instance = TierManager._();

  void reset() {
    // Placeholder for future tier progression reset.
  }
}

/// Global singleton instance (matches GameManager’s current usage).
final TierManager tierManager = TierManager.instance;
