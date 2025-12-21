import "../powerups/power_up.dart";

/// ActivatePowerUpCommand
///
/// Intent to activate a power-up.
class ActivatePowerUpCommand {
  final PowerUp powerUp;

  const ActivatePowerUpCommand(this.powerUp);
}
