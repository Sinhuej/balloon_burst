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

  bool get isEnded => _ended;
  int get escapeCount => _escapeCount;
  int get missCount => _missCount;
  String? get endReason => _endReason;


