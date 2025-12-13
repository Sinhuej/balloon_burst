// lib/engine/momentum/momentum_config.dart

/// Configuration model for the Universal Momentum system.
///
/// This allows momentum behavior to be tuned per game
/// or globally without touching gameplay code.
class MomentumConfig {
  /// Multiplier applied when local momentum is gained
  final double localGainRate;

  /// Rate at which local momentum decays per second
  final double localDecayRate;

  /// Percentage (0.0–1.0) of local gains that feed universal momentum
  final double universalShare;

  /// Universal momentum thresholds that define Rising Worlds
  final List<double> worldThresholds;

  const MomentumConfig({
    required this.localGainRate,
    required this.localDecayRate,
    required this.universalShare,
    required this.worldThresholds,
  });

  /// Create config from JSON (future-ready)
  factory MomentumConfig.fromJson(Map<String, dynamic> json) {
    return MomentumConfig(
      localGainRate: (json['localGainRate'] as num).toDouble(),
      localDecayRate: (json['localDecayRate'] as num).toDouble(),
      universalShare: (json['universalShare'] as num).toDouble(),
      worldThresholds: (json['worldThresholds'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  /// Safe default config (used if JSON is not wired yet)
  static MomentumConfig defaults() {
    return const MomentumConfig(
      localGainRate: 1.0,
      localDecayRate: 0.25,
      universalShare: 0.30,
      worldThresholds: [
        0,
        100,
        300,
        700,
        1500,
        3000,
        6000,
        10000,
      ],
    );
  }
}

