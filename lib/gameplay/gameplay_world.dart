import 'balloon.dart';
import '../game/commands/pop_first_available_command.dart';
import '../game/commands/remove_popped_balloons_command.dart';
import '../world/world_state.dart';

class GameplayWorld {
  final List<Balloon> balloons;
  final bool lastActionWasPowerUp;
  final WorldState worldState;

  const GameplayWorld({
    required this.balloons,
    this.lastActionWasPowerUp = false,
    WorldState? worldState,
  }) : worldState = worldState ?? WorldState();

  int get poppedCount => balloons.where((b) => b.isPopped).length;

  int get score {
    if (poppedCount == 0) return 0;
    return (poppedCount * 10) + ((poppedCount - 1) * 5);
  }

  bool get isGameOver => false;
  bool get isWin => false;

  GameplayWorld copyWith({
    List<Balloon>? balloons,
    bool? lastActionWasPowerUp,
    WorldState? worldState,
  }) {
    return GameplayWorld(
      balloons: balloons ?? this.balloons,
      lastActionWasPowerUp:
          lastActionWasPowerUp ?? this.lastActionWasPowerUp,
      worldState: worldState ?? this.worldState,
    );
  }

  GameplayWorld applyScroll(double dy) {
    if (dy == 0) return this;
    return copyWith(
      balloons: balloons.map((b) => b.movedBy(dy)).toList(),
    );
  }

  GameplayWorld popBalloonAt(int index) {
    if (index < 0 || index >= balloons.length) return this;

    final b = balloons[index];
    if (b.isPopped) return this;

    final updated = List<Balloon>.from(balloons);
    updated[index] = b.pop();

    // TJ-30: register world progress
    worldState.registerPop();

    // TJ-30: world completion + soft reset
    if (worldState.isWorldComplete) {
      worldState.advanceWorld();

      return GameplayWorld(
        balloons: const [],
        lastActionWasPowerUp: false,
        worldState: worldState,
      );
    }

    return copyWith(
      balloons: updated,
      lastActionWasPowerUp: false,
    );
  }

  GameplayWorld removePoppedBalloons() {
    final remaining = balloons.where((b) => !b.isPopped).toList();
    if (remaining.length == balloons.length) return this;

    return copyWith(
      balloons: remaining,
      lastActionWasPowerUp: false,
    );
  }

  List<Object> get suggestedCommands {
    if (balloons.any((b) => b.isPopped)) {
      return const <Object>[RemovePoppedBalloonsCommand()];
    }
    return const <Object>[];
  }
}
