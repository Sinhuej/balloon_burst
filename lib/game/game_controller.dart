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
/// - Tracks lightweight telemetry counters (misses/escapes/perfects)
/// - Logs gameplay signals
///
/// NON-RESPONSIBILITY:
/// - Run lifecycle authority (start/end) is owned by TJ Engine
/// - Fail conditions (miss limit, escape limit) are owned by TJ Engine
/// ===============================================================
class GameController {
  final MomentumController momentum;
  final TierController tier;
  final SpeedCurve speed;
  final GameState gameState;

  // Telemetry-only counters
  int _escapeCount = 0;
  int _missCount = 0;
  int _perfectHits = 0;
  int _perfectChain = 0;
  int get perfectChain => _perfectChain;

    DateTime? lastTapTime;  

  GameController({
    required this.momentum,
    required this.tier,
    required this.speed,
    required this.gameState,
  });

  /// Telemetry values (read-only)
  int get escapeCount => _escapeCount;
  int get missCount => _missCount;
  int get perfectHits => _perfectHits;

  /// -----------------------
  /// Telemetry (read-only)
  /// -----------------------
  double get accuracy01 => momentum.accuracy01;

  void update(List<Balloon> balloons, double dt) {
    momentum.update(dt);

    // Tier update
    tier.update(dt);

    gameState.framesSinceStart++;
  }

  /// Telemetry-only escape registration.
  /// Engine decides if escapes end the run.
  void registerEscapes(int count) {
    _escapeCount += count;

    gameState.log(
      'WORLD: ESCAPE +$count total=$_escapeCount',
      type: DebugEventType.miss,
    );
  }

  /// Telemetry-only tap registration.
  /// Engine decides if misses end the run.
  void registerTap({required bool hit, bool perfect = false}) {

  lastTapTime = DateTime.now();

  // Always update momentum first
  momentum.registerTap(hit: hit);

  // Log accuracy telemetry
  gameState.log(
    'ACCURACY: a01=${momentum.accuracy01.toStringAsFixed(3)}',
    type: DebugEventType.accuracy,
  );

  if (hit) {

    if (perfect) {
      _perfectHits++;
      _perfectChain++;

      gameState.log(
        'PERFECT TAP total=$_perfectHits chain=$_perfectChain',
        type: DebugEventType.system,
      );

      if (_perfectChain == 3 ||
          _perfectChain == 5 ||
          _perfectChain == 10 ||
          _perfectChain == 20) {

        gameState.log(
          'PERFECT CHAIN x$_perfectChain',
          type: DebugEventType.system,
        );
      }

    } else {
      _perfectChain = 0;
    }

  } else {

    _perfectChain = 0;
    _missCount++;

    gameState.log(
      'MISS: count=$_missCount',
      type: DebugEventType.miss,
    );
  }
}
  
    lastTapTime = DateTime.now();

    // Always update momentum first
    momentum.registerTap(hit: hit);

    // Log accuracy telemetry
    gameState.log(
      'ACCURACY: a01=${momentum.accuracy01.toStringAsFixed(3)}',
      type: DebugEventType.accuracy,
    );

    if (hit) {

  if (perfect) {
    _perfectHits++;
    _perfectChain++;

    gameState.log(
      'PERFECT TAP total=$_perfectHits chain=$_perfectChain',
      type: DebugEventType.system,
    );

    // TapJunkie milestone moments (no rewards yet)
    if (_perfectChain == 3 ||
        _perfectChain == 5 ||
        _perfectChain == 10 ||
        _perfectChain == 20) {

      gameState.log(
        'PERFECT CHAIN x$_perfectChain',
        type: DebugEventType.system,
      );
    }

  } else {
    _perfectChain = 0;
  }

} else {

  _perfectChain = 0;
  _missCount++;

  gameState.log(
    'MISS: count=$_missCount',
    type: DebugEventType.miss,
  );
}

  /// Reset only telemetry + controllers.
  /// Run lifecycle reset is owned by TJ Engine.
  void reset() {
    _escapeCount = 0;
    _missCount = 0;
    _perfectHits = 0;
    _perfectChain = 0;

    momentum.reset();
    tier.reset();

    gameState.log(
      'SYSTEM: controller reset (telemetry + controllers)',
      type: DebugEventType.system,
    );
  }
}
