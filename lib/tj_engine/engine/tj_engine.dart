// lib/tj_engine/engine/tj_engine.dart

import 'run/run_lifecycle_manager.dart';

/// ===============================================================
/// SYSTEM: TJEngine (Engine Facade)
/// ===============================================================
///
/// PURPOSE:
/// Single entry point to all TapJunkie engine systems.
///
/// OWNED BY:
/// BalloonBurst (for now)
///
/// FUTURE:
/// This file becomes the only import point for games.
/// Games should not directly instantiate engine subsystems.
///
/// IMPORTANT:
/// This facade currently only exposes RunLifecycleManager.
/// Additional systems will be attached in later phases.
///
/// This file must remain pure Dart.
/// No Flutter imports.
/// ===============================================================
class TJEngine {
  final RunLifecycleManager runLifecycle;

  TJEngine({
    RunLifecycleManager? runLifecycle,
  }) : runLifecycle = runLifecycle ?? RunLifecycleManager();
}
