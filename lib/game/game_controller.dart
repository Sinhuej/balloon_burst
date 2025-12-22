import "../gameplay/gameplay_world.dart";
import "../game/commands/pop_balloon_command.dart";
import "../game/commands/pop_first_available_command.dart";
import "../game/commands/remove_popped_balloons_command.dart";
import "../game/commands/spawn_balloon_command.dart";

class GameController {
  GameplayWorld? _world;

  GameplayWorld? get gameplayWorld => _world;

  void start() {
    _world = const GameplayWorld(balloons: []);
  }

  void execute(Object command) {
    final w = _world;
    if (w == null) return;

    if (command is SpawnBalloonCommand) {
      _world = w.spawnNextBalloon();
      return;
    }

    if (command is PopBalloonCommand) {
      _world = w.popBalloonAt(command.index);
      return;
    }

    if (command is PopFirstAvailableCommand) {
      final i = w.balloons.indexWhere((b) => !b.isPopped);
      if (i >= 0) _world = w.popBalloonAt(i);
      return;
    }

    if (command is RemovePoppedBalloonsCommand) {
      _world = w.removePoppedBalloons();
      return;
    }
  }

  void autoExecuteSuggestions() {
    final w = _world;
    if (w == null) return;
    final s = w.suggestedCommands;
    if (s.isNotEmpty) execute(s.first);
  }
}
