// lib/tj_engine/engine/run/models/run_event.dart

/// ===============================================================
/// SYSTEM: RunEvent (Engine Event Contract)
/// ===============================================================
///
/// PURPOSE:
/// Defines the gameplay events that a game module (like BalloonBurst)
/// can report to the TJ Engine RunLifecycleManager.
///
/// OWNED BY:
/// TJ Engine
///
/// REPORTED BY:
/// GameController (later step)
///
/// IMPORTANT:
/// These events are pure data objects.
/// They contain no logic.
/// ===============================================================

/// Base class for all run-related events.
abstract class RunEvent {
  const RunEvent();
}

/// ===============================================================
/// EVENT: Balloon Pop
/// ===============================================================
///
/// Triggered when a balloon is successfully popped.
///
/// To change scoring:
/// -> Adjust ScoreDeltaEvent handling later
///
/// To change pop tracking:
/// -> Modify RunLifecycleManager event handling
class PopEvent extends RunEvent {
  final int points;
  const PopEvent({required this.points});
}

/// ===============================================================
/// EVENT: Miss (Tap Miss)
/// ===============================================================
///
/// Triggered when a player taps but misses.
///
/// Miss limit will be enforced by RunLifecycleManager.
class MissEvent extends RunEvent {
  const MissEvent();
}

/// ===============================================================
/// EVENT: Escape
/// ===============================================================
///
/// Triggered when a balloon escapes the screen.
///
/// To change escape difficulty:
/// -> Modify escape limit in RunLifecycleManager
class EscapeEvent extends RunEvent {
  final int count;
  const EscapeEvent({this.count = 1});
}

/// ===============================================================
/// EVENT: World Transition
/// ===============================================================
///
/// Triggered when the game transitions to a new world.
///
/// World logic currently lives in BalloonSpawner.
/// Later it will be unified with RisingWorlds.
class WorldTransitionEvent extends RunEvent {
  final int newWorldLevel;
  const WorldTransitionEvent({required this.newWorldLevel});
}

/// ===============================================================
/// EVENT: Score Adjustment
/// ===============================================================
///
/// Allows score changes that are not directly tied to pops.
/// (e.g., combo bonuses, powerups, penalties)
class ScoreDeltaEvent extends RunEvent {
  final int delta;
  const ScoreDeltaEvent({required this.delta});
}
