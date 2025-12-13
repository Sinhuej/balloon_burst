// lib/engine/momentum/momentum_models.dart

/// Immutable snapshot of momentum state.
///
/// Used by:
/// - Difficulty scaling
/// - UI meters
/// - Reward systems
/// - Rising Worlds gating
class MomentumSnapshot {
  /// Per-game / per-session momentum
  final double local;

  /// Cross-game universal momentum
  final double universal;

  /// Rising World level derived from universal momentum
  final int worldLevel;

  const MomentumSnapshot({
    required this.local,
    required this.universal,
    required this.worldLevel,
  });
}

