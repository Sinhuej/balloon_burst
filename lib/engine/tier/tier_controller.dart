/// TapJunkie CORE SYSTEM
/// ---------------------
/// TierController converts a continuous momentum signal (0..1)
/// into a discrete progression tier (1..maxTier).
///
/// Design goals:
/// - Tier 12 is mythic (top ~1–3%)
/// - No flickering (hysteresis)
/// - Engine-level, reusable across games
class TierController {
  final TierConfig config;

  int _currentTier = 1;

  TierController({TierConfig? config})
      : config = config ?? const TierConfig();

  /// Current discrete tier (1..maxTier).
  int get currentTier => _currentTier;

  /// Normalized tier position (0..1).
  double get tier01 =>
      (_currentTier - 1) / (config.maxTier - 1);

  /// Update tier based on current momentum (0..1).
  void update(double momentum01) {
    final targetTier = _tierFromMomentum(momentum01);

    if (targetTier > _currentTier) {
      // Promote only if momentum clears upper hysteresis
      if (momentum01 >= _promotionThreshold(_currentTier)) {
        _currentTier = targetTier;
      }
    } else if (targetTier < _currentTier) {
      // Demote only if momentum falls below lower hysteresis
      if (momentum01 <= _demotionThreshold(_currentTier)) {
        _currentTier = targetTier;
      }
    }
  }

  void reset() {
    _currentTier = 1;
  }

  int _tierFromMomentum(double m) {
    final clamped = m.clamp(0.0, 1.0);
    for (int i = 0; i < config.thresholds.length; i++) {
      if (clamped < config.thresholds[i]) {
        return i + 1;
      }
    }
    return config.maxTier;
  }

  double _promotionThreshold(int tier) {
    final idx = (tier - 1).clamp(0, config.thresholds.length - 1);
    return (config.thresholds[idx] + config.hysteresisUp)
        .clamp(0.0, 1.0);
  }

  double _demotionThreshold(int tier) {
    final idx = (tier - 2).clamp(0, config.thresholds.length - 1);
    return (config.thresholds[idx] - config.hysteresisDown)
        .clamp(0.0, 1.0);
  }
}

/// Configuration defining how momentum maps to tiers.
///
/// Thresholds represent the *entry point* to the next tier.
/// Example:
/// - Tier 1: < thresholds[0]
/// - Tier 2: >= thresholds[0] and < thresholds[1]
/// ...
class TierConfig {
  final int maxTier;

  /// Ascending thresholds (length = maxTier - 1).
  final List<double> thresholds;

  /// Hysteresis values to prevent flicker.
  final double hysteresisUp;
  final double hysteresisDown;

  const TierConfig({
    this.maxTier = 12,
    this.thresholds = const [
      0.08, // Tier 2
      0.16, // Tier 3
      0.25, // Tier 4
      0.34, // Tier 5
      0.44, // Tier 6
      0.55, // Tier 7
      0.66, // Tier 8
      0.75, // Tier 9
      0.83, // Tier 10
      0.90, // Tier 11
      0.96, // Tier 12 (mythic)
    ],
    this.hysteresisUp = 0.015,
    this.hysteresisDown = 0.030,
  });
}
