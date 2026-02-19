// lib/tj_engine/engine/tj_engine.dart

import 'run/run_lifecycle_manager.dart';
import 'daily/daily_reward_manager.dart';

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
/// This facade exposes:
/// - RunLifecycleManager
/// - DailyRewardManager
///
/// This file must remain pure Dart.
/// No Flutter imports.
/// ===============================================================
class TJEngine {
  /// Authoritative run lifecycle system.
  final RunLifecycleManager runLifecycle;

  /// Daily reward system (24-hour claim logic).
  final DailyRewardManager dailyReward;

  TJEngine({
    RunLifecycleManager? runLifecycle,
    DailyRewardManager? dailyReward,
  })  : runLifecycle = runLifecycle ?? RunLifecycleManager(),
        dailyReward = dailyReward ?? DailyRewardManager();
}
