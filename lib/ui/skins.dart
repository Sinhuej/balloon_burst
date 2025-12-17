import 'dart:ui';

class SkinDef {
  final String id;
  final String name;
  final String description;
  final String rarity; // COMMON / RARE / EPIC / LEGENDARY
  final int price;
  final Color background;
  final List<Color> balloonColors;
  final Color glowColor;
  final Color goldGlowColor;

  const SkinDef({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.price,
    required this.background,
    required this.balloonColors,
    required this.glowColor,
    required this.goldGlowColor,
  });
}

/// ---------- SKIN DEFINITIONS ----------

const List<SkinDef> allSkins = [
  SkinDef(
    id: 'classic',
    name: 'Classic Mix',
    description: 'Balanced bright colors, the default TapJunkie mix.',
    rarity: 'COMMON',
    price: 0,
    background: Color(0xFF050817),
    balloonColors: [
      Color(0xFFFFD54F),
      Color(0xFF64FFDA),
      Color(0xFF448AFF),
      Color(0xFFAB47BC),
      Color(0xFFFF7043),
    ],
    glowColor: Color(0x33FFFFFF),
    goldGlowColor: Color(0x66FFD54F),
  ),
  SkinDef(
    id: 'neon_city',
    name: 'Neon City',
    description: 'Electric blues & greens of a city at 3AM.',
    rarity: 'RARE',
    price: 250,
    background: Color(0xFF020510),
    balloonColors: [
      Color(0xFF00E5FF),
      Color(0xFF00FF94),
      Color(0xFF2979FF),
      Color(0xFF651FFF),
    ],
    glowColor: Color(0x5500E5FF),
    goldGlowColor: Color(0x88FFFF00),
  ),
  SkinDef(
    id: 'retro_arcade',
    name: 'Retro Arcade',
    description: 'Orange & magenta glow like a CRT cabinet.',
    rarity: 'RARE',
    price: 300,
    background: Color(0xFF05000C),
    balloonColors: [
      Color(0xFFFF9100),
      Color(0xFFFF3D00),
      Color(0xFFFF4081),
      Color(0xFF7C4DFF),
    ],
    glowColor: Color(0x66FF9100),
    goldGlowColor: Color(0xAAFFEA00),
  ),
  SkinDef(
    id: 'mystic_glow',
    name: 'Mystic Glow',
    description: 'Cool blues and purples with dreamy glow.',
    rarity: 'EPIC',
    price: 350,
    background: Color(0xFF020414),
    balloonColors: [
      Color(0xFF7C4DFF),
      Color(0xFF536DFE),
      Color(0xFF00B0FF),
      Color(0xFFAA00FF),
    ],
    glowColor: Color(0x6600B0FF),
    goldGlowColor: Color(0x88FFD54F),
  ),
];

SkinDef skinById(String id) {
  return allSkins.firstWhere(
    (s) => s.id == id,
    orElse: () => allSkins.first,
  );
}
