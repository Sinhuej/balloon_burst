import 'dart:math';
import 'package:flutter/material.dart';

class PopParticle {
  final double x;
  final double y;
  final double vx;
  final double vy;
  final double age;
  final double life;
  final Color color;

  const PopParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.age,
    required this.life,
    this.color = Colors.white,
  });

  PopParticle advance(double dt) {
    return PopParticle(
      x: x + vx * dt,
      y: y + vy * dt,
      vx: vx,
      vy: vy,
      age: age + dt,
      life: life,
      color: color,
    );
  }

  bool get alive => age < life;

  double get opacity {
    final t = (age / life).clamp(0.0, 1.0);
    return 1.0 - t;
  }

  static List<PopParticle> burst(double x, double y) {
    final rand = Random();
    const count = 7;

    return List.generate(count, (_) {
      final angle = rand.nextDouble() * pi * 2;
      final speed = 80 + rand.nextDouble() * 80;

      return PopParticle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        age: 0,
        life: 0.35,
      );
    });
  }
}
