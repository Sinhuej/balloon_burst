// lib/tj_engine/engine/run/models/run_state.dart

/// ===============================================================
/// SYSTEM: Run Lifecycle State
/// ===============================================================
///
/// PURPOSE:
/// Defines the state machine for a single gameplay run.
///
/// OWNED BY:
/// RunLifecycleManager
///
/// CONSUMED BY:
/// - UI overlays
/// - Game flow control
///
/// IMPORTANT:
/// This file contains no logic.
/// It is a pure enum definition.
/// ===============================================================

/// Represents the lifecycle state of a run.
enum RunState {
  /// No run is active.
  idle,

  /// Run is currently active and receiving events.
  running,

  /// Run has ended and summary is frozen.
  ended,
}

/// Represents why a run ended.
///
/// To add new fail conditions:
/// -> Add new enum value here
/// -> Handle it inside RunLifecycleManager
/// -> Update RunEnd messaging logic
enum EndReason {
  playerQuit,
  gameOver,
  escapeLimit,
  missLimit,
  timeout,
  systemInterrupt,
  unknown,
}
