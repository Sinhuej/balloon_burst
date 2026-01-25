import 'run_summary.dart';

class RunSummaryBuilder {
  static RunSummary build({
    required String reason,
    required int world,
    required int pops,
    required int escapes,
    required int missStreak,
    required int hits,
    required int misses,
  }) {
    final total = hits + misses;
    final accuracy =
        total == 0 ? 1.0 : (hits / total).clamp(0.0, 1.0);

    return RunSummary(
      reason: reason,
      world: world,
      pops: pops,
      escapes: escapes,
      missStreak: missStreak,
      accuracy: accuracy,
    );
  }
}
