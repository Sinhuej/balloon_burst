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

  // -------- Read-only state (used by UI / RunEndState)
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

  /// Called by GameScreen when balloons escape
  void registerEscapes(int count) {
    if (_ended || count <= 0) return;

    _escapeCount += count;

    gameState.log(
      'WORLD: ESCAPE +$count total=$_escapeCount',
      type: DebugEventType.world,
    );

    momentum.registerTap(hit: false);
    _checkFail();
  }

  /// Per-frame hook (kept intentionally light)
  void update(List<Balloon> balloons, double dt) {
    if (_ended) return;
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
  }
}
