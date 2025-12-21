import "../gameplay/gameplay_world.dart";
import "../gameplay/balloon.dart";
import "commands/pop_balloon_command.dart";

/// GameController
///
/// Owns GameplayWorld and executes intents.
class GameController {
  GameplayWorld? _world;

  GameplayWorld? get gameplayWorld => _world;

  void start() {
    _world = const GameplayWorld(balloons: <Balloon>[]);
  }

  void stop() {
    _world = null;
  }

  void requestPopAt(int index) {
    final world = _world;
    if (world == null) return;
    _world = world.popBalloonAt(index);
  }

  void execute(Object command) {
    if (command is PopBalloonCommand) {
      requestPopAt(command.index);
    }
  }

  /// STEP 20
  /// Execute first suggested command only.
  void autoExecuteSuggestions() {
    final world = _world;
    if (world == null) return;

    final suggestions = world.suggestedCommands;
    if (suggestions.isEmpty) return;

    execute(suggestions.first);
  }
}
