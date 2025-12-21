import "../gameplay/gameplay_world.dart";
import "../gameplay/balloon.dart";
import "commands/pop_balloon_command.dart";
import "commands/pop_first_available_command.dart";
import "commands/remove_popped_balloons_command.dart";
import "commands/spawn_balloon_command.dart";

class GameController {
  GameplayWorld? _world;

  GameplayWorld? get gameplayWorld => _world;

  void start() {
    _world = const GameplayWorld(balloons: <Balloon>[]);
  }

  void execute(Object command) {
    final world = _world;
    if (world == null) return;

    if (command is PopBalloonCommand) {
      _world = world.popBalloonAt(command.index);
      return;
    }

    if (command is PopFirstAvailableCommand) {
      final index =
          world.balloons.indexWhere((b) => !b.isPopped);
      if (index < 0) return;
      _world = world.popBalloonAt(index);
      return;
    }

    if (command is RemovePoppedBalloonsCommand) {
      _world = world.removePoppedBalloons();
      return;
    }

    /// STEP 28
    if (command is SpawnBalloonCommand) {
      _world = world.spawnBalloon(command.balloon);
      return;
    }
  }

  void autoExecuteSuggestions() {
    final world = _world;
    if (world == null) return;

    final suggestions = world.suggestedCommands;
    if (suggestions.isEmpty) return;

    execute(suggestions.first);
  }
}
