// lib/tj_engine/juice/models/score_burst.dart

/// ===============================================================
/// MODEL: ScoreBurst (UI-consumed, engine-owned)
/// ===============================================================
///
/// Pure data emitted by TJEngine's JuiceManager.
/// Rendered by game UI (GameCanvas) in screen space.
/// No Flutter imports, no UI logic.
/// ===============================================================
class ScoreBurst {
  final String id;

  /// Screen-space position (pixels) where the burst starts.
  final double x;
  final double y;

  /// Display value (we’ll use +1 for now).
  final int value;

  /// Current age in seconds.
  final double ageS;

  /// Lifetime in seconds.
  final double lifetimeS;

  const ScoreBurst({
    required this.id,
    required this.x,
    required this.y,
    required this.value,
    required this.ageS,
    required this.lifetimeS,
  });

  double get t01 {
    if (lifetimeS <= 0) return 1.0;
    final v = ageS / lifetimeS;
    if (v < 0) return 0.0;
    if (v > 1) return 1.0;
    return v;
  }

  bool get isAlive => ageS < lifetimeS;

  ScoreBurst advanced(double dt) => ScoreBurst(
        id: id,
        x: x,
        y: y,
        value: value,
        ageS: ageS + dt,
        lifetimeS: lifetimeS,
      );
}
