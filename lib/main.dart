import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(BalloonBurstApp(prefs: prefs));
}

/// ---------- DATA MODELS ----------

class TapJunkieSkin {
  final String id;
  final String name;
  final int cost;
  final bool legendary;

  /// base balloon colors
  final List<Color> balloonColors;

  /// glow color for normal balloons
  final Color glowColor;

  /// glow color for golden balloons
  final Color goldenGlowColor;

  /// bomb glow color
  final Color bombGlowColor;

  const TapJunkieSkin({
    required this.id,
    required this.name,
    required this.cost,
    required this.legendary,
    required this.balloonColors,
    required this.glowColor,
    required this.goldenGlowColor,
    required this.bombGlowColor,
  });
}

const classicMixSkin = TapJunkieSkin(
  id: 'classic',
  name: 'Classic Mix',
  cost: 0,
  legendary: false,
  balloonColors: [
    Color(0xFFFFD54F),
    Color(0xFF64B5F6),
    Color(0xFFBA68C8),
    Color(0xFF4DB6AC),
  ],
  glowColor: Color(0x33FFFFFF),
  goldenGlowColor: Color(0x66FFD54F),
  bombGlowColor: Color(0x66FF5252),
);

const neonCitySkin = TapJunkieSkin(
  id: 'neon_city',
  name: 'Neon City',
  cost: 250,
  legendary: false,
  balloonColors: [
    Color(0xFF00E5FF),
    Color(0xFFFF6E40),
    Color(0xFFE040FB),
    Color(0xFF69F0AE),
  ],
  glowColor: Color(0x6621CBF3),
  goldenGlowColor: Color(0xFFFFF176),
  bombGlowColor: Color(0x66FF1744),
);

const retroArcadeSkin = TapJunkieSkin(
  id: 'retro_arcade',
  name: 'Retro Arcade',
  cost: 300,
  legendary: false,
  balloonColors: [
    Color(0xFFFFC400),
    Color(0xFFFF3D00),
    Color(0xFF00E676),
    Color(0xFF2979FF),
  ],
  glowColor: Color(0x66FFAB40),
  goldenGlowColor: Color(0x66FFE082),
  bombGlowColor: Color(0x88FF1744),
);

const mysticGlowSkin = TapJunkieSkin(
  id: 'mystic_glow',
  name: 'Mystic Glow',
  cost: 350,
  legendary: false,
  balloonColors: [
    Color(0xFF7C4DFF),
    Color(0xFF448AFF),
    Color(0xFF00E5FF),
    Color(0xFFE040FB),
  ],
  glowColor: Color(0x663F51B5),
  goldenGlowColor: Color(0x66FFF59D),
  bombGlowColor: Color(0x88D32F2F),
);

const cosmicBurstSkin = TapJunkieSkin(
  id: 'cosmic_burst',
  name: 'Cosmic Burst',
  cost: 400,
  legendary: false,
  balloonColors: [
    Color(0xFF00E5FF),
    Color(0xFF69F0AE),
    Color(0xFFFFD740),
    Color(0xFF7C4DFF),
  ],
  glowColor: Color(0x663F51B5),
  goldenGlowColor: Color(0x66FFE57F),
  bombGlowColor: Color(0x88FF1744),
);

const junkieJuiceSkin = TapJunkieSkin(
  id: 'junkie_juice',
  name: 'Junkie Juice',
  cost: 500,
  legendary: true,
  balloonColors: [
    Color(0xFF00FF95), // toxic lime
    Color(0xFFFF2FB3), // hot pink
    Color(0xFF00F0FF),
    Color(0xFF9B5CFF),
  ],
  glowColor: Color(0x6600FF95),
  goldenGlowColor: Color(0x88FFFF00),
  bombGlowColor: Color(0xAAFF1744),
);

const allSkins = <TapJunkieSkin>[
  classicMixSkin,
  neonCitySkin,
  retroArcadeSkin,
  mysticGlowSkin,
  cosmicBurstSkin,
  junkieJuiceSkin,
];

TapJunkieSkin skinById(String id) =>
    allSkins.firstWhere((s) => s.id == id, orElse: () => classicMixSkin);

class DailyMission {
  final String id;
  final String description;
  final int target;
  final int reward;
  int progress;
  bool completed;

  DailyMission({
    required this.id,
    required this.description,
    required this.target,
    required this.reward,
    this.progress = 0,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'target': target,
        'reward': reward,
        'progress': progress,
        'completed': completed,
      };

  factory DailyMission.fromJson(Map<String, dynamic> json) => DailyMission(
        id: json['id'] as String,
        description: json['description'] as String,
        target: json['target'] as int,
        reward: json['reward'] as int,
        progress: json['progress'] as int,
        completed: json['completed'] as bool,
      );
}

class GameResult {
  final int score;
  final int coinsThisRun;
  final int comboBestThisRun;
  final int livesLeft;
  final int frenzyTriggers;

  final List<DailyMission> missions;

  GameResult({
    required this.score,
    required this.coinsThisRun,
    required this.comboBestThisRun,
    required this.livesLeft,
    required this.frenzyTriggers,
    required this.missions,
  });
}

/// ---------- APP & MAIN MENU ----------

class BalloonBurstApp extends StatefulWidget {
  final SharedPreferences prefs;
  const BalloonBurstApp({super.key, required this.prefs});

  @override
  State<BalloonBurstApp> createState() => _BalloonBurstAppState();
}

class _BalloonBurstAppState extends State<BalloonBurstApp> {
  late int highScore;
  late int bestCombo;
  late int lastScore;
  late int coins;
  late int dailyStreak;
  late List<DailyMission> missions;
  late TapJunkieSkin equippedSkin;

  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final p = widget.prefs;
    highScore = p.getInt('high_score') ?? 0;
    bestCombo = p.getInt('best_combo') ?? 0;
    lastScore = p.getInt('last_score') ?? 0;
    coins = p.getInt('coins') ?? 50;
    dailyStreak = _calculateDailyStreak(p);
    equippedSkin = skinById(p.getString('equipped_skin') ?? 'classic');

    missions = _loadOrGenerateMissions(p);
    _loaded = true;
    setState(() {});
  }

  int _calculateDailyStreak(SharedPreferences p) {
    final lastDate = p.getString('last_play_date');
    final today = DateTime.now();

    if (lastDate == null) {
      p.setString('last_play_date',
          DateTime(today.year, today.month, today.day).toIso8601String());
      p.setInt('daily_streak', 1);
      return 1;
    }

    final parsed = DateTime.tryParse(lastDate) ??
        DateTime(today.year, today.month, today.day);
    final diff = today.difference(parsed).inDays;

    if (diff == 0) {
      return p.getInt('daily_streak') ?? 1;
    }
    if (diff == 1) {
      final streak = (p.getInt('daily_streak') ?? 1) + 1;
      p.setInt('daily_streak', streak);
      p.setString('last_play_date',
          DateTime(today.year, today.month, today.day).toIso8601String());
      return streak;
    }

    p.setInt('daily_streak', 1);
    p.setString('last_play_date',
        DateTime(today.year, today.month, today.day).toIso8601String());
    return 1;
  }

  List<DailyMission> _loadOrGenerateMissions(SharedPreferences p) {
    final todayKey =
        '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
    final savedDate = p.getString('missions_date');

    if (savedDate == todayKey) {
      final raw = p.getStringList('missions');
      if (raw != null) {
        return raw
            .map((s) =>
                DailyMission.fromJson(Map<String, dynamic>.from(_decode(s))))
            .toList();
      }
    }

    final random = Random();
    final missions = <DailyMission>[
      DailyMission(
        id: 'score_${random.nextInt(200) + 600}',
        description: 'Score ${(random.nextInt(200) + 600)}+ in a run',
        target: random.nextInt(200) + 600,
        reward: 100,
      ),
      DailyMission(
        id: 'combo_${random.nextInt(10) + 12}',
        description: 'Reach combo ${(random.nextInt(10) + 12)}+',
        target: random.nextInt(10) + 12,
        reward: 100,
      ),
      DailyMission(
        id: 'frenzy_${random.nextInt(3) + 2}',
        description: 'Trigger Frenzy ${(random.nextInt(3) + 2)} time(s)',
        target: random.nextInt(3) + 2,
        reward: 100,
      ),
    ];

    p.setString('missions_date', todayKey);
    p.setStringList(
        'missions', missions.map((m) => _encode(m.toJson())).toList());

    return missions;
  }

  static String _encode(Map<String, dynamic> map) => map.toString();

  static Map<String, dynamic> _decode(String s) {
    // VERY small & controlled: we stored as Map.toString(). We’ll parse back.
    final trimmed = s.substring(1, s.length - 1); // remove { }
    final parts = trimmed.split(', ');
    final result = <String, dynamic>{};
    for (final part in parts) {
      final idx = part.indexOf(':');
      if (idx == -1) continue;
      final k = part.substring(0, idx);
      final v = part.substring(idx + 2); // skip ": "
      if (int.tryParse(v) != null) {
        result[k] = int.parse(v);
      } else if (v == 'true' || v == 'false') {
        result[k] = v == 'true';
      } else {
        result[k] = v;
      }
    }
    return result;
  }

  Future<void> _startGame(BuildContext context) async {
    if (!_loaded) return;

    final result = await Navigator.of(context).push<GameResult>(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          prefs: widget.prefs,
          equippedSkin: equippedSkin,
          missions: missions.map((m) => DailyMission(
                id: m.id,
                description: m.description,
                target: m.target,
                reward: m.reward,
                progress: m.progress,
                completed: m.completed,
              )).toList(),
        ),
      ),
    );

    if (result == null) return;

    // Update stats and missions
    setState(() {
      lastScore = result.score;
      highScore = max(highScore, result.score);
      bestCombo = max(bestCombo, result.comboBestThisRun);
      coins += result.coinsThisRun;

      for (final resM in result.missions) {
        final idx = missions.indexWhere((m) => m.id == resM.id);
        if (idx != -1) {
          missions[idx] = resM;
          if (resM.completed) {
            coins += resM.reward;
          }
        }
      }
    });

    final p = widget.prefs;
    p.setInt('high_score', highScore);
    p.setInt('best_combo', bestCombo);
    p.setInt('last_score', lastScore);
    p.setInt('coins', coins);
    p.setStringList(
      'missions',
      missions.map((m) => _encode(m.toJson())).toList(),
    );
  }

  Future<void> _openShop(BuildContext context) async {
    final owned = widget.prefs.getStringList('owned_skins') ?? ['classic'];
    final result = await Navigator.of(context).push<_ShopResult>(
      MaterialPageRoute(
        builder: (_) => ShopScreen(
          prefs: widget.prefs,
          coins: coins,
          equipped: equippedSkin,
          ownedSkinIds: owned,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      coins = result.coins;
      equippedSkin = result.equippedSkin;
    });

    final p = widget.prefs;
    p.setInt('coins', coins);
    p.setString('equipped_skin', equippedSkin.id);
    p.setStringList('owned_skins', result.ownedSkinIds);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF050814),
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Balloon Burst',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050814),
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'Roboto',
            ),
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF050814),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                const Text(
                  'BALLOON BURST',
                  style: TextStyle(
                    fontSize: 32,
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF4F9A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Text(
                  'High Score: $highScore',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Best Combo: $bestCombo',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF00E5FF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last Score: $lastScore',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Coins: $coins',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFFFFD54F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Equipped Skin: ${equippedSkin.name}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Daily streak: $dailyStreak day(s)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 24),
                _MissionsCard(missions: missions),
                const Spacer(),
                _PrimaryButton(
                  label: 'PLAY',
                  onTap: () => _startGame(context),
                ),
                const SizedBox(height: 12),
                _SecondaryButton(
                  label: 'SHOP',
                  onTap: () => _openShop(context),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------- MAIN MENU WIDGET HELPERS ----------

class _MissionsCard extends StatelessWidget {
  final List<DailyMission> missions;
  const _MissionsCard({required this.missions});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1020),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Missions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00E5FF),
            ),
          ),
          const SizedBox(height: 12),
          for (final m in missions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    m.completed ? Icons.check_circle : Icons.radio_button_off,
                    size: 18,
                    color: m.completed ? Colors.greenAccent : Colors.white38,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      m.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF25293A),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE0D4FF),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF5C6BC0)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9FA8DA),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------- GAME SCREEN + FLAME GAME ----------

class GameScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final TapJunkieSkin equippedSkin;
  final List<DailyMission> missions;

  const GameScreen({
    super.key,
    required this.prefs,
    required this.equippedSkin,
    required this.missions,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late BalloonGame _game;

  @override
  void initState() {
    super.initState();
    _game = BalloonGame(
      equippedSkin: widget.equippedSkin,
      missions: widget.missions,
      onGameOver: (result) {
        Navigator.of(context).pop(result);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050814),
      body: GameWidget(game: _game),
    );
  }
}

class BalloonGame extends FlameGame with HasCollisionDetection {
  final TapJunkieSkin equippedSkin;
  final List<DailyMission> missions;
  final void Function(GameResult) onGameOver;

  BalloonGame({
    required this.equippedSkin,
    required this.missions,
    required this.onGameOver,
  });

  final Random _random = Random();

  int score = 0;
  int coins = 0;
  int lives = 3;
  int combo = 0;
  int bestComboThisRun = 0;
  int frenzyTriggers = 0;

  double _spawnTimer = 0;
  double _spawnInterval = 0.9;

  bool inFrenzy = false;
  double frenzyTimer = 0;
  double frenzyDuration = 6.0;

  final int frenzyComboThreshold = 12;

  bool _gameOverSent = false;

  @override
  Color backgroundColor() => const Color(0xFF050814);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(ScreenHitbox());

    add(
      TextComponent(
        text: '',
        position: Vector2(8, 8),
        priority: 10,
      )..add(
          TimerComponent(
            period: 0.05,
            repeat: true,
            onTick: () {
              final textComponent = children
                  .whereType<TextComponent>()
                  .firstWhere((c) => c.position.x == 8 && c.position.y == 8);
              textComponent.text =
                  'Score: $score\nLives: $lives\nCoins: $coins\nCombo: $combo';
            },
          ),
        ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_gameOverSent) return;

    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      _spawnBalloon();
    }

    if (inFrenzy) {
      frenzyTimer -= dt;
      if (frenzyTimer <= 0) {
        inFrenzy = false;
        _spawnInterval = 0.9;
      }
    }

    if (lives <= 0 && !_gameOverSent) {
      _gameOverSent = true;
      _finishGame();
    }
  }

  void _spawnBalloon() {
    final isBomb = _random.nextDouble() < 0.12;
    final isGolden = !isBomb && _random.nextDouble() < 0.08;

    final radius = isGolden ? 22.0 : 16.0;

    final x = _random.nextDouble() * (size.x - radius * 2) + radius;
    final y = size.y + radius + 10;

    final baseSpeed = inFrenzy ? 130.0 : 90.0;
    final speed = baseSpeed + _random.nextDouble() * 70;

    final normalColors = equippedSkin.balloonColors;

    final color = isBomb
        ? const Color(0xFFFF5252)
        : (isGolden ? const Color(0xFFFFD54F) : normalColors[_random.nextInt(normalColors.length)]);

    final glowColor = isBomb
        ? equippedSkin.bombGlowColor
        : (isGolden ? equippedSkin.goldenGlowColor : equippedSkin.glowColor);

    final balloon = Balloon(
      position: Vector2(x, y),
      radius: radius,
      speed: speed,
      color: color,
      glowColor: glowColor,
      isBomb: isBomb,
      isGolden: isGolden,
      onPopped: _handleBalloonPopped,
      onMissed: _handleBalloonMissed,
    );

    add(balloon);
  }

  void _handleBalloonPopped(Balloon balloon) {
    if (balloon.isBomb) {
      // Option A: ONLY tapping bombs hurts you
      lives = max(0, lives - 1);
      combo = 0;
      return;
    }

    final basePoints = balloon.isGolden ? 15 : 5;
    final baseCoins = balloon.isGolden ? 10 : 1;

    final multiplier = inFrenzy ? 2 : 1;

    score += basePoints * multiplier;
    coins += baseCoins * multiplier;
    combo += 1;
    bestComboThisRun = max(bestComboThisRun, combo);

    if (!inFrenzy && combo >= frenzyComboThreshold) {
      inFrenzy = true;
      frenzyTimer = frenzyDuration;
      _spawnInterval = 0.55;
      frenzyTriggers += 1;
    }

    _updateMissionsOnPop(balloon);
  }

  void _handleBalloonMissed(Balloon balloon) {
    // Missing bombs is SAFE with Option A locked in.
    if (!balloon.isBomb) {
      lives = max(0, lives - 1);
    }
    combo = 0;
  }

  void _updateMissionsOnPop(Balloon balloon) {
    for (final m in missions) {
      if (m.completed) continue;

      if (m.id.startsWith('score_')) {
        if (score >= m.target) {
          m.completed = true;
        }
      } else if (m.id.startsWith('combo_')) {
        if (bestComboThisRun >= m.target) {
          m.completed = true;
        }
      } else if (m.id.startsWith('frenzy_')) {
        if (frenzyTriggers >= m.target) {
          m.completed = true;
        }
      }
    }
  }

  void _finishGame() {
    final result = GameResult(
      score: score,
      coinsThisRun: coins,
      comboBestThisRun: bestComboThisRun,
      livesLeft: lives,
      frenzyTriggers: frenzyTriggers,
      missions: missions,
    );

    // Flame Game can't directly call Navigator, but our GameScreen passed a callback.
    onGameOver(result);
  }
}

/// ---------- BALLOON COMPONENT ----------

class Balloon extends PositionComponent
    with TapCallbacks, HasGameRef<BalloonGame> {
  final double radius;
  final double speed;
  final Color color;
  final Color glowColor;
  final bool isBomb;
  final bool isGolden;

  final void Function(Balloon) onPopped;
  final void Function(Balloon) onMissed;

  Balloon({
    required Vector2 position,
    required this.radius,
    required this.speed,
    required this.color,
    required this.glowColor,
    required this.isBomb,
    required this.isGolden,
    required this.onPopped,
    required this.onMissed,
  }) {
    this.position = position;
    size = Vector2.all(radius * 2);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(
      CircleHitbox()
        ..radius = radius
        ..anchor = Anchor.center
        ..collisionType = CollisionType.inactive,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= speed * dt;
    if (position.y + radius < 0) {
      onMissed(this);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final glowPaint = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(radius, radius), radius * 1.8, glowPaint);

    final balloonPaint = Paint()..color = color;
    canvas.drawCircle(Offset(radius, radius), radius, balloonPaint);

    if (isBomb) {
      final center = Offset(radius, radius);
      final pulsePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withOpacity(0.9);
      canvas.drawCircle(center, radius * 0.55, pulsePaint);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    onPopped(this);
    removeFromParent();
  }
}

/// ---------- SHOP ----------

class _ShopResult {
  final int coins;
  final TapJunkieSkin equippedSkin;
  final List<String> ownedSkinIds;

  _ShopResult({
    required this.coins,
    required this.equippedSkin,
    required this.ownedSkinIds,
  });
}

class ShopScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final int coins;
  final TapJunkieSkin equipped;
  final List<String> ownedSkinIds;

  const ShopScreen({
    super.key,
    required this.prefs,
    required this.coins,
    required this.equipped,
    required this.ownedSkinIds,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late int _coins;
  late TapJunkieSkin _equipped;
  late List<String> _owned;

  TapJunkieSkin? _selected;

  @override
  void initState() {
    super.initState();
    _coins = widget.coins;
    _equipped = widget.equipped;
    _owned = [...widget.ownedSkinIds];
    _selected = _equipped;
  }

  bool get _selectedOwned =>
      _selected != null && _owned.contains(_selected!.id);

  bool get _selectedEquipped =>
      _selected != null && _equipped.id == _selected!.id;

  String get _bottomLabel {
    if (_selected == null) return '';
    if (_selectedEquipped) return 'Equipped';
    if (_selectedOwned) return 'Equip';
    if (_coins < _selected!.cost) return 'Not enough coins';
    return 'Buy for ${_selected!.cost}';
  }

  void _onBottomButton() {
    if (_selected == null) return;
    final skin = _selected!;

    if (_selectedEquipped) return;

    if (_selectedOwned) {
      setState(() {
        _equipped = skin;
      });
      return;
    }

    if (_coins < skin.cost) return;

    setState(() {
      _coins -= skin.cost;
      _owned.add(skin.id);
      _equipped = skin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050814),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050814),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'TapJunkie Shop',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFFFFD54F)),
              const SizedBox(width: 4),
              Text(
                '$_coins',
                style: const TextStyle(color: Color(0xFFFFD54F)),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_selected != null) _SelectedSkinHeader(skin: _selected!),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (final skin in allSkins)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selected = skin;
                        });
                      },
                      child: _SkinCard(
                        skin: skin,
                        owned: _owned.contains(skin.id),
                        equipped: _equipped.id == skin.id,
                        selected: _selected?.id == skin.id,
                      ),
                    ),
                ],
              ),
            ),
            // BIG bottom button with extra padding to avoid nav bar overlap.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: GestureDetector(
                onTap: _onBottomButton,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _bottomLabel == 'Not enough coins'
                        ? Colors.grey.shade800
                        : const Color(0xFF25293A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: Text(
                      _bottomLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE0D4FF),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 0,
        child: Container(), // keeps nav bar area reserved
      ),
    );
  }

  @override
  void dispose() {
    Navigator.of(context).pop(
      _ShopResult(
        coins: _coins,
        equippedSkin: _equipped,
        ownedSkinIds: _owned,
      ),
    );
    super.dispose();
  }
}

class _SelectedSkinHeader extends StatelessWidget {
  final TapJunkieSkin skin;
  const _SelectedSkinHeader({required this.skin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            skin.balloonColors.first,
            skin.balloonColors.last,
          ],
        ),
        border: Border.all(
          color: skin.legendary ? const Color(0xFFFFD54F) : Colors.white24,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: skin.glowColor,
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
              gradient: LinearGradient(
                colors: skin.balloonColors,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skin.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  skin.legendary ? 'LEGENDARY' : 'Skin',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                    color: skin.legendary
                        ? const Color(0xFFFFD54F)
                        : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          if (skin.cost > 0)
            Text(
              '${skin.cost}c',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFFFFD54F),
              ),
            ),
        ],
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  final TapJunkieSkin skin;
  final bool owned;
  final bool equipped;
  final bool selected;

  const _SkinCard({
    required this.skin,
    required this.owned,
    required this.equipped,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: skin.balloonColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? Colors.white : Colors.transparent,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 4,
            top: 4,
            child: Text(
              skin.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Text(
              skin.cost == 0 ? '' : '${skin.cost}c',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
          if (equipped)
            const Positioned(
              left: 4,
              bottom: 4,
              child: Text(
                'Equipped',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (owned)
            const Positioned(
              left: 4,
              bottom: 4,
              child: Text(
                'Owned',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

