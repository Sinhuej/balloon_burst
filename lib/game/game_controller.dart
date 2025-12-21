import "../gameplay/gameplay_world.dart";
import "../gameplay/balloon.dart";
import "commands/pop_balloon_command.dart";
import "commands/pop_first_available_command.dart";

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
      return;
    }

    /// STEP 22
    /// New command type: pop first available.
    if (command is PopFirstAvailableCommand) {
      final world = _world;
      if (world == null) return;

      final index = world.balloons.indexWhere((b) => !b.isPopped);
      if (index < 0) return;

      requestPopAt(index);
      return;
    }
  }

  /// Execute first suggested command only.
  void autoExecuteSuggestions() {
    final world = _world;
    if (world == null) return;

    final suggestions = world.suggestedCommands;
    if (suggestions.isEmpty) return;

    execute(suggestions.first);
  }
}
