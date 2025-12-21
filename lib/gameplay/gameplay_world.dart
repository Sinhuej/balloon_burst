import "balloon.dart";
import "../game/commands/pop_balloon_command.dart";
import "../game/commands/pop_first_available_command.dart";
import "../game/commands/remove_popped_balloons_command.dart";

class GameplayWorld {
  final List<Balloon> balloons;

  const GameplayWorld({required this.balloons});

  int get poppedCount => balloons.where((b) => b.isPopped).length;

  int get score => poppedCount * 10;

  GameplayWorld popBalloonAt(int index) {
    if (index < 0 || index >= balloons.length) return this;
    final balloon = balloons[index];
    if (balloon.isPopped) return this;

    final updated = List<Balloon>.from(balloons);
    updated[index] = balloon.pop();
    return GameplayWorld(balloons: updated);
  }

  /// STEP 25
  /// Remove all popped balloons.
  GameplayWorld removePoppedBalloons() {
    final remaining = balloons.where((b) => !b.isPopped).toList();
    if (remaining.length == balloons.length) return this;
    return GameplayWorld(balloons: remaining);
  }

  /// STEP 23 (extended)
  /// Prioritized suggestions:
  /// 1) Cleanup if popped balloons exist
  /// 2) Otherwise pop first available
  List<Object> get suggestedCommands {
    if (balloons.any((b) => b.isPopped)) {
      return const <Object>[RemovePoppedBalloonsCommand()];
    }

    if (balloons.any((b) => !b.isPopped)) {
      return const <Object>[PopFirstAvailableCommand()];
    }

    return const <Object>[];
  }

  PopBalloonCommand commandForIndex(int index) =>
      PopBalloonCommand(index);
}
