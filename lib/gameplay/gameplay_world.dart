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
}
