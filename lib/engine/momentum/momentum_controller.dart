import 'dart:math';

/// TapJunkie CORE SYSTEM
/// ---------------------
/// MomentumController produces a stable 0..1 momentum signal based on:
/// - Tap rate (taps/second) over a rolling window
/// - Accuracy (hit/miss) as an exponential moving average
/// - Natural decay over time
///
/// This is intentionally game-agnostic and reusable across TapJunkie titles.
class MomentumController {
  MomentumConfig config;

  /// Current momentum in [0, 1].
  double momentum = 0.0;

  /// Smoothed taps/sec signal (0..1 normalized via config).
  double tapRate01 = 0.0;

  /// Smoothed accuracy signal (0..1).
  double accuracy01 = 1.0;

  // Rolling tap timestamps (seconds since start).
  final List<double> _tapTimes = <double>[];

  // Internal clock (seconds).
  double _t = 0.0;

  MomentumController({MomentumConfig? config})
      : config = config ?? const MomentumConfig();

  /// Advance internal time and apply decay.
  void update(double dt) {
    if (dt <= 0) return;
    _t += dt;

    // Drop old taps outside the rolling window.
    final cutoff = _t - config.tapWindowSeconds;
    while (_tapTimes.isNotEmpty && _tapTimes.first < cutoff) {
      _tapTimes.removeAt(0);
    }

    // Compute taps/sec over the rolling window.
    final tapsPerSecond = _tapTimes.length / max(0.001, config.tapWindowSeconds);
    tapRate01 = _normalizeTapsPerSecond(tapsPerSecond);

    // Passive decay pulls momentum down each frame.
    momentum = max(0.0, momentum - (config.decayPerSecond * dt));

    // Recompute momentum from current signals (rate + accuracy).
    final target = _computeTargetMomentum(tapRate01, accuracy01);
    momentum = _approach(momentum, target, config.approachPerSecond, dt);
  }

  /// Register a tap event. Use `hit=false` for misses/wrong taps.
  /// Optionally pass `accuracyWeight` (0..1) if a hit has quality.
  void registerTap({required bool hit, double accuracyWeight = 1.0}) {
    // record tap time
    _tapTimes.add(_t);

    // accuracy EMA update
    final a = config.accuracyEmaAlpha.clamp(0.0, 1.0);
    final sample = hit ? accuracyWeight.clamp(0.0, 1.0) : 0.0;
    accuracy01 = (1.0 - a) * accuracy01 + a * sample;

    // small immediate nudge upward for responsive feel (still bounded)
    if (hit) {
      momentum = min(1.0, momentum + config.hitBoost);
    } else {
      momentum = max(0.0, momentum - config.missPenalty);
    }
  }

  /// Hard reset to baseline.
  void reset() {
    momentum = 0.0;
    tapRate01 = 0.0;
    accuracy01 = 1.0;
    _tapTimes.clear();
    _t = 0.0;
  }

  double _normalizeTapsPerSecond(double tps) {
    // Map [minTps..maxTps] to [0..1]
    final minTps = config.minTapsPerSecond;
    final maxTps = max(minTps + 0.001, config.maxTapsPerSecond);
    final v = (tps - minTps) / (maxTps - minTps);
    return v.clamp(0.0, 1.0);
  }

  double _computeTargetMomentum(double rate01, double acc01) {
    // Weighted blend: momentum is mostly "pace", but accuracy tempers it.
    final r = rate01.clamp(0.0, 1.0);
    final a = acc01.clamp(0.0, 1.0);
    final wR = config.rateWeight;
    final wA = config.accuracyWeight;

    // Basic: target = weighted average, then apply an "accuracy gate"
    // so sloppy taps can't ride to Tier 12 later.
    final base = ((wR * r) + (wA * a)) / max(0.001, (wR + wA));
    final gated = base * (config.accuracyGateMin + (1.0 - config.accuracyGateMin) * a);
    return gated.clamp(0.0, 1.0);
  }

  double _approach(double current, double target, double perSecond, double dt) {
    if (perSecond <= 0) return current;
    final maxDelta = perSecond * dt;
    if ((target - current).abs() <= maxDelta) return target;
    return current + (target > current ? maxDelta : -maxDelta);
  }
}

class MomentumConfig {
  /// Rolling window used to compute tap rate.
  final double tapWindowSeconds;

  /// Tap rate normalization range.
  final double minTapsPerSecond;
  final double maxTapsPerSecond;

  /// Passive decay rate applied continuously.
  final double decayPerSecond;

  /// How fast momentum approaches the computed target each second.
  final double approachPerSecond;

  /// EMA alpha for accuracy smoothing (higher reacts faster).
  final double accuracyEmaAlpha;

  /// Immediate adjustments per tap.
  final double hitBoost;
  final double missPenalty;

  /// Blend weights.
  final double rateWeight;
  final double accuracyWeight;

  /// Minimum gate factor applied before multiplying by accuracy (prevents total collapse).
  final double accuracyGateMin;

  const MomentumConfig({
    this.tapWindowSeconds = 2.0,
    this.minTapsPerSecond = 0.5,
    this.maxTapsPerSecond = 6.0,
    this.decayPerSecond = 0.18,
    this.approachPerSecond = 2.2,
    this.accuracyEmaAlpha = 0.20,
    this.hitBoost = 0.015,
    this.missPenalty = 0.030,
    this.rateWeight = 0.70,
    this.accuracyWeight = 0.30,
    this.accuracyGateMin = 0.35,
  });
}
