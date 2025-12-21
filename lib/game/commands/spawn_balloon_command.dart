import "../../gameplay/balloon.dart";

/// SpawnBalloonCommand
///
/// Intent to add a new balloon to the world.
class SpawnBalloonCommand {
  final Balloon balloon;

  const SpawnBalloonCommand(this.balloon);
}
