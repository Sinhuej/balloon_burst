class Balloon {
  Offset position;
  double radius;
  double speed;
  Color color;
  bool isGolden;
  bool isBomb;
  double glowIntensity; // 0–1

  Balloon({
    required this.position,
    required this.radius,
    required this.speed,
    required this.color,
    required this.isGolden,
    required this.isBomb,
    required this.glowIntensity,
  });
}
