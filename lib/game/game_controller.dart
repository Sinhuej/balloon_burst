import "../gameplay/gameplay_world.dart";
import "../gameplay/balloon.dart";
import "commands/pop_balloon_command.dart";

/// GameController
///
/// Owns GameplayWorld and executes intents.
/// Sole execution choke point.
class GameController {
  GameplayWorld? _world;

  GameplayWorld? get gameplayWorld => _world;

  void start() {
    _world = const GameplayWorld(balloons: <Balloon>[]);
  }

  void stop() {
    _world = null;
  }

  /// Step 14
  void requestPopAt(int index) {
    final world = _world;
    if (world == null) return;
    _world = world.popBalloonAt(index);
  }

  /// Step 15
  void autoPopFirstAvailable() {
    final world = _world;
    if (world == null) return;

    final index =
        world.balloons.indexWhere((b) => !b.isPopped);
    if (index < 0) return;

    requestPopAt(index);
  }

  /// STEP 18
  /// Execute a command object.
  void execute(Object command) {
    if (command is PopBalloonCommand) {
      requestPopAt(command.index);
    }
  }
}
