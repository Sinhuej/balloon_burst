import "../gameplay/gameplay_world.dart";
import "../gameplay/balloon.dart";
import "commands/pop_balloon_command.dart";
import "commands/pop_first_available_command.dart";
import "commands/remove_popped_balloons_command.dart";
import "commands/spawn_balloon_command.dart";
import "commands/activate_powerup_command.dart";
import "powerups/power_up.dart";

class GameController {
  GameplayWorld? _world;
  GameplayWorld? get gameplayWorld => _world;

  void start() {
    _world = const GameplayWorld(balloons: <Balloon>[]);
  }

  void execute(Object command) {
    final w = _world;
    if (w == null) return;

    if (command is ActivatePowerUpCommand &&
        w.powerUpOnCooldown) return;

    if (command is ActivatePowerUpCommand &&
        command.powerUp is DoublePopPowerUp) {
      var u = w;
      final idx = u.balloons
          .asMap()
          .entries
          .where((e) => !e.value.isPopped)
          .map((e) => e.key)
          .take(2);
      for (final i in idx) {
        u = u.popBalloonAt(i);
      }
      _world = u.copyWith(lastActionWasPowerUp: true);
      return;
    }

    if (command is ActivatePowerUpCommand &&
        command.powerUp is BombPopPowerUp) {
      var u = w;
      final idx = u.balloons
          .asMap()
          .entries
          .where((e) => !e.value.isPopped)
          .map((e) => e.key)
          .toList();
      for (final i in idx) {
        u = u.popBalloonAt(i);
      }
      _world = u.copyWith(lastActionWasPowerUp: true);
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

    if (command is SpawnBalloonCommand) {
      _world = w.spawnBalloon(command.balloon);
      return;
    }
  }

  /// STEP 33
  void autoExecuteSuggestions() {
    final w = _world;
    if (w == null) return;
    final s = w.suggestedCommands;
    if (s.isNotEmpty) execute(s.first);
  }
}
