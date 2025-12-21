import 'balloon.dart';

/// GameplayWorld
///
/// Domain container for gameplay state.
/// Owns a collection of Balloons.
/// Step 10: structural expansion only.
///
/// No logic. No systems. No spawning rules.
class GameplayWorld {
  final List<Balloon> balloons;

  GameplayWorld()
      : balloons = [
          Balloon(id: 'balloon-1'),
        ];
}
