import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/game/balloon_spawner.dart';
import 'run_summary_builder.dart';

class RunSummaryLogger {
  static void log({
    required GameState gameState,
    required BalloonSpawner spawner,
    required int escapes,
    required int missStreak,
  }) {
    final summary = RunSummaryBuilder.build(
      reason: gameState.endReason ?? 'unknown',
      world: spawner.currentWorld,
      pops: spawner.totalPops,
      escapes: escapes,
      missStreak: missStreak,
      hits: spawner.recentHits + spawner.totalPops,
      misses: spawner.recentMisses,
    );

    gameState.logEvent(
      DebugEventType.run,
      'RUN SUMMARY ${summary.toString()}',
    );
  }
}
