import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:balloon_burst/audio/audio_player.dart';

/// World Surge Pulse v1.2
/// - Fires shortly before world transition
/// - Fake-out flash: current → next → current
/// - Vertical micro-shake
class WorldSurgePulse {
  final AnimationController _pulseCtrl;
  final AnimationController _shakeCtrl;

  int _lastSurgeWorld = 0;
  bool _invertColors = false;

  static const double pulseMaxOpacity = 0.08;
  static const double shakeAmpPx = 2.5;

  WorldSurgePulse({
    required TickerProvider vsync,
  })  : _pulseCtrl = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 160),
        ),
        _shakeCtrl = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 120),
        );

  void dispose() {
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
  }

  /// 🔑 Reset surge state for a brand-new run (Retry)
  void reset() {
    _lastSurgeWorld = 0;
    _invertColors = false;
    _pulseCtrl.reset();
    _shakeCtrl.reset();
  }

  void maybeTrigger({
    required int totalPops,
    required int currentWorld,
    required int world2Pops,
    required int world3Pops,
    required int world4Pops,
  }) {
    // Only fire once per world per run
    if (_lastSurgeWorld == currentWorld) return;

    final int? triggerAt = switch (currentWorld) {
      1 => world2Pops - 3,
      2 => world3Pops - 4,
      3 => world4Pops - 5,
      _ => null,
    };

    if (triggerAt != null && totalPops == triggerAt) {
      _lastSurgeWorld = currentWorld;

      AudioPlayerService.playSurge(); // 🔊 anticipation cue

      _invertColors = true;
      _pulseCtrl
        ..reset()
        ..forward();

      _shakeCtrl
        ..reset()
        ..forward();

      // Snap back to current color when pulse completes
      _pulseCtrl.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _invertColors = false;
        }
      });
    }
  }

  bool get showNextWorldColor => _invertColors;

  bool get isActive =>
      _pulseCtrl.isAnimating || _pulseCtrl.value > 0.0;

  double get pulseOpacity {
    final t = _pulseCtrl.value.clamp(0.0, 1.0);
    final eased = 1.0 - t;
    return pulseMaxOpacity * eased * eased;
  }

  double get shakeYOffset {
    final t = _shakeCtrl.value.clamp(0.0, 1.0);
    return sin(pi * t) * shakeAmpPx;
  }

  Listenable get listenable =>
      Listenable.merge([_pulseCtrl, _shakeCtrl]);
}
