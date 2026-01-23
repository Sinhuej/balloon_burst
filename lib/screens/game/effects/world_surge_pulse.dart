import 'dart:math';
import 'package:flutter/material.dart';

class WorldSurgePulse {
  final AnimationController _flipCtrl;
  final AnimationController _pulseCtrl;
  final AnimationController _shakeCtrl;

  bool _showNextWorldColor = false;
  bool _isActive = false;

  static const int _tapsBefore = 5; // LOCKED timing
  static const double _pulseMaxOpacity = 0.10;
  static const double _shakeAmpPx = 3.0;

  WorldSurgePulse({
    required TickerProvider vsync,
  })  : _flipCtrl = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 120),
        ),
        _pulseCtrl = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 220),
        ),
        _shakeCtrl = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 160),
        ) {
    _flipCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        // after the quick flip, allow the fade-back to finish and then reset
        _showNextWorldColor = false;
      }
    });

    _pulseCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _isActive = false;
      }
    });
  }

  Listenable get listenable =>
      Listenable.merge([_flipCtrl, _pulseCtrl, _shakeCtrl]);

  bool get isActive => _isActive;

  /// When true, background should show next-world color (briefly).
  bool get showNextWorldColor => _showNextWorldColor;

  /// Fade layer opacity (subtle wash)
  double get pulseOpacity {
    if (!_isActive) return 0.0;
    final t = _pulseCtrl.value.clamp(0.0, 1.0);
    // ease out
    final eased = 1.0 - t;
    return _pulseMaxOpacity * eased * eased;
  }

  /// Shake Y offset
  double get shakeYOffset {
    if (!_isActive) return 0.0;
    final t = _shakeCtrl.value.clamp(0.0, 1.0);
    return sin(pi * t) * _shakeAmpPx;
  }

  /// Call this on POP, using current totals.
  /// Triggers exactly _tapsBefore before the next threshold.
  void maybeTrigger({
    required int totalPops,
    required int currentWorld,
    required int world2Pops,
    required int world3Pops,
    required int world4Pops,
  }) {
    final int? triggerAt = switch (currentWorld) {
      1 => world2Pops - _tapsBefore,
      2 => world3Pops - _tapsBefore,
      3 => world4Pops - _tapsBefore,
      _ => null,
    };

    if (triggerAt == null) return;

    // totalPops increments on pop, so trigger when we HIT the exact count.
    if (totalPops == triggerAt) {
      _isActive = true;
      _showNextWorldColor = true;

      _flipCtrl.forward(from: 0.0);
      _pulseCtrl.forward(from: 0.0);
      _shakeCtrl.forward(from: 0.0);
    }
  }

  void dispose() {
    _flipCtrl.dispose();
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
  }
}
