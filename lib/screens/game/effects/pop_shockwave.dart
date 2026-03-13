import 'package:flutter/material.dart';

class PopShockwave {
  final double x;
  final double y;
  final double age;
  final double life;

  const PopShockwave({
    required this.x,
    required this.y,
    required this.age,
    required this.life,
  });

  PopShockwave advance(double dt) {
    return PopShockwave(
      x: x,
      y: y,
      age: age + dt,
      life: life,
    );
  }

  bool get alive => age < life;

  double get t {
    final v = age / life;
    if (v < 0) return 0;
    if (v > 1) return 1;
    return v;
  }

  double get radius => 8 + (t * 55);

  double get opacity => 1 - t;
}
