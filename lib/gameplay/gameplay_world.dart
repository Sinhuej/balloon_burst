import "balloon.dart";
import "../game/commands/pop_balloon_command.dart";
import "../game/commands/pop_first_available_command.dart";

/// GameplayWorld
///
/// Immutable domain state.
class GameplayWorld {
  final List<Balloon> balloons;

  const GameplayWorld({required this.balloons});

  int get poppedCount => balloons.where((b) => b.isPopped).length;

  int get score => poppedCount * 10;

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

  /// STEP 23
  /// Prioritized suggestion list (bounded):
  /// - If any unpopped balloons exist, suggest ONLY the prioritized command
  ///   (pop first available).
  /// - Otherwise, suggest nothing.
  ///
  /// This keeps suggestions deterministic and prevents command floods.
  List<Object> get suggestedCommands {
    final hasAny = balloons.any((b) => !b.isPopped);
    if (!hasAny) return const <Object>[];

    return const <Object>[PopFirstAvailableCommand()];
  }

  /// (Optional) Still available for direct indexed pop by external intent.
  /// Kept for compatibility and explicit actions.
  PopBalloonCommand commandForIndex(int index) => PopBalloonCommand(index);
}
