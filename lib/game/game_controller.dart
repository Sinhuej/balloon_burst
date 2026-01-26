import 'package:balloon_burst/engine/momentum/momentum_controller.dart';
import 'package:balloon_burst/engine/tier/tier_controller.dart';
import 'package:balloon_burst/engine/speed/speed_curve.dart';
import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/gameplay/balloon.dart';

class GameController {
  final MomentumController momentum;
  final TierController tier;
  final SpeedCurve speed;
  final GameState gameState;

  GameController({
    required this.momentum,
    required this.tier,
    required this.speed,
    required this.gameState,
  });

  static const int maxEscapesBeforeFail = 3;
  static const int maxMissesBeforeFail = 10;

  int _escapeCount = 0;
  int _missCount = 0;
  bool _ended = false;
  String? _endReason;

  int get escapeCount => _escapeCount;
  int get missCount => _missCount;
  bool get isEnded => _ended;
  String? get endReason => _endReason;

  void reset() {
    _escapeCount = 0;
    _missCount = 0;
    _ended = false;
    _endReason = null;

    gameState.log(
      'SYSTEM: run reset',
      type: DebugEventType.system,
    );
  }

  /// Register player input (TapHandler calls this)
  void registerTap({required bool hit}) {
    if (_ended) return;

    momentum.registerTap(hit: hit);

    if (hit) {
      // one-frame visual feedback only
      gameState.tapPulse = true;
      return;
    }

    _missCount++;

    gameState.log(
      'MISS: count=$_missCount',
      type: DebugEventType.miss,
    );

    _checkFail();
  }

  /// Called by GameScreen when balloons are removed for escaping.
  void registerEscapes(int count) {
    if (_ended) return;
    if (count <= 0) return;

    _escapeCount += count;

    gameState.log(
      'WORLD: ESCAPE +$count total=$_escapeCount',
      type: DebugEventType.world,
    );

    // Optional: treat escapes as a "bad event" for momentum signal.
    momentum.registerTap(hit: false);

    _checkFail();
  }

  /// Per-frame update hook (kept for future use; currently minimal by design).
  void update(List<Balloon> balloons, double dt) {
    if (_ended) return;
    // Intentionally empty for Option A (no GameState mutations, no removal here).
  }

  void _checkFail() {
    if (_ended) return;

    if (_escapeCount >= maxEscapesBeforeFail) {
      _endRun('escape');
    } else if (_missCount >= maxMissesBeforeFail) {
      _endRun('miss');
    }
  }

  void _endRun(String reason) {
    if (_ended) return;

    _ended = true;
    _endReason = reason;

    gameState.log(
      'SYSTEM: RUN END reason=$reason escapes=$_escapeCount misses=$_missCount',
      type: DebugEventType.system,
    );

    // NOTE (Option A): We do NOT change gameState.screenMode here.
    // UI/end-screen work comes next phase.
  }

  bool get isEnded => _ended;
  int get escapeCount => _escapeCount;
  int get missCount => _missCount;
  String? get endReason => _endReason;

}
