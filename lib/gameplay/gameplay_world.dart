import 'balloon.dart';

/// GameplayWorld
///
/// Domain container for gameplay state.
/// Owns exactly one Balloon for Step 9.
///
/// No logic. No systems. No loops.
class GameplayWorld {
  final Balloon balloon;

  GameplayWorld() : balloon = Balloon(id: 'balloon-1');
}
