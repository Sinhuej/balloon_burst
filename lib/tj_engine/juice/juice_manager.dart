// lib/tj_engine/juice/juice_manager.dart

import 'models/score_burst.dart';

/// ===============================================================
/// SYSTEM: JuiceManager (TapJunkie "Arcade Juice")
/// ===============================================================
///
/// Engine-owned micro-feedback events.
/// - Stores ephemeral FX events (score bursts, etc)
/// - Updates lifetimes (dt-based)
/// - UI pulls snapshots and renders them
///
/// IMPORTANT:
/// This module is intentionally lightweight and optional.
/// Future games can:
/// - disable it (never call spawn)
/// - swap visuals (UI-only)
/// - replace manager implementation if desired
/// ===============================================================
class JuiceManager {
  final List<ScoreBurst> _scoreBursts = [];

  int _idCounter = 0;

  List<ScoreBurst> get scoreBursts => List.unmodifiable(_scoreBursts);

  void clear() {
    _scoreBursts.clear();
  }

  void update(double dt) {
    if (_scoreBursts.isEmpty) return;

    for (int i = 0; i < _scoreBursts.length; i++) {
      _scoreBursts[i] = _scoreBursts[i].advanced(dt);
    }

    _scoreBursts.removeWhere((b) => !b.isAlive);
  }

  /// Spawn a classic arcade “+1” score burst.
  ///
  /// x/y are screen-space pixels (from TapDownDetails.localPosition).
  void spawnScoreBurst({
    required double x,
    required double y,
    int value = 1,
  }) {
    final id = 'sb_${_idCounter++}';

    // Lifetime tuning: quick and snappy.
    const lifetimeS = 0.70;

    _scoreBursts.add(
      ScoreBurst(
        id: id,
        x: x,
        y: y,
        value: value,
        ageS: 0.0,
        lifetimeS: lifetimeS,
      ),
    );
  }
}
