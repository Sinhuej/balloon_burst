import 'balloon.dart';
import '../game/commands/pop_first_available_command.dart';
import '../game/commands/remove_popped_balloons_command.dart';
import '../world/world_state.dart';

class GameplayWorld {
  final List<Balloon> balloons;
  final bool lastActionWasPowerUp;
  final WorldState worldState;
  final bool pendingWorldAdvance;

  const GameplayWorld({
    required this.balloons,
    this.lastActionWasPowerUp = false,
    WorldState? worldState,
    this.pendingWorldAdvance = false,
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
    bool? pendingWorldAdvance,
  }) {
    return GameplayWorld(
      balloons: balloons ?? this.balloons,
      lastActionWasPowerUp:
          lastActionWasPowerUp ?? this.lastActionWasPowerUp,
      worldState: worldState ?? this.worldState,
      pendingWorldAdvance:
          pendingWorldAdvance ?? this.pendingWorldAdvance,
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

    worldState.registerPop();
    final shouldAdvance = worldState.isWorldComplete;

    return copyWith(
      balloons: updated,
      lastActionWasPowerUp: true, // 🔑 restore gameplay signal
      pendingWorldAdvance: shouldAdvance,
    );
  }

  GameplayWorld removePoppedBalloons() {
    final remaining = balloons.where((b) => !b.isPopped).toList();
    if (remaining.length == balloons.length) return this;

    if (pendingWorldAdvance) {
      worldState.advanceWorld();
      return GameplayWorld(
        balloons: const [],
        lastActionWasPowerUp: false,
        worldState: worldState,
        pendingWorldAdvance: false,
      );
    }

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
