// lib/engine/momentum/momentum_manager.dart

import 'momentum_models.dart';
import 'momentum_config.dart';
import 'momentum_storage.dart';
import '../worlds/rising_worlds.dart';

/// Universal Momentum Manager
///
/// Handles:
/// - Local (per-session / per-game) momentum
/// - Universal (cross-game) momentum
/// - Rising Worlds evaluation
///
/// Storage is abstracted so cloud sync can be added later
/// without touching gameplay code.
class MomentumManager {
  final MomentumConfig config;
  final MomentumStorage storage;

  late final RisingWorlds _worlds;

  double _localMomentum = 0.0;
  double _universalMomentum = 0.0;

  MomentumManager({
    required this.config,
    required this.storage,
  }) {
    _worlds = RisingWorlds(config.worldThresholds);
  }

  /// Load universal momentum from storage
  Future<void> init() async {
    _universalMomentum = await storage.loadUniversal();
  }

  /// Add local momentum (called by gameplay events)
  void addLocal(double amount) {
    if (amount <= 0) return;

    final gained = amount * config.localGainRate;
    _localMomentum += gained;

    final shared = gained * config.universalShare;
    _universalMomentum += shared;

    storage.saveUniversal(_universalMomentum);
  }

  /// Decay local momentum over time
  void decayLocal(double dt) {
    _localMomentum -= config.localDecayRate * dt;
    if (_localMomentum < 0) {
      _localMomentum = 0;
    }
  }

  /// Current snapshot of momentum state
  MomentumSnapshot snapshot() {
    return MomentumSnapshot(
      local: _localMomentum,
      universal: _universalMomentum,
      worldLevel: _worlds.getWorldLevel(_universalMomentum),
    );
  }

  /// Convenience getters
  double get local => _localMomentum;
  double get universal => _universalMomentum;
}

