import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BalloonBurstApp());
}

/// Root Flutter app
class BalloonBurstApp extends StatelessWidget {
  const BalloonBurstApp({super.key});

  @override
  Widget build(BuildContext context) {
    final game = BalloonGame();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Balloon Burst',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050816),
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'Roboto',
            ),
      ),
      home: Scaffold(
        body: GameWidget<BalloonGame>(
          game: game,
          overlayBuilderMap: {
            'mainMenu': (context, game) => MainMenuOverlay(game: game),
            'gameOver': (context, game) => GameOverOverlay(game: game),
            'shop': (context, game) => ShopOverlay(game: game),
          },
          initialActiveOverlays: const ['mainMenu'],
        ),
      ),
    );
  }
}

/// ==== SKIN SYSTEM ==========================================================

class SkinDef {
  final String id;
  final String name;
  final String description;
  final int price;
  final List<Color> palette;
  final Color accent;
  final bool legendary;

  const SkinDef({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.palette,
    required this.accent,
    this.legendary = false,
  });
}

const classicMixSkin = SkinDef(
  id: 'classic',
  name: 'Classic Mix',
  description: 'Original TapJunkie balloon colors.',
  price: 0,
  palette: [
    Color(0xFFFCD34D),
    Color(0xFF60A5FA),
    Color(0xFF34D399),
    Color(0xFFF97373),
    Color(0xFFA855F7),
  ],
  accent: Color(0xFFFCD34D),
);

const neonCitySkin = SkinDef(
  id: 'neon',
  name: 'Neon City',
  description: 'Electric cyan, magenta and violet.',
  price: 250,
  palette: [
    Color(0xFF22D3EE),
    Color(0xFFEC4899),
    Color(0xFFA855F7),
    Color(0xFF4ADE80),
  ],
  accent: Color(0xFF22D3EE),
);

const retroArcadeSkin = SkinDef(
  id: 'retro',
  name: 'Retro Arcade',
  description: 'Warm oranges and synthwave sunset.',
  price: 300,
  palette: [
    Color(0xFFFB923C),
    Color(0xFFF97316),
    Color(0xFFEC4899),
    Color(0xFFEAB308),
  ],
  accent: Color(0xFFF97316),
);

const mysticGlowSkin = SkinDef(
  id: 'mystic',
  name: 'Mystic Glow',
  description: 'Deep purple, blue and magic vibes.',
  price: 350,
  palette: [
    Color(0xFF6366F1),
    Color(0xFF22C55E),
    Color(0xFFA855F7),
    Color(0xFF0EA5E9),
  ],
  accent: Color(0xFF6366F1),
);

const cosmicBurstSkin = SkinDef(
  id: 'cosmic',
  name: 'Cosmic Burst',
  description: 'Space-grade gradients and starlight.',
  price: 400,
  palette: [
    Color(0xFF22D3EE),
    Color(0xFFA855F7),
    Color(0xFFFACC15),
    Color(0xFF4ADE80),
  ],
  accent: Color(0xFFF97316),
);

const junkieJuiceSkin = SkinDef(
  id: 'junkie',
  name: 'Junkie Juice',
  description: 'TapJunkie legendary toxic-lime & hot pink.',
  price: 500,
  palette: [
    Color(0xFF22C55E),
    Color(0xFFEC4899),
    Color(0xFFFACC15),
    Color(0xFF0EA5E9),
  ],
  accent: Color(0xFF22C55E),
  legendary: true,
);

const allSkins = <SkinDef>[
  classicMixSkin,
  neonCitySkin,
  retroArcadeSkin,
  mysticGlowSkin,
  cosmicBurstSkin,
  junkieJuiceSkin,
];

SkinDef skinById(String id) {
  return allSkins.firstWhere(
    (s) => s.id == id,
    orElse: () => classicMixSkin,
  );
}

/// ==== MISSIONS =============================================================

class DailyMissions {
  final int scoreTarget;
  final int comboTarget;
  final int frenzyTarget;

  bool scoreCompleted;
  bool comboCompleted;
  bool frenzyCompleted;

  DailyMissions({
    required this.scoreTarget,
    required this.comboTarget,
    required this.frenzyTarget,
    this.scoreCompleted = false,
    this.comboCompleted = false,
    this.frenzyCompleted = false,
  });

  bool get allCompleted =>
      scoreCompleted && comboCompleted && frenzyCompleted;
}

/// ==== GAME ENUMS ===========================================================

enum BalloonType { normal, golden, bomb, lightning }

/// ==== MAIN GAME ============================================================

class BalloonGame extends FlameGame with HasTappables {
  BalloonGame();

  final Random rng = Random();

  // Core run state
  int score = 0;
  int bestComboThisRun = 0;
  int combo = 0;
  int lives = 3;
  int coinsThisRun = 0;
  bool _gameOver = false;

  // Persistent stats
  int highScore = 0;
  int bestComboEver = 0;
  int totalCoins = 0;
  int lastScore = 0;
  int dailyStreak = 1;

  // Frenzy
  bool inFrenzy = false;
  double _frenzyTimer = 0;
  int frenzyTriggersThisRun = 0;

  // Spawning
  double _spawnTimer = 0;
  double _spawnInterval = 0.8;

  // Missions
  late DailyMissions missions;

  // Skins
  SkinDef skin = classicMixSkin;
  final Set<String> ownedSkinIds = {'classic'};
  SharedPreferences? _prefs;

  // For mission display on GameOver
  final List<String> completedMissionMessages = [];

  // HUD
  late TextPaint hudWhite;
  late TextPaint hudYellow;
  late TextPaint hudCyan;
  late TextPaint hudRed;

  @override
  Color backgroundColor() => const Color(0xFF050816);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    hudWhite = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
    );
    hudYellow = TextPaint(
      style: const TextStyle(
        color: Color(0xFFFACC15),
        fontSize: 14,
      ),
    );
    hudCyan = TextPaint(
      style: const TextStyle(
        color: Color(0xFF22D3EE),
        fontSize: 14,
      ),
    );
    hudRed = TextPaint(
      style: const TextStyle(
        color: Color(0xFFEF4444),
        fontSize: 14,
      ),
    );

    await _loadPrefs();
    _loadPersistentState();
    _loadMissionsForToday();

    pauseEngine();
  }

  Future<void> _loadPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  void _loadPersistentState() {
    final p = _prefs;
    if (p == null) return;

    highScore = p.getInt('bb_highScore') ?? 0;
    bestComboEver = p.getInt('bb_bestCombo') ?? 0;
    totalCoins = p.getInt('bb_totalCoins') ?? 50;
    lastScore = p.getInt('bb_lastScore') ?? 0;
    dailyStreak = p.getInt('bb_dailyStreak') ?? 1;

    final equippedId = p.getString('bb_skin_equipped') ?? 'classic';
    skin = skinById(equippedId);

    final owned = p.getStringList('bb_ownedSkins') ?? ['classic'];
    ownedSkinIds
      ..clear()
      ..addAll(owned);

    // Daily login bonus
    final today = DateTime.now();
    final lastPlayStr = p.getString('bb_lastPlayDate');
    DateTime? lastPlay;
    if (lastPlayStr != null) {
      lastPlay = DateTime.tryParse(lastPlayStr);
    }

    if (lastPlay == null) {
      p.setString('bb_lastPlayDate', today.toIso8601String());
    } else {
      final diff = today.difference(
        DateTime(lastPlay.year, lastPlay.month, lastPlay.day),
      ).inDays;
      if (diff == 0) {
        // same day, streak unchanged
      } else if (diff == 1) {
        dailyStreak += 1;
        totalCoins += 25;
      } else if (diff > 1) {
        dailyStreak = 1;
      }
      p
        ..setInt('bb_dailyStreak', dailyStreak)
        ..setInt('bb_totalCoins', totalCoins)
        ..setString('bb_lastPlayDate', today.toIso8601String());
    }
  }

  void _loadMissionsForToday() {
    // Simple: regenerate each day based on date hash.
    final now = DateTime.now();
    final seed =
        now.year * 10000 + now.month * 100 + now.day; // crude but fine
    final r = Random(seed);

    missions = DailyMissions(
      scoreTarget: 600 + r.nextInt(401), // 600–1000
      comboTarget: 15 + r.nextInt(10), // 15–24
      frenzyTarget: 2 + r.nextInt(3), // 2–4
    );
  }

  Future<void> _savePersistentState() async {
    final p = _prefs;
    if (p == null) return;
    await p.setInt('bb_highScore', highScore);
    await p.setInt('bb_bestCombo', bestComboEver);
    await p.setInt('bb_totalCoins', totalCoins);
    await p.setInt('bb_lastScore', lastScore);
    await p.setInt('bb_dailyStreak', dailyStreak);
    await p.setString('bb_skin_equipped', skin.id);
    await p.setStringList('bb_ownedSkins', ownedSkinIds.toList());
  }

  // Public helpers for overlays

  void equipSkin(SkinDef s) {
    skin = s;
    _savePersistentState();
  }

  bool isSkinOwned(String id) => ownedSkinIds.contains(id);

  bool canAfford(int price) => totalCoins >= price;

  void unlockAndEquipSkin(SkinDef s) {
    ownedSkinIds.add(s.id);
    totalCoins -= s.price;
    skin = s;
    _savePersistentState();
  }

  // Gameplay control

  void startGame() {
    score = 0;
    combo = 0;
    bestComboThisRun = 0;
    lives = 3;
    coinsThisRun = 0;
    _spawnInterval = 0.8;
    _spawnTimer = 0;
    inFrenzy = false;
    _frenzyTimer = 0;
    frenzyTriggersThisRun = 0;
    _gameOver = false;
    completedMissionMessages.clear();

    children.whereType<Balloon>().forEach((b) => b.removeFromParent());

    overlays.remove('gameOver');
    overlays.remove('mainMenu');
    resumeEngine();
  }

  void goToMenu() {
    overlays.remove('gameOver');
    overlays.add('mainMenu');
    pauseEngine();
  }

  void _triggerFrenzy() {
    inFrenzy = true;
    _frenzyTimer = 8;
    frenzyTriggersThisRun += 1;
  }

  void _endFrenzy() {
    inFrenzy = false;
    _frenzyTimer = 0;
  }

  void handleBalloonTap(Balloon b) {
    if (_gameOver) return;

    switch (b.type) {
      case BalloonType.normal:
        combo += 1;
        final added = 10 + (combo ~/ 3);
        score += added;
        coinsThisRun += 1;
        if (combo > bestComboThisRun) {
          bestComboThisRun = combo;
        }
        // Frenzy trigger based on combo
        if (!inFrenzy && combo >= 20) {
          _triggerFrenzy();
        }
        break;
      case BalloonType.golden:
        combo += 2;
        score += 75;
        coinsThisRun += 25;
        if (combo > bestComboThisRun) {
          bestComboThisRun = combo;
        }
        if (!inFrenzy) {
          _triggerFrenzy();
        }
        break;
      case BalloonType.lightning:
        combo += 1;
        score += 25;
        coinsThisRun += 5;
        if (combo > bestComboThisRun) {
          bestComboThisRun = combo;
        }
        _triggerFrenzy();
        break;
      case BalloonType.bomb:
        // Bombs only punish on tap – NOT on escape.
        lives -= 1;
        combo = 0;
        if (lives <= 0) {
          _onGameOver();
        }
        break;
    }

    b.removeFromParent();
  }

  void handleMiss() {
    if (_gameOver) return;
    lives -= 1;
    combo = 0;
    if (lives <= 0) {
      _onGameOver();
    }
  }

  void _evaluateMissions() {
    if (score >= missions.scoreTarget) {
      missions.scoreCompleted = true;
    }
    if (bestComboThisRun >= missions.comboTarget) {
      missions.comboCompleted = true;
    }
    if (frenzyTriggersThisRun >= missions.frenzyTarget) {
      missions.frenzyCompleted = true;
    }

    int bonus = 0;
    if (missions.scoreCompleted) {
      bonus += 100;
      completedMissionMessages
          .add('Mission complete: Score ${missions.scoreTarget}+ (+100 coins)');
    }
    if (missions.comboCompleted) {
      bonus += 100;
      completedMissionMessages.add(
          'Mission complete: Reach combo ${missions.comboTarget}+ (+100 coins)');
    }
    if (missions.frenzyCompleted) {
      bonus += 100;
      completedMissionMessages
          .add('Mission complete: Trigger Frenzy ${missions.frenzyTarget}x (+100 coins)');
    }
    if (bonus > 0) {
      totalCoins += bonus;
    }
  }

  void _onGameOver() {
    if (_gameOver) return;
    _gameOver = true;
    lastScore = score;
    totalCoins += coinsThisRun;

    if (score > highScore) {
      highScore = score;
    }
    if (bestComboThisRun > bestComboEver) {
      bestComboEver = bestComboThisRun;
    }

    _evaluateMissions();

    _savePersistentState();
    pauseEngine();
    overlays.add('gameOver');
  }

  void spawnBalloon() {
    if (_gameOver || size.x <= 0 || size.y <= 0) return;

    final radius = 20 + rng.nextDouble() * 25;
    final x = radius + rng.nextDouble() * (size.x - radius * 2);
    final position = Vector2(x, size.y + radius + 20);

    final roll = rng.nextDouble();
    BalloonType type;
    if (roll < 0.08) {
      type = BalloonType.golden;
    } else if (roll < 0.13) {
      type = BalloonType.bomb;
    } else if (roll < 0.18) {
      type = BalloonType.lightning;
    } else {
      type = BalloonType.normal;
    }

    double speed = 120 + score * 0.45;
    if (inFrenzy) speed *= 1.7;

    final currentSkin = skin;
    final baseColor = _colorForType(type, currentSkin);

    add(
      Balloon(
        skin: currentSkin,
        type: type,
        radius: radius,
        position: position,
        speed: speed,
        baseColor: baseColor,
      ),
    );
  }

  Color _colorForType(BalloonType type, SkinDef s) {
    switch (type) {
      case BalloonType.golden:
        return Colors.amberAccent;
      case BalloonType.bomb:
        return const Color(0xFFEF5350);
      case BalloonType.lightning:
        return Colors.lightBlueAccent;
      case BalloonType.normal:
      default:
        final palette = s.palette;
        if (palette.isEmpty) return Colors.white;
        return palette[rng.nextInt(palette.length)];
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameOver) return;

    // Spawning
    _spawnTimer += dt;
    final minInterval = 0.35;
    _spawnInterval = 0.8 - (score / 1200).clamp(0, 0.45);
    if (_spawnInterval < minInterval) _spawnInterval = minInterval;

    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      spawnBalloon();
    }

    // Frenzy timer
    if (inFrenzy) {
      _frenzyTimer -= dt;
      if (_frenzyTimer <= 0) {
        _endFrenzy();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // HUD
    double y = 8;
    hudWhite.render(canvas, 'Score: $score', Vector2(8, y));
    y += 16;
    hudRed.render(canvas, 'Lives: $lives', Vector2(8, y));
    y += 16;
    hudYellow.render(
        canvas, 'Coins: ${totalCoins + coinsThisRun}', Vector2(8, y));
    y += 16;
    hudCyan.render(canvas, 'Combo: $combo', Vector2(8, y));

    if (inFrenzy) {
      final frenzyPaint = TextPaint(
        style: const TextStyle(
          color: Color(0xFFFB7185),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      frenzyPaint.render(
        canvas,
        'FRENZY!',
        Vector2(size.x - 90, 10),
      );
    }
  }
}

/// ==== BALLOON COMPONENT (SKIN ENGINE C2) ===================================

class Balloon extends CircleComponent
    with TapCallbacks, HasGameRef<BalloonGame> {
  final double speed;
  final BalloonType type;
  final Color baseColor;
  final SkinDef skin;

  late final Paint glowPaint;
  late final Paint innerGlowPaint;
  double _time = 0;

  Balloon({
    required this.skin,
    required this.type,
    required double radius,
    required Vector2 position,
    required this.speed,
    required this.baseColor,
  }) : super(
          radius: radius,
          position: position,
          anchor: Anchor.center,
        ) {
    paint = Paint()..color = _computeCoreColor();

    glowPaint = Paint()
      ..color = _computeGlowColor().withOpacity(
        skin.legendary ? 0.95 : (type == BalloonType.normal ? 0.55 : 0.75),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    innerGlowPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    add(
      CircleHitbox()..collisionType = CollisionType.inactive,
    );
  }

  Color _computeCoreColor() {
    switch (type) {
      case BalloonType.golden:
        return Colors.amberAccent;
      case BalloonType.bomb:
        return Colors.redAccent;
      case BalloonType.lightning:
        return Colors.lightBlueAccent;
      case BalloonType.normal:
      default:
        return baseColor;
    }
  }

  Color _computeGlowColor() {
    switch (type) {
      case BalloonType.golden:
        return const Color(0xFFFFF176);
      case BalloonType.bomb:
        return const Color(0xFFFF5252);
      case BalloonType.lightning:
        return const Color(0xFF40C4FF);
      case BalloonType.normal:
      default:
        return skin.accent;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    position.y -= speed * dt;

    if (position.y < -radius) {
      if (type != BalloonType.bomb) {
        gameRef.handleMiss();
      }
      removeFromParent();
    }

    if (type == BalloonType.bomb) {
      final pulse = 0.5 + 0.3 * sin(_time * 8);
      glowPaint.color =
          glowPaint.color.withOpacity(pulse.clamp(0.25, 1.0).toDouble());
    }

    if (skin.legendary) {
      final wave = 0.6 + 0.4 * sin(_time * 6);
      final base = _computeGlowColor();
      glowPaint.color = base.withOpacity(wave.clamp(0.4, 1.0));
    }

    if (gameRef.inFrenzy && type == BalloonType.normal) {
      final idx = ((_time * 5).floor().abs()) % skin.palette.length;
      paint.color = skin.palette[idx];
    }
  }

  @override
  void render(Canvas canvas) {
    double auraRadius = radius * 1.6;
    if (skin.legendary) {
      auraRadius = radius * 1.9;
    } else if (type != BalloonType.normal) {
      auraRadius = radius * 1.8;
    }

    canvas.drawCircle(Offset.zero, auraRadius, glowPaint);

    final highlightOffset = const Offset(-6, -6);
    canvas.drawCircle(highlightOffset, radius * 0.7, innerGlowPaint);

    super.render(canvas);

    if (skin.legendary) {
      final starPaint =
          Paint()..color = Colors.white.withOpacity(0.5);
      const starRadius = 4.0;
      final center = Offset.zero;

      canvas.drawCircle(center, starRadius, starPaint);
      canvas.drawLine(
        center.translate(-starRadius * 1.5, 0),
        center.translate(starRadius * 1.5, 0),
        starPaint..strokeWidth = 1.5,
      );
      canvas.drawLine(
        center.translate(0, -starRadius * 1.5),
        center.translate(0, starRadius * 1.5),
        starPaint..strokeWidth = 1.5,
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    gameRef.handleBalloonTap(this);
  }
}

/// ==== FLUTTER OVERLAYS =====================================================

class MainMenuOverlay extends StatelessWidget {
  final BalloonGame game;
  const MainMenuOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final missions = game.missions;
    return SafeArea(
      child: Container(
        color: const Color(0xFF050816),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            const Text(
              'BALLOON BURST',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Color(0xFFF472B6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'High Score: ${game.highScore}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            Text(
              'Best Combo: ${game.bestComboEver}',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF22D3EE),
              ),
            ),
            Text(
              'Last Score: ${game.lastScore}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coins: ${game.totalCoins}',
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFFFACC15),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Equipped Skin: ${game.skin.name}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF22D3EE),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Daily streak: ${game.dailyStreak} day(s)',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1120),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Missions",
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF38BDF8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _missionRow(
                    completed: game.missions.scoreCompleted,
                    text: 'Score ${missions.scoreTarget}+ in a run',
                  ),
                  _missionRow(
                    completed: game.missions.comboCompleted,
                    text: 'Reach combo ${missions.comboTarget}+',
                  ),
                  _missionRow(
                    completed: game.missions.frenzyCompleted,
                    text:
                        'Trigger Frenzy ${missions.frenzyTarget} time(s)',
                  ),
                ],
              ),
            ),
            const Spacer(),
            _primaryButton(
              label: 'PLAY',
              onPressed: () {
                game.startGame();
              },
            ),
            const SizedBox(height: 12),
            _secondaryButton(
              label: 'SHOP',
              onPressed: () {
                game.overlays.add('shop');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _missionRow({required bool completed, required String text}) {
    return Row(
      children: [
        Icon(
          completed ? Icons.check_circle : Icons.circle_outlined,
          size: 18,
          color: completed ? Colors.greenAccent : Colors.white60,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: completed ? Colors.greenAccent : Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF6366F1)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  final BalloonGame game;
  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: const Color(0xFF020617),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            const Text(
              'GAME OVER',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF472B6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Score: ${game.score}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Best Combo (this run): ${game.bestComboThisRun}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Coins this run: ${game.coinsThisRun}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'High Score: ${game.highScore}',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF22D3EE),
              ),
            ),
            Text(
              'Best Combo: ${game.bestComboEver}',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF22D3EE),
              ),
            ),
            Text(
              'Total Coins: ${game.totalCoins}',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFFFACC15),
              ),
            ),
            const SizedBox(height: 24),
            if (game.completedMissionMessages.isNotEmpty) ...[
              const Text(
                'Missions Completed:',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.lightGreenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...game.completedMissionMessages.map(
                (m) => Text(
                  '• $m',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.lightGreenAccent,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () {
                  game.goToMenu();
                },
                child: const Text(
                  'Back to Menu',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// SHOP OVERLAY – with SafeArea & bottom padding for nav bar
class ShopOverlay extends StatefulWidget {
  final BalloonGame game;
  const ShopOverlay({super.key, required this.game});

  @override
  State<ShopOverlay> createState() => _ShopOverlayState();
}

class _ShopOverlayState extends State<ShopOverlay> {
  late SkinDef selected;

  BalloonGame get game => widget.game;

  @override
  void initState() {
    super.initState();
    selected = game.skin;
  }

  @override
  Widget build(BuildContext context) {
    final owned = game.isSkinOwned(selected.id);
    final equipped = game.skin.id == selected.id;
    final canAfford = game.canAfford(selected.price);

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    color: Colors.white70,
                    onPressed: () {
                      game.overlays.remove('shop');
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'TapJunkie Shop',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Color(0xFFFACC15),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${game.totalCoins}',
                        style: const TextStyle(
                          color: Color(0xFFFACC15),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Preview card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      selected.palette.first,
                      selected.palette.last,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: selected.legendary
                        ? const Color(0xFFFACC15)
                        : Colors.white24,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    // Balloon preview
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected.palette.first,
                        boxShadow: [
                          BoxShadow(
                            color: selected.accent.withOpacity(0.9),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: selected.legendary
                          ? const Icon(
                              Icons.star,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selected.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selected.legendary ? 'LEGENDARY' : '',
                            style: const TextStyle(
                              fontSize: 12,
                              letterSpacing: 2,
                              color: Color(0xFFFACC15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${selected.price}c',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          owned
                              ? (equipped ? 'Equipped' : 'Owned')
                              : 'Not owned',
                          style: TextStyle(
                            fontSize: 12,
                            color: owned
                                ? Colors.greenAccent
                                : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Grid of skins
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                  children: allSkins.map((s) {
                    final isOwned = game.isSkinOwned(s.id);
                    final isEquipped = game.skin.id == s.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selected = s;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              s.palette.first,
                              s.palette.last,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: selected.id == s.id
                                ? Colors.white
                                : Colors.white24,
                            width: selected.id == s.id ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (s.legendary)
                              const Text(
                                'LEGENDARY',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  color: Color(0xFFFACC15),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              isEquipped
                                  ? 'Equipped'
                                  : isOwned
                                      ? 'Owned'
                                      : '${s.price}c',
                              style: TextStyle(
                                fontSize: 12,
                                color: isEquipped
                                    ? Colors.greenAccent
                                    : isOwned
                                        ? Colors.white
                                        : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          final bottomInset = MediaQuery.of(context).padding.bottom;
          final owned = game.isSkinOwned(selected.id);
          final equipped = game.skin.id == selected.id;
          final canAfford = game.canAfford(selected.price);

          String label;
          VoidCallback? onPressed;

          if (equipped) {
            label = 'Equipped';
            onPressed = null;
          } else if (owned) {
            label = 'Equip';
            onPressed = () {
              setState(() {
                game.equipSkin(selected);
              });
            };
          } else {
            label = 'Buy for ${selected.price}';
            onPressed = canAfford
                ? () {
                    setState(() {
                      game.unlockAndEquipSkin(selected);
                    });
                  }
                : null;
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: bottomInset + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: onPressed == null
                      ? Colors.grey.shade700
                      : const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: onPressed,
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

