import "balloon.dart";
import "../game/commands/pop_balloon_command.dart";

/// GameplayWorld
///
/// Immutable domain state.
class GameplayWorld {
  final List<Balloon> balloons;

  const GameplayWorld({required this.balloons});

  int get poppedCount =>
      balloons.where((b) => b.isPopped).length;

  GameplayWorld popBalloonAt(int index) {
    if (index < 0 || index >= balloons.length) {
      return this;
    }

    final balloon = balloons[index];
    if (balloon.isPopped) return this;

    final updated = List<Balloon>.from(balloons);
    updated[index] = balloon.pop();

    return GameplayWorld(balloons: updated);
  }

  /// STEP 19
  /// Pure suggestion of possible commands.
  List<PopBalloonCommand> get suggestedCommands {
    final commands = <PopBalloonCommand>[];
    for (var i = 0; i < balloons.length; i++) {
      if (!balloons[i].isPopped) {
        commands.add(PopBalloonCommand(i));
      }
    }
    return commands;
  }
}
