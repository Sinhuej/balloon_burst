import 'engine/momentum.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'game/balloon.dart';
import 'screens/game_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game/balloon_painter.dart';

// TapJunkie Engine (vendored inside repo)
import 'tj_engine/engine/momentum/momentum_manager.dart';
import 'tj_engine/engine/momentum/momentum_config.dart';
import 'tj_engine/engine/momentum/momentum_storage.dart';

/// ---------- ENTRY POINT ----------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

/// ---------- CORE APP ----------

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Balloon Burst',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050817),
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'Roboto',
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF4F9A),
          secondary: Color(0xFF00E0FF),
        ),
      ),
      home: MainMenu(prefs: prefs),
    );
  }
}

/// ---------- DATA MODELS ----------

class PlayerProfile {
  int highScore;
  int bestCombo;
  int lastScore;
  int totalCoins;

  /// Daily reward / streak
  int dailyStreak;
  DateTime? lastDailyClaimDate;

  /// Skins
  String equippedSkinId;
  Set<String> ownedSkins;

  PlayerProfile({
    required this.highScore,
    required this.bestCombo,
    required this.lastScore,
    required this.totalCoins,
    required this.dailyStreak,
    required this.lastDailyClaimDate,
    required this.equippedSkinId,
    required this.ownedSkins,
  });

  factory PlayerProfile.fromPrefs(SharedPreferences prefs) {
    final highScore = prefs.getInt('highScore') ?? 0;
    final bestCombo = prefs.getInt('bestCombo') ?? 0;
    final lastScore = prefs.getInt('lastScore') ?? 0;
    final totalCoins = prefs.getInt('totalCoins') ?? 50;

    final equippedSkinId = prefs.getString('equippedSkinId') ?? 'classic';
    final ownedSkinsList = prefs.getStringList('ownedSkins') ?? ['classic'];

    final lastClaimStr = prefs.getString('lastDailyClaimDate');
    DateTime? lastClaim;
    if (lastClaimStr != null) {
      lastClaim = DateTime.tryParse(lastClaimStr);
    }
    final dailyStreak = prefs.getInt('dailyStreak') ?? 0;

    return PlayerProfile(
      highScore: highScore,
      bestCombo: bestCombo,
      lastScore: lastScore,
      totalCoins: totalCoins,
      dailyStreak: dailyStreak,
      lastDailyClaimDate: lastClaim,
      equippedSkinId: equippedSkinId,
      ownedSkins: ownedSkinsList.toSet(),
    );
  }

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setInt('highScore', highScore);
    await prefs.setInt('bestCombo', bestCombo);
    await prefs.setInt('lastScore', lastScore);
    await prefs.setInt('totalCoins', totalCoins);
    await prefs.setString('equippedSkinId', equippedSkinId);
    await prefs.setStringList('ownedSkins', ownedSkins.toList());
    await prefs.setInt('dailyStreak', dailyStreak);
    if (lastDailyClaimDate != null) {
      await prefs.setString(
        'lastDailyClaimDate',
        lastDailyClaimDate!.toIso8601String(),
      );
    }
  }
}

enum MissionType { score, combo, frenzy }

class Mission {
  final String id;
  final MissionType type;
  final int target;
  bool completed;

  Mission({
    required this.id,
    required this.type,
    required this.target,
    this.completed = false,
  });

  String get description {
    switch (type) {
      case MissionType.score:
        return 'Score $target+ in a run';
      case MissionType.combo:
        return 'Reach combo $target+';
      case MissionType.frenzy:
        return 'Trigger Frenzy $target time(s)';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'target': target,
      'completed': completed,
    };
  }

  factory Mission.fromMap(Map<String, dynamic> map) {
    return Mission(
      id: map['id'] as String,
      type: MissionType.values[map['type'] as int],
      target: map['target'] as int,
      completed: (map['completed'] as bool?) ?? false,
    );
  }
}

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
    glowColor: Color(0x66536DFE),
    goldGlowColor: Color(0xAAFFF176),
  ),
  SkinDef(
    id: 'cosmic_burst',
    name: 'Cosmic Burst',
    description: 'Teal and cyan streaks from deep space.',
    rarity: 'EPIC',
    price: 400,
    background: Color(0xFF000815),
    balloonColors: [
      Color(0xFF00E5FF),
      Color(0xFF00BFA5),
      Color(0xFF18FFFF),
      Color(0xFF69F0AE),
    ],
    glowColor: Color(0x6600E5FF),
    goldGlowColor: Color(0xAAFFF59D),
  ),
  SkinDef(
    id: 'junkie_juice',
    name: 'Junkie Juice',
    description: 'TapJunkie legendary toxic-lime & hot pink.',
    rarity: 'LEGENDARY',
    price: 500,
    background: Color(0xFF001006),
    balloonColors: [
      Color(0xFF00FF6A),
      Color(0xFFFF4F9A),
      Color(0xFFFFFF00),
      Color(0xFF7CFC00),
    ],
    glowColor: Color(0x8800FF6A),
    goldGlowColor: Color(0xCCFFFF00),
  ),
];

SkinDef skinById(String id) {
  return allSkins.firstWhere(
    (s) => s.id == id,
    orElse: () => allSkins.first,
  );
}

/// ---------- GAME MODES ----------

enum GameMode { arcade, frenzy, chaos }

class GameModeConfig {
  final GameMode mode;
  final String name;
  final String tagline;
  final String description;
  final Color colorA;
  final Color colorB;

  final double spawnIntervalNormal;
  final double spawnIntervalFrenzy;
  final int maxBalloonsNormal;
  final int maxBalloonsFrenzy;

  final double baseSpeedScale;
  final double scoreMultiplier;
  final double coinMultiplier;

  final double goldenChance;
  final double goldenChanceFrenzy;
  final double bombChance;
  final double bombChanceFrenzy;

  const GameModeConfig({
    required this.mode,
    required this.name,
    required this.tagline,
    required this.description,
    required this.colorA,
    required this.colorB,
    required this.spawnIntervalNormal,
    required this.spawnIntervalFrenzy,
    required this.maxBalloonsNormal,
    required this.maxBalloonsFrenzy,
    required this.baseSpeedScale,
    required this.scoreMultiplier,
    required this.coinMultiplier,
    required this.goldenChance,
    required this.goldenChanceFrenzy,
    required this.bombChance,
    required this.bombChanceFrenzy,
  });
}

const Map<GameMode, GameModeConfig> kGameModeConfigs = {
  GameMode.arcade: GameModeConfig(
    mode: GameMode.arcade,
    name: 'Arcade',
    tagline: 'Smooth & chill',
    description: 'Relaxed pacing, generous spacing, perfect for new players.',
    colorA: Color(0xFF00E5FF),
    colorB: Color(0xFF00FF94),
    spawnIntervalNormal: 0.70,
    spawnIntervalFrenzy: 0.45,
    maxBalloonsNormal: 22,
    maxBalloonsFrenzy: 30,
    baseSpeedScale: 1.0,
    scoreMultiplier: 1.0,
    coinMultiplier: 1.0,
    goldenChance: 0.07,
    goldenChanceFrenzy: 0.22,
    bombChance: 0.09,
    bombChanceFrenzy: 0.11,
  ),
  GameMode.frenzy: GameModeConfig(
    mode: GameMode.frenzy,
    name: 'Frenzy',
    tagline: 'Chaotic & fast',
    description: 'Rapid spawns, higher risk, juiced coins and scores.',
    colorA: Color(0xFFFF4F9A),
    colorB: Color(0xFFFFC400),
    spawnIntervalNormal: 0.50,
    spawnIntervalFrenzy: 0.32,
    maxBalloonsNormal: 30,
    maxBalloonsFrenzy: 40,
    baseSpeedScale: 1.15,
    scoreMultiplier: 1.2,
    coinMultiplier: 1.3,
    goldenChance: 0.09,
    goldenChanceFrenzy: 0.27,
    bombChance: 0.11,
    bombChanceFrenzy: 0.14,
  ),
  GameMode.chaos: GameModeConfig(
    mode: GameMode.chaos,
    name: 'Chaos',
    tagline: 'Balanced mayhem',
    description:
        'The sweet spot: lively pacing with room to breathe and strategize.',
    colorA: Color(0xFF7C4DFF),
    colorB: Color(0xFF00E5FF),
    spawnIntervalNormal: 0.60,
    spawnIntervalFrenzy: 0.38,
    maxBalloonsNormal: 26,
    maxBalloonsFrenzy: 34,
    baseSpeedScale: 1.08,
    scoreMultiplier: 1.1,
    coinMultiplier: 1.15,
    goldenChance: 0.08,
    goldenChanceFrenzy: 0.24,
    bombChance: 0.10,
    bombChanceFrenzy: 0.13,
  ),
};

/// ---------- MISSIONS STORAGE ----------

Future<List<Mission>> loadMissions(SharedPreferences prefs) async {
  final today = DateTime.now();
  final todayKey = '${today.year}-${today.month}-${today.day}';
  final storedDate = prefs.getString('missionsDate');

  if (storedDate == todayKey) {
    final jsonStr = prefs.getString('missionsData');
    if (jsonStr != null) {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => Mission.fromMap(e as Map<String, dynamic>))
          .toList();
    }
  }

  // Generate new missions for today
  final rand = Random();
  final missions = <Mission>[
    Mission(
      id: 'score',
      type: MissionType.score,
      target: 500 + rand.nextInt(400), // 500–899
    ),
    Mission(
      id: 'combo',
      type: MissionType.combo,
      target: 12 + rand.nextInt(10), // 12–21
    ),
    Mission(
      id: 'frenzy',
      type: MissionType.frenzy,
      target: 2 + rand.nextInt(3), // 2–4
    ),
  ];

  await saveMissions(prefs, missions, todayKey);
  return missions;
}

Future<void> saveMissions(
  SharedPreferences prefs,
  List<Mission> missions, [
  String? dateKey,
]) async {
  final today = DateTime.now();
  final key = dateKey ?? '${today.year}-${today.month}-${today.day}';
  await prefs.setString('missionsDate', key);
  final jsonStr = jsonEncode(missions.map((m) => m.toMap()).toList());
  await prefs.setString('missionsData', jsonStr);
}

/// ---------- GAME RESULT & BALLOON MODEL ----------


class GameResult {
  final int score;
  final int bestCombo;
  final int coinsEarned;
  final int missionBonusCoins;
  final List<String> completedMissionIds;
  final int frenzyCount;

  GameResult({
    required this.score,
    required this.bestCombo,
    required this.coinsEarned,
    required this.missionBonusCoins,
    required this.completedMissionIds,
    required this.frenzyCount,
  });
}

/// ---------- MAIN MENU ----------

class MainMenu extends StatefulWidget {
  final SharedPreferences prefs;

  const MainMenu({super.key, required this.prefs});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  late PlayerProfile profile;
  List<Mission> missions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    profile = PlayerProfile.fromPrefs(widget.prefs);
    missions = await loadMissions(widget.prefs);
    await profile.save(widget.prefs);
    setState(() {
      loading = false;
    });
  }

  Future<void> _openShop() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ShopScreen(
          prefs: widget.prefs,
          profile: profile,
        ),
      ),
    );
    if (changed == true) {
      profile = PlayerProfile.fromPrefs(widget.prefs);
      setState(() {});
    }
  }

  Future<void> _openDailyReward() async {
    final claimed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DailyRewardScreen(
          prefs: widget.prefs,
          profile: profile,
        ),
      ),
    );

    if (claimed == true) {
      profile = PlayerProfile.fromPrefs(widget.prefs);
      setState(() {});
    }
  }

  Future<void> _startGame() async {
    if (loading) return;

    // 1) Pick mode
    final chosenMode = await Navigator.of(context).push<GameMode?>(
      MaterialPageRoute(
        builder: (_) => ModeSelectScreen(),
      ),
    );
    if (chosenMode == null) return;

    // 2) Start game in that mode
    final equipped = skinById(profile.equippedSkinId);
    final result = await Navigator.of(context).push<GameResult?>(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          skin: equipped,
          missions: missions
              .map(
                (m) => Mission(
                  id: m.id,
                  type: m.type,
                  target: m.target,
                  completed: m.completed,
                ),
              )
              .toList(),
          mode: chosenMode,
        ),
      ),
    );

    if (result == null) return;

    // 3) Update stats
    profile.lastScore = result.score;
    profile.highScore = max(profile.highScore, result.score);
    profile.bestCombo = max(profile.bestCombo, result.bestCombo);
    profile.totalCoins += result.coinsEarned + result.missionBonusCoins;

    // Update missions completion flags
    for (final m in missions) {
      if (result.completedMissionIds.contains(m.id)) {
        m.completed = true;
      }
    }

    await profile.save(widget.prefs);
    await saveMissions(widget.prefs, missions);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final equippedSkin = skinById(profile.equippedSkinId);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Text(
                'BALLOON BURST',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              _buildStatText('High Score', profile.highScore.toString(),
                  color: Colors.white),
              _buildStatText('Best Combo', profile.bestCombo.toString(),
                  color: const Color(0xFF00E5FF)),
              _buildStatText('Last Score', profile.lastScore.toString(),
                  color: Colors.grey.shade300),
              _buildStatText('Coins', profile.totalCoins.toString(),
                  color: const Color(0xFFFFD54F)),
              const SizedBox(height: 8),
              Text(
                'Equipped Skin: ${equippedSkin.name}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Daily streak: ${profile.dailyStreak} day(s)',
                style: const TextStyle(fontSize: 13, color: Colors.white54),
              ),
              const SizedBox(height: 24),
              _buildMissionsCard(),
              const Spacer(),
              _buildMainButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatText(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 16,
          color: color ?? Colors.white,
        ),
      ),
    );
  }

  Widget _buildMissionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1224),
        borderRadius: BorderRadius.circular(18),
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
          const SizedBox(height: 8),
          for (final m in missions) _buildMissionRow(m),
        ],
      ),
    );
  }

  Widget _buildMissionRow(Mission m) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            m.completed ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: m.completed ? const Color(0xFF69F0AE) : Colors.white54,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              m.description,
              style: TextStyle(
                fontSize: 14,
                color: m.completed ? Colors.white70 : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButtons() {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                backgroundColor: const Color(0xFF1E2338),
              ),
              child: const Text(
                'PLAY',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _openShop,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                side: const BorderSide(color: Color(0xFF7C4DFF)),
              ),
              child: const Text(
                'SHOP',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _openDailyReward,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                side: const BorderSide(color: Color(0xFFFFD54F)),
              ),
              child: const Text(
                'DAILY REWARD',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// ---------- MODE SELECT SCREEN (NEON CARDS) ----------

class ModeSelectScreen extends StatefulWidget {
  const ModeSelectScreen({super.key});

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double _wave(double phase) {
    // 0–1 sine wave
    final v = sin(2 * pi * (_pulseController.value + phase));
    return 0.5 + 0.5 * v;
  }

  void _select(GameMode mode) {
    Navigator.of(context).pop(mode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050817),
      appBar: AppBar(
        title: const Text('Select Mode'),
        backgroundColor: const Color(0xFF050817),
        elevation: 0,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MODE SELECT',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose your play style.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  _buildModeCard(
                    config: kGameModeConfigs[GameMode.arcade]!,
                    phase: 0.0,
                    onTap: () => _select(GameMode.arcade),
                  ),
                  const SizedBox(height: 16),
                  _buildModeCard(
                    config: kGameModeConfigs[GameMode.chaos]!,
                    phase: 0.33,
                    onTap: () => _select(GameMode.chaos),
                  ),
                  const SizedBox(height: 16),
                  _buildModeCard(
                    config: kGameModeConfigs[GameMode.frenzy]!,
                    phase: 0.66,
                    onTap: () => _select(GameMode.frenzy),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required GameModeConfig config,
    required double phase,
    required VoidCallback onTap,
  }) {
    final t = _wave(phase);
    final color1 = Color.lerp(config.colorA, config.colorB, t)!;
    final color2 = Color.lerp(config.colorB, config.colorA, 1 - t)!;
    final scale = 1.0 + 0.02 * sin(2 * pi * (_pulseController.value + phase));

    return Transform.scale(
      scale: scale,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color1, color2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color1.withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                config.tagline,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                config.description,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _chip('Coins x${config.coinMultiplier.toStringAsFixed(2)}'),
                  const SizedBox(width: 8),
                  _chip('Score x${config.scoreMultiplier.toStringAsFixed(2)}'),
                  const Spacer(),
                  const Icon(Icons.play_arrow_rounded, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}

/// ---------- SHOP SCREEN ----------

class ShopScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final PlayerProfile profile;

  const ShopScreen({
    super.key,
    required this.prefs,
    required this.profile,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late SkinDef selectedSkin;

  @override
  void initState() {
    super.initState();
    selectedSkin = skinById(widget.profile.equippedSkinId);
  }

  void _selectSkin(SkinDef skin) {
    setState(() {
      selectedSkin = skin;
    });
  }

  Future<void> _buyOrEquip() async {
    final profile = widget.profile;
    final owned = profile.ownedSkins.contains(selectedSkin.id);
    if (owned) {
      profile.equippedSkinId = selectedSkin.id;
    } else {
      if (profile.totalCoins < selectedSkin.price) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough coins!')),
        );
        return;
      }
      profile.totalCoins -= selectedSkin.price;
      profile.ownedSkins.add(selectedSkin.id);
      profile.equippedSkinId = selectedSkin.id;
    }
    await profile.save(widget.prefs);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final owned = profile.ownedSkins.contains(selectedSkin.id);
    final isEquipped = profile.equippedSkinId == selectedSkin.id;

    String buttonText;
    if (isEquipped) {
      buttonText = 'Equipped';
    } else if (owned) {
      buttonText = 'Equip';
    } else {
      buttonText = 'Buy for ${selectedSkin.price}';
    }

    final canPress = !isEquipped;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TapJunkie Shop'),
        backgroundColor: const Color(0xFF050817),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: _buildSelectedSkinHeader(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.monetization_on,
                      color: Color(0xFFFFD54F), size: 20),
                  const SizedBox(width: 4),
                  Text(
                    profile.totalCoins.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFFFD54F),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    for (final skin in allSkins) _buildSkinCard(skin),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canPress ? _buyOrEquip : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF1E2338),
                      disabledBackgroundColor: const Color(0xFF181C2A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSkinHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            selectedSkin.background.withOpacity(0.9),
            selectedSkin.glowColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selectedSkin.goldGlowColor.withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selectedSkin.balloonColors.first,
              boxShadow: [
                BoxShadow(
                  color: selectedSkin.glowColor,
                  blurRadius: 18,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedSkin.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedSkin.description,
                  style:
                      const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  selectedSkin.rarity,
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                    color: selectedSkin.rarity == 'LEGENDARY'
                        ? const Color(0xFFFFD54F)
                        : const Color(0xFF80D8FF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinCard(SkinDef skin) {
    final profile = widget.profile;
    final owned = profile.ownedSkins.contains(skin.id);
    final equipped = profile.equippedSkinId == skin.id;

    return GestureDetector(
      onTap: () => _selectSkin(skin),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              skin.balloonColors.first,
              skin.balloonColors.last,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: selectedSkin.id == skin.id
                ? Colors.white
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                skin.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                skin.price == 0 ? 'Equipped' : '${skin.price}c',
                style: TextStyle(
                  fontSize: 12,
                  color: skin.price == 0
                      ? Colors.white70
                      : const Color(0xFFFAFAFA),
                ),
              ),
            ),
            if (equipped)
              const Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Equipped',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            else if (owned)
              const Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Owned',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            else if (skin.rarity == 'LEGENDARY')
              const Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'LEGENDARY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellowAccent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ---------- DAILY REWARD SCREEN ----------

class DailyRewardScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final PlayerProfile profile;

  const DailyRewardScreen({
    super.key,
    required this.prefs,
    required this.profile,
  });

  @override
  State<DailyRewardScreen> createState() => _DailyRewardScreenState();
}

class _DailyRewardScreenState extends State<DailyRewardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _chestController;
  Timer? _timer;

  bool _canClaim = false;
  Duration _timeRemaining = Duration.zero;
  int _previewReward = 0;
  bool _claimedThisVisit = false;
  bool _showCoinBurst = false;

@override
void initState() {
  super.initState();


}
  @override
  void dispose() {
    _timer?.cancel();
    _chestController.dispose();
    super.dispose();
  }

  void _tick() {
    if (!_canClaim) {
      _evaluateState();
    }
  }

  void _evaluateState() {
    final now = DateTime.now();
    final last = widget.profile.lastDailyClaimDate;

    if (last == null) {
      setState(() {
        _canClaim = true;
        _timeRemaining = Duration.zero;
        _previewReward = _calculateRewardPreview(1);
      });
      return;
    }

    final diff = now.difference(last);
    if (diff >= const Duration(hours: 24)) {
      final nextStreak =
          _nextStreakValue(now, last, widget.profile.dailyStreak);
      setState(() {
        _canClaim = true;
        _timeRemaining = Duration.zero;
        _previewReward = _calculateRewardPreview(nextStreak);
      });
    } else {
      final remaining = const Duration(hours: 24) - diff;
      setState(() {
        _canClaim = false;
        _timeRemaining = remaining.isNegative ? Duration.zero : remaining;
        _previewReward = _calculateRewardPreview(
            widget.profile.dailyStreak == 0 ? 1 : widget.profile.dailyStreak);
      });
    }
  }

  int _nextStreakValue(DateTime now, DateTime last, int currentStreak) {
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(last.year, last.month, last.day);
    final dayDiff = today.difference(lastDay).inDays;

    if (dayDiff == 1) {
      return currentStreak + 1;
    } else if (dayDiff > 1) {
      return 1;
    } else {
      return currentStreak == 0 ? 1 : currentStreak;
    }
  }

  int _calculateRewardPreview(int streakValue) {
    int base = 50;
    int streakBonus = max(0, streakValue - 1) * 10;
    int reward = base + streakBonus;
    if (streakValue % 7 == 0) {
      reward += 100; // weekly bonus
    }
    return reward;
  }

  Future<void> _claimReward() async {
    if (!_canClaim) return;

    final now = DateTime.now();
    final last = widget.profile.lastDailyClaimDate;
    final currentStreak = widget.profile.dailyStreak;

    final nextStreak = last == null
        ? 1
        : _nextStreakValue(now, last, currentStreak);

    final rewardCoins = _calculateRewardPreview(nextStreak);

    widget.profile.dailyStreak = nextStreak;
    widget.profile.lastDailyClaimDate = now;
    widget.profile.totalCoins += rewardCoins;

    await widget.profile.save(widget.prefs);

    setState(() {
      _canClaim = false;
      _claimedThisVisit = true;
      _showCoinBurst = true;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _showCoinBurst = false;
      });
    });

    _evaluateState();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(h)}:${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_claimedThisVisit);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daily Reward'),
          backgroundColor: const Color(0xFF050817),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(_claimedThisVisit);
            },
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TapJunkie Treasure Chest',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _canClaim
                        ? 'Your daily reward is ready!'
                        : 'Come back after the countdown to claim again.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1.05).animate(
                      CurvedAnimation(
                        parent: _chestController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFC400),
                            Color(0xFFFF6F00),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amberAccent.withOpacity(0.7),
                            blurRadius: 30,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Text(
                            '🧰',
                            style: TextStyle(fontSize: 70),
                          ),
                          Positioned(
                            bottom: 24,
                            child: Row(
                              children: const [
                                Icon(Icons.star, color: Colors.white, size: 18),
                                SizedBox(width: 4),
                                Icon(Icons.star,
                                    color: Colors.white70, size: 14),
                                SizedBox(width: 4),
                                Icon(Icons.star,
                                    color: Colors.white54, size: 12),
                              ],
                            ),
                          ),
                          if (_showCoinBurst)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: AnimatedOpacity(
                                  opacity: _showCoinBurst ? 1 : 0,
                                  duration:
                                      const Duration(milliseconds: 900),
                                  child: Stack(
                                    children: [
                                      _coinBurstOffset(-40, -40),
                                      _coinBurstOffset(30, -30),
                                      _coinBurstOffset(-10, 40),
                                      _coinBurstOffset(40, 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Current streak: ${profile.dailyStreak} day(s)',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.lightGreenAccent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _canClaim
                        ? 'Next reward value: $_previewReward coins'
                        : 'Last claimed: ${profile.lastDailyClaimDate?.toLocal().toString().split(".").first ?? 'Never'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_canClaim)
                    Column(
                      children: [
                        const Text(
                          'Next chest unlock in:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDuration(_timeRemaining),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD54F),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canClaim ? _claimReward : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF1E2338),
                        disabledBackgroundColor: const Color(0xFF181C2A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        _canClaim
                            ? 'Open Chest (+$_previewReward coins)'
                            : 'Chest Locked',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _coinBurstOffset(double dx, double dy) {
    return Align(
      alignment: Alignment.center,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: const Icon(
          Icons.monetization_on,
          size: 26,
          color: Color(0xFFFFD54F),
        ),
      ),
    );
  }
}

