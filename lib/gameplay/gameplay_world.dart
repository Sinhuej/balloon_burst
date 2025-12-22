import "balloon.dart";
import "../game/commands/pop_balloon_command.dart";
import "../game/commands/pop_first_available_command.dart";
import "../game/commands/remove_popped_balloons_command.dart";
import "../game/commands/spawn_balloon_command.dart";
import "../game/commands/activate_powerup_command.dart";
import "../game/powerups/power_up.dart";

class GameplayWorld {
  final List<Balloon> balloons;
  final bool lastActionWasPowerUp;

  const GameplayWorld({
    required this.balloons,
    this.lastActionWasPowerUp = false,
  });

  int get poppedCount => balloons.where((b) => b.isPopped).length;

  int get score {
    if (poppedCount == 0) return 0;
    return (poppedCount * 10) + ((poppedCount - 1) * 5);
  }

  bool get powerUpOnCooldown => lastActionWasPowerUp;

  GameplayWorld copyWith({
    List<Balloon>? balloons,
    bool? lastActionWasPowerUp,
  }) =>
      GameplayWorld(
        balloons: balloons ?? this.balloons,
        lastActionWasPowerUp:
            lastActionWasPowerUp ?? this.lastActionWasPowerUp,
      );

  GameplayWorld popBalloonAt(int index) {
    if (index < 0 || index >= balloons.length) return this;
    final b = balloons[index];
    if (b.isPopped) return this;
    final updated = List<Balloon>.from(balloons);
    updated[index] = b.pop();
    return copyWith(balloons: updated, lastActionWasPowerUp: false);
  }

  GameplayWorld removePoppedBalloons() {
    final remaining = balloons.where((b) => !b.isPopped).toList();
    if (remaining.length == balloons.length) return this;
    return copyWith(balloons: remaining, lastActionWasPowerUp: false);
  }

  GameplayWorld spawnBalloon(Balloon balloon) =>
      copyWith(balloons: [...balloons, balloon], lastActionWasPowerUp: false);

  /// STEP 32 — base curve
  List<Object> get suggestedCommands {
    if (balloons.any((b) => b.isPopped)) {
      return const <Object>[RemovePoppedBalloonsCommand()];
    }
    if (balloons.length < 3) {
      return const <Object>[SpawnBalloonCommand(Balloon())];
    }
    if (balloons.any((b) => !b.isPopped)) {
      return const <Object>[PopFirstAvailableCommand()];
    }
    return const <Object>[];
  }

  PopBalloonCommand commandForIndex(int index) =>
      PopBalloonCommand(index);
}
