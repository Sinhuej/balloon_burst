import 'package:flutter/foundation.dart';

/// WorldState
/// -------------
/// Single source of truth for Rising Worlds progression.
/// Logic-only. No UI, no spawners, no rendering.
class WorldState {
  int worldIndex;
  int poppedThisWorld;

  WorldState({
    this.worldIndex = 1,
    this.poppedThisWorld = 0,
  });

  /// Deterministic scaling rule (TJ-30)
  int get balloonsToClear {
    return 20 + (worldIndex - 1) * 10;
  }

  /// Register a balloon pop toward world progress
  void registerPop() {
    poppedThisWorld++;
    debugPrint(
      'World $worldIndex progress: $poppedThisWorld / $balloonsToClear',
    );
  }

  /// Whether the current world is complete
  bool get isWorldComplete {
    return poppedThisWorld >= balloonsToClear;
  }

  /// Advance to the next world (soft reset)
  void advanceWorld() {
    debugPrint('World $worldIndex complete');
    worldIndex++;
    poppedThisWorld = 0;
  }
}
