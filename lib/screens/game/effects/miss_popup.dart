import 'package:flutter/material.dart';

class MissPopup {
  final double x;
  final double y;
  final double age;
  final double life;
  final String label;
  final Color color;

  const MissPopup({
    required this.x,
    required this.y,
    required this.age,
    required this.life,
    required this.label,
    required this.color,
  });

  double get t01 => (age / life).clamp(0.0, 1.0);
  double get opacity => 1.0 - t01;
  bool get alive => age < life;

  MissPopup advance(double dt) {
    return MissPopup(
      x: x,
      y: y,
      age: age + dt,
      life: life,
      label: label,
      color: color,
    );
  }
}
