import 'balloon.dart';

/// Domain-only world state.
/// Exists only while gameplay is running.
/// Owns the balloon list.
/// No Flutter. No Flame.
class GameplayWorld {
  final List<Balloon> balloons;

  const GameplayWorld({
    required this.balloons,
  });

  /// Step 12-1: derived popped state
  /// Read-only, explicit, no caching, no side effects.
  int get poppedCount {
    var count = 0;
    for (final b in balloons) {
      if (b.isPopped) count++;
    }
    return count;
  }

  /// Step 13-1: explicitly apply a pop to one balloon by index.
  /// Returns a new world or this world if no change applies.
  GameplayWorld popBalloonAt(int index) {
    if (index < 0 || index >= balloons.length) {
      return this;
    }

    final target = balloons[index];
    if (target.isPopped) {
      return this;
    }

    final updated = <Balloon>[];
    for (var i = 0; i < balloons.length; i++) {
      if (i == index) {
        updated.add(target.pop());
      } else {
        updated.add(balloons[i]);
      }
    }

    return GameplayWorld(balloons: updated);
  }
}
