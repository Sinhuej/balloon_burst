import 'package:balloon_burst/game/game_state.dart' show GameState;
import 'package:balloon_burst/debug/debug_log.dart' show DebugEventType;
import 'package:balloon_burst/gameplay/balloon.dart';

import 'package:balloon_burst/engine/momentum/momentum_controller.dart';
import 'package:balloon_burst/engine/tier/tier_controller.dart';
import 'package:balloon_burst/engine/speed/speed_curve.dart';

/// ===============================================================
/// GameController (BalloonBurst)
/// ===============================================================
///
/// RESPONSIBILITY (Post-Engine Integration):
/// - Updates gameplay-related controllers (momentum/tier/speed)
/// - Tracks lightweight telemetry counters (misses/escapes) for UI/debug
/// - Logs gameplay signals
///
/// NON-RESPONSIBILITY:
/// - Run lifecycle authority (start/end) is now owned by TJ Engine
/// - Fail conditions (miss limit, escape limit) are owned by TJ Engine
/// ===============================================================
class GameController {
  final MomentumController momentum;
  final TierController tier;
  final SpeedCurve speed;
  final GameState gameState;

  // Telemetry-only counters (engine owns fail rules + lifecycle)
  int _escapeCount = 0;
  int _missCount = 0;

  GameController({
    required this.momentum,
    required this.tier,
    required this.speed,
    required this.gameState,
  });

  /// Telemetry values (read-only).
  int get escapeCount => _escapeCount;
  int get missCount => _missCount;

  /// -----------------------
  /// Telemetry (read-only)
  /// -----------------------
  double get accuracy01 => momentum.accuracy01;

  void update(List<Balloon> balloons, double dt) {
    momentum.update(dt);

    // NOTE: TierController.update expects momentum01, not dt.
    // If TierController signature differs in this repo, keep as-is.
    // For now we preserve behavior: calling update(...) here.
    tier.update(dt);

    gameState.framesSinceStart++;
  }

  /// Telemetry-only escape registration.
  /// Engine will decide if escapes end the run.
  void registerEscapes(int count) {
    _escapeCount += count;

    gameState.log(
      'WORLD: ESCAPE +$count total=$_escapeCount',
      type: DebugEventType.miss,
    );
  }

  /// Telemetry-only tap registration.
  /// Engine will decide if misses end the run.
  void registerTap({required bool hit}) {
    // Always update momentum first (hit or miss)
    momentum.registerTap(hit: hit);

    // Always log current accuracy (if filter enabled)
    gameState.log(
      'ACCURACY: a01=${momentum.accuracy01.toStringAsFixed(3)}',
      type: DebugEventType.accuracy,
    );

    if (!hit) {
      _missCount++;
      gameState.log(
        'MISS: count=$_missCount',
        type: DebugEventType.miss,
      );
    }
  }

  /// Reset only telemetry + controllers.
  /// Run lifecycle reset is owned by TJ Engine.
  void reset() {
    _escapeCount = 0;
    _missCount = 0;

    momentum.reset();
    tier.reset();

    gameState.log(
      'SYSTEM: controller reset (telemetry + controllers)',
      type: DebugEventType.system,
    );
  }
}
