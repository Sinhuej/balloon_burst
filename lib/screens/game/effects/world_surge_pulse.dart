import 'dart:math';
import 'package:flutter/scheduler.dart';

/// World Surge Pulse v1
/// - Trigger at (threshold - 5) pops for upcoming world change.
/// - Provides:
///   - pulseOpacity (0.08 -> 0.0 over ~180ms, easeOut)
///   - shakeYOffset (vertical micro shake 2–3px over ~120ms)
class WorldSurgePulse {
  final AnimationController _pulseCtrl;
  final AnimationController _shakeCtrl;

  int _lastSurgeWorld = 0;

  static const double pulseMaxOpacity = 0.08;
  static const double shakeAmpPx = 2.5;

  WorldSurgePulse({
    required TickerProvider vsync,
  })  : _pulseCtrl = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 180),
        ),
        _shakeCtrl = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 120),
        );

  void dispose() {
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
  }

  /// Fire when we are (threshold - 5) pops away from a world switch.
  /// Uses BalloonSpawner's locked thresholds via the caller.
  void maybeTrigger({
    required int totalPops,
    required int currentWorld,
    required int world2Pops,
    required int world3Pops,
    required int world4Pops,
  }) {
    if (_lastSurgeWorld == currentWorld) return;

    final int? triggerAt = switch (currentWorld) {
      1 => world2Pops - 5,
      2 => world3Pops - 5,
      3 => world4Pops - 5,
      _ => null,
    };

    if (triggerAt != null && totalPops == triggerAt) {
      _lastSurgeWorld = currentWorld;
      _pulseCtrl.forward(from: 0.0);
      _shakeCtrl.forward(from: 0.0);
    }
  }

  bool get isActive => _pulseCtrl.isAnimating || _pulseCtrl.value > 0.0;

  double get pulseOpacity {
    // Safe, bounded, ease-out without “invisible overlay” bugs.
    final t = _pulseCtrl.value.clamp(0.0, 1.0);
    final eased = 1.0 - t;
    return pulseMaxOpacity * eased * eased;
  }

  double get shakeYOffset {
    final t = _shakeCtrl.value.clamp(0.0, 1.0);
    // Single bump: 0 -> 1 -> 0
    return sin(pi * t) * shakeAmpPx;
  }

  Listenable get listenable => Listenable.merge([_pulseCtrl, _shakeCtrl]);
}
