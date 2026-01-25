/// Danger Rules (NON-ENDING)
/// ------------------------
/// These thresholds provide pressure via UX (visual/audio),
/// but NEVER end the run.
///
/// Sparkles Guidance:
/// - 8  → Warning
/// - 10 → Danger
/// - 15 → Max Danger
library danger_rules;

enum DangerLevel {
  none,
  warning,
  danger,
  maxDanger,
}

class DangerRules {
  static DangerLevel fromCounts({
    required int escapes,
    required int misses,
  }) {
    final maxCount = escapes > misses ? escapes : misses;

    if (maxCount >= 15) return DangerLevel.maxDanger;
    if (maxCount >= 10) return DangerLevel.danger;
    if (maxCount >= 8) return DangerLevel.warning;

    return DangerLevel.none;
  }
}
