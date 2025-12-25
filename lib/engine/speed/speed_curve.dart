import 'dart:math';

/// TapJunkie CORE SYSTEM
/// ---------------------
/// SpeedCurve maps progression (tier) into a scroll speed.
/// This is intentionally game-agnostic: "speed" could mean scroll velocity,
/// enemy velocity, spawn pacing, etc.
///
/// We keep the curve non-linear so high tiers feel dramatically different.
class SpeedCurve {
  final SpeedCurveConfig config;

  const SpeedCurve({SpeedCurveConfig? config})
      : config = config ?? const SpeedCurveConfig();

  /// Returns speed in "units per second" for a given tier (1..maxTier).
  double speedForTier(int tier) {
    final t = tier.clamp(1, config.maxTier);
    final tier01 = (t - 1) / max(1, (config.maxTier - 1));
    return speedForTier01(tier01);
  }

  /// Returns speed for a normalized tier [0..1].
  double speedForTier01(double tier01) {
    final x = tier01.clamp(0.0, 1.0);

    // Non-linear ramp: early tiers gentle, late tiers explosive.
    // curveExp > 1 makes the end steeper.
    final shaped = pow(x, config.curveExp).toDouble();

    // Base + shaped range.
    return config.minSpeed + shaped * (config.maxSpeed - config.minSpeed);
  }
}

class SpeedCurveConfig {
  final int maxTier;

  /// Speed range (units/sec). "Units" are defined by the scroller usage.
  final double minSpeed;
  final double maxSpeed;

  /// Shape exponent: higher = more explosive late tiers.
  final double curveExp;

  const SpeedCurveConfig({
    this.maxTier = 12,
    this.minSpeed = 40.0,
    this.maxSpeed = 240.0,
    this.curveExp = 2.4,
  });
}
