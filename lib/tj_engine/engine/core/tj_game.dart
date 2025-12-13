// lib/engine/core/tj_game.dart

import 'dart:async';
import 'package:flame/game.dart';

import 'game_manager.dart';
import 'difficulty_manager.dart';
import 'states.dart';

// TapJunkie Universal Progression
import '../momentum/momentum_manager.dart';
import '../worlds/rising_worlds.dart';

/// Base class for all TapJunkie games.
///
/// Wraps FlameGame + shared GameManager & DifficultyManager.
/// Drives Universal Momentum + Rising Worlds progression.
///
/// TJGame does NOT own progression logic.
/// It only advances it while the game is actively playing.
class TJGame extends FlameGame {
  final GameManager gameManager;
  final DifficultyManager difficultyManager;

  /// Universal momentum spine (shared across games later)
  final MomentumManager momentumManager;

  /// Rising Worlds evaluator (tiering)
  late final RisingWorlds risingWorlds;

  TJGame({
    required this.gameManager,
    required this.momentumManager,
    DifficultyManager? difficultyManager,
  }) : difficultyManager = difficultyManager ?? DifficultyManager() {
    risingWorlds = RisingWorlds(momentumManager.config.worldThresholds);
  }

  /// Override in your game if you want to react to state changes.
  void onGameStateChanged(GameState state) {
    // Default: do nothing.
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize universal momentum state
    await momentumManager.init();

    // Hook game state changes
    gameManager.addListener(onGameStateChanged);
  }

  @override
  void onRemove() {
    gameManager.removeListener(onGameStateChanged);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Only advance progression while actively playing.
    if (gameManager.state != GameState.playing) {
      return;
    }

    // === TAPJUNKIE UNIVERSAL PROGRESSION SPINE ===
    momentumManager.decayLocal(dt);

    // World level can be queried by any system:
    // final snapshot = momentumManager.snapshot();
    // final world = snapshot.worldLevel;

    // DifficultyManager remains game-specific
    // but can later read from world/momentum if desired.
  }
}

