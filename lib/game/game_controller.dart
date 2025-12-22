import '../gameplay/gameplay_world.dart';
import '../game/commands/pop_balloon_command.dart';
import '../game/commands/pop_first_available_command.dart';
import '../game/commands/remove_popped_balloons_command.dart';
import '../game/commands/spawn_balloon_command.dart';
import '../game/commands/activate_powerup_command.dart';

class GameController {
  GameplayWorld? _world;
  bool _autoIntentConsumed = false;

  GameplayWorld? get gameplayWorld => _world;

  void start() {
    _world = const GameplayWorld(balloons: []);
    _autoIntentConsumed = false;
    _applyOneAutoIntent();
  }

  void execute(Object command) {
    final w = _world;
    if (w == null) return;

    if (command is SpawnBalloonCommand) {
      _world = w.spawnNextBalloon();
    } else if (command is PopBalloonCommand) {
      _world = w.popBalloonAt(command.index);
    } else if (command is PopFirstAvailableCommand) {
      final i = w.balloons.indexWhere((b) => !b.isPopped);
      if (i >= 0) _world = w.popBalloonAt(i);
    } else if (command is RemovePoppedBalloonsCommand) {
      _world = w.removePoppedBalloons();
    } else if (command is ActivatePowerUpCommand) {
      _world = w.copyWith(lastActionWasPowerUp: true);
    }

    // reset auto-intent after explicit action
    _autoIntentConsumed = false;
    _applyOneAutoIntent();
  }

  void _applyOneAutoIntent() {
    if (_autoIntentConsumed) return;

    final w = _world;
    if (w == null) return;

    final suggestions = w.suggestedCommands;
    if (suggestions.isEmpty) return;

    _autoIntentConsumed = true;
    execute(suggestions.first);
  }
}
