import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

/// ------------------------------------------------------------
/// CORE APP
/// ------------------------------------------------------------

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

/// ------------------------------------------------------------
/// DATA MODELS
/// ------------------------------------------------------------

enum MissionType {
  score,
  combo,
  frenzy,
}

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

class PlayerProfile {
  int highScore;
  int bestCombo;
  int lastScore;
  int totalCoins;

  int dailyStreak;
  DateTime? lastDailyClaimDate;

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

/// Core in-run data

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

class Particle {
  Offset position;
  Offset velocity;
  double life; // seconds remaining
  Color color;
  double size;

  Particle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.color,
    required this.size,
  });
}

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

/// ------------------------------------------------------------
/// SKIN SYSTEM
/// ------------------------------------------------------------

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
    description: 'Teal and cyan bursts from deep space.',
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
    description: 'TapJunkie toxic lime + hot pink overdose.',
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

/// ------------------------------------------------------------
/// MISSIONS STORAGE
/// ------------------------------------------------------------

Future<List<Mission>> loadMissions(SharedPreferences prefs) async {
  final now = DateTime.now();
  final todayKey = '${now.year}-${now.month}-${now.day}';
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

  final rand = Random();
  final missions = <Mission>[
    Mission(
      id: 'score',
      type: MissionType.score,
      target: 500 + rand.nextInt(400),
    ),
    Mission(
      id: 'combo',
      type: MissionType.combo,
      target: 12 + rand.nextInt(10),
    ),
    Mission(
      id: 'frenzy',
      type: MissionType.frenzy,
      target: 2 + rand.nextInt(3),
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
  final now = DateTime.now();
  final key = dateKey ?? '${now.year}-${now.month}-${now.day}';
  await prefs.setString('missionsDate', key);
  final jsonStr = jsonEncode(missions.map((m) => m.toMap()).toList());
  await prefs.setString('missionsData', jsonStr);
}

/// ------------------------------------------------------------
/// GAME STATE MANAGER
/// ------------------------------------------------------------

class GameStateManager {
  final SharedPreferences prefs;

  late PlayerProfile profile;
  List<Mission> missions = [];

  GameStateManager(this.prefs);

  Future<void> init() async {
    profile = PlayerProfile.fromPrefs(prefs);
    missions = await loadMissions(prefs);
    await profile.save(prefs);
  }

  Future<void> applyGameResult(GameResult result) async {
    profile.lastScore = result.score;
    profile.highScore = max(profile.highScore, result.score);
    profile.bestCombo = max(profile.bestCombo, result.bestCombo);
    profile.totalCoins += result.coinsEarned + result.missionBonusCoins;

    for (final m in missions) {
      if (result.completedMissionIds.contains(m.id)) {
        m.completed = true;
      }
    }

    await profile.save(prefs);
    await saveMissions(prefs, missions);
  }
}

/// ------------------------------------------------------------
/// MAIN MENU
/// ------------------------------------------------------------

class MainMenu extends StatefulWidget {
  final SharedPreferences prefs;

  const MainMenu({super.key, required this.prefs});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  late GameStateManager manager;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    manager = GameStateManager(widget.prefs);
    _init();
  }

  Future<void> _init() async {
    await manager.init();
    setState(() {
      loading = false;
    });
  }

  Future<void> _openShop() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ShopScreen(
          prefs: widget.prefs,
          profile: manager.profile,
        ),
      ),
    );

    if (changed == true) {
      await manager.init();
      setState(() {});
    }
  }

  Future<void> _openDailyReward() async {
    final claimed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DailyRewardScreen(
          prefs: widget.prefs,
          profile: manager.profile,
        ),
      ),
    );

    if (claimed == true) {
      await manager.init();
      setState(() {});
    }
  }

  Future<void> _startGame() async {
    if (loading) return;

    final equippedSkin = skinById(manager.profile.equippedSkinId);

    final missionsCopy = manager.missions
        .map(
          (m) => Mission(
            id: m.id,
            type: m.type,
            target: m.target,
            completed: m.completed,
          ),
        )
        .toList();

    final result = await Navigator.of(context).push<GameResult?>(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          skin: equippedSkin,
          missions: missionsCopy,
        ),
      ),
    );

    if (result == null) return;

    await manager.applyGameResult(result);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final profile = manager.profile;
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
              _stat('High Score', profile.highScore.toString(),
                  color: Colors.white),
              _stat('Best Combo', profile.bestCombo.toString(),
                  color: const Color(0xFF00E5FF)),
              _stat('Last Score', profile.lastScore.toString(),
                  color: Colors.grey.shade300),
              _stat('Coins', profile.totalCoins.toString(),
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
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 24),
              _missionsCard(manager.missions),
              const Spacer(),
              _mainButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, {Color? color}) {
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

  Widget _missionsCard(List<Mission> missions) {
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
          for (final m in missions) _missionRow(m),
        ],
      ),
    );
  }

  Widget _missionRow(Mission m) {
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

  Widget _mainButtons() {
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

/// ------------------------------------------------------------
/// SHOP SCREEN
/// ------------------------------------------------------------

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
              child: _selectedSkinHeader(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Color(0xFFFFD54F),
                    size: 20,
                  ),
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
                    for (final skin in allSkins) _skinCard(skin),
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

  Widget _selectedSkinHeader() {
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
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

  Widget _skinCard(SkinDef skin) {
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
            color: selectedSkin.id == skin.id ? Colors.white : Colors.transparent,
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

/// ------------------------------------------------------------
/// DAILY REWARD SCREEN (CHEST + STREAK + COUNTDOWN)
/// ------------------------------------------------------------

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
    _chestController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _evaluateState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chestController.dispose();
    super.dispose();
  }

  void _tick() {
    if (!_canClaim && mounted) {
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
      final nextStreak = _nextStreakValue(now, last, widget.profile.dailyStreak);
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
        final streakBase = widget.profile.dailyStreak == 0
            ? 1
            : widget.profile.dailyStreak;
        _previewReward = _calculateRewardPreview(streakBase);
      });
    }
  }

  int _nextStreakValue(
      DateTime now, DateTime last, int currentStreak) {
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
      reward += 100;
    }
    return reward;
  }

  Future<void> _claimReward() async {
    if (!_canClaim) return;

    final now = DateTime.now();
    final last = widget.profile.lastDailyClaimDate;
    final currentStreak = widget.profile.dailyStreak;

    final nextStreak =
        last == null ? 1 : _nextStreakValue(now, last, currentStreak);

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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                                Icon(Icons.star,
                                    color: Colors.white, size: 18),
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
                                  duration: const Duration(milliseconds: 900),
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

/// ------------------------------------------------------------
/// GAME SCREEN (NO FLUTTER GIMMICKS, PURE TICKER + PAINTER)
/// ------------------------------------------------------------

class GameScreen extends StatefulWidget {
  final SkinDef skin;
  final List<Mission> missions;

  const GameScreen({
    super.key,
    required this.skin,
    required this.missions,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastTick = Duration.zero;
  final Random _rand = Random();

  final List<Balloon> _balloons = [];
  final List<Particle> _particles = [];

  bool _running = true;
  bool _gameOver = false;

  int _score = 0;
  int _coins = 0;
  int _lives = 3;
  int _combo = 0;
  int _bestCombo = 0;
  int _frenzyCount = 0;

  bool _frenzy = false;
  double _frenzyTimer = 0;
  double _spawnTimer = 0;

  List<String> _completedMissionIds = [];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (!_running || _gameOver) return;
    _update(dt);
  }

  void _update(double dt) {
    setState(() {
      _spawnTimer += dt;

      final spawnInterval = _frenzy ? 0.28 : 0.6;
      const maxBalloonsNormal = 30;
      const maxBalloonsFrenzy = 40;
      final maxAllowed = _frenzy ? maxBalloonsFrenzy : maxBalloonsNormal;

      while (_spawnTimer >= spawnInterval &&
          _balloons.length < maxAllowed) {
        _spawnTimer -= spawnInterval;
        _spawnBalloon();
      }

      for (var b in _balloons) {
        b.position = Offset(
          b.position.dx,
          b.position.dy - b.speed * dt,
        );
      }

      _balloons.removeWhere((b) {
        if (b.position.dy + b.radius < 0) {
          if (!b.isBomb) {
            _lives -= 1;
            _combo = 0;
            if (_lives <= 0) {
              _triggerGameOver();
            }
          }
          return true;
        }
        return false;
      });

      for (final p in _particles) {
        p.position += p.velocity * dt;
        p.life -= dt;
      }
      _particles.removeWhere((p) => p.life <= 0);

      if (_frenzy) {
        _frenzyTimer -= dt;
        if (_frenzyTimer <= 0) {
          _frenzy = false;
        }
      }
    });
  }

  void _spawnBalloon() {
    final size = MediaQuery.of(context).size;
    final x = 40 + _rand.nextDouble() * (size.width - 80);
    final radius = 18 + _rand.nextDouble() * 26;

    const baseSpeed = 70.0;
    final speedScale = 1.0 + (_score / 350.0);
    final speed = baseSpeed * speedScale * (0.85 + _rand.nextDouble() * 0.35);

    final isGoldenChance = _frenzy ? 0.25 : 0.06;
    final isBombChance = _frenzy ? 0.08 : 0.10;

    final isGolden = _rand.nextDouble() < isGoldenChance;
    final isBomb = !isGolden && _rand.nextDouble() < isBombChance;

    Color color;
    if (isBomb) {
      color = Colors.redAccent;
    } else if (isGolden) {
      color = const Color(0xFFFFD740);
    } else {
      final palette = widget.skin.balloonColors;
      color = palette[_rand.nextInt(palette.length)];
    }

    final glowIntensity = 0.5 + _rand.nextDouble() * 0.5;

    _balloons.add(
      Balloon(
        position: Offset(x, size.height + radius + 10),
        radius: radius,
        speed: speed,
        color: color,
        isGolden: isGolden,
        isBomb: isBomb,
        glowIntensity: glowIntensity,
      ),
    );
  }

  double _tapHitboxMultiplier() {
    switch (widget.skin.id) {
      case 'classic':
        return 1.6;
      case 'neon_city':
        return 1.7;
      case 'retro_arcade':
        return 1.7;
      case 'mystic_glow':
        return 1.7;
      case 'cosmic_burst':
        return 1.8;
      case 'junkie_juice':
        return 2.0;
      default:
        return 1.7;
    }
  }

  void _handleTap(Offset pos) {
    if (_gameOver) return;

    final multiplier = _tapHitboxMultiplier();

    for (int i = _balloons.length - 1; i >= 0; i--) {
      final b = _balloons[i];
      final dist = (pos - b.position).distance;
      final effectiveRadius = b.radius * multiplier;

      if (dist <= effectiveRadius) {
        _popBalloon(i);
        return;
      }
    }

    setState(() {
      _combo = 0;
    });
  }

  void _spawnParticlesAt(Offset position, Color color) {
    for (int i = 0; i < 10; i++) {
      final angle = _rand.nextDouble() * 2 * pi;
      final speed = 40 + _rand.nextDouble() * 80;
      final velocity = Offset(cos(angle), sin(angle)) * speed;
      _particles.add(
        Particle(
          position: position,
          velocity: velocity,
          life: 0.5 + _rand.nextDouble() * 0.5,
          color: color,
          size: 3 + _rand.nextDouble() * 3,
        ),
      );
    }
  }

  void _popBalloon(int index) {
    final b = _balloons[index];

    setState(() {
      _balloons.removeAt(index);
      _spawnParticlesAt(b.position, b.color);

      if (b.isBomb) {
        _lives -= 1;
        _combo = 0;
        if (_lives <= 0) {
          _triggerGameOver();
        }
      } else {
        _combo += 1;
        if (_combo > _bestCombo) _bestCombo = _combo;

        int baseScore = 10;
        int baseCoins = 1;

        if (b.isGolden) {
          baseScore = 40;
          baseCoins = 5;
        }

        final comboBonus = (_combo ~/ 5);
        int gainedScore = baseScore + comboBonus;
        int gainedCoins = baseCoins + (_frenzy ? 1 : 0);

        if (_frenzy) {
          gainedScore = (gainedScore * 1.5).round();
          gainedCoins += 1;
        }

        _score += gainedScore;
        _coins += gainedCoins;

        if (b.isGolden || _combo % 10 == 0) {
          _maybeTriggerFrenzy();
        }
      }
    });
  }

  void _maybeTriggerFrenzy() {
    if (_frenzy) return;
    _frenzy = true;
    _frenzyTimer = 8.0;
    _frenzyCount += 1;
  }

  void _triggerGameOver() {
    _gameOver = true;
    _running = false;
    _ticker.stop();

    int bonusCoins = 0;
    final completedIds = <String>[];

    for (final m in widget.missions) {
      bool done = false;
      switch (m.type) {
        case MissionType.score:
          done = _score >= m.target;
          break;
        case MissionType.combo:
          done = _bestCombo >= m.target;
          break;
        case MissionType.frenzy:
          done = _frenzyCount >= m.target;
          break;
      }
      if (done && !m.completed) {
        m.completed = true;
        completedIds.add(m.id);
        bonusCoins += 100;
      }
    }

    _completedMissionIds = completedIds;

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _exitToMenu() {
    final result = GameResult(
      score: _score,
      bestCombo: _bestCombo,
      coinsEarned: _coins,
      missionBonusCoins: _completedMissionIds.length * 100,
      completedMissionIds: _completedMissionIds,
      frenzyCount: _frenzyCount,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.skin.background,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => _handleTap(details.localPosition),
              child: CustomPaint(
                painter: BalloonPainter(
                  balloons: _balloons,
                  particles: _particles,
                  skin: widget.skin,
                  frenzy: _frenzy,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            _hud(),
            if (_gameOver) _gameOverOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _hud() {
    return Positioned(
      top: 8,
      left: 10,
      right: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hudText('Score: $_score', Colors.white),
              _hudText('Lives: $_lives', Colors.redAccent),
              _hudText('Coins: $_coins', const Color(0xFFFFD54F)),
              _hudText('Combo: $_combo', const Color(0xFF00E5FF)),
            ],
          ),
          if (_frenzy || _frenzyTimer > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'FRENZY!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Colors.pinkAccent.shade100,
                  ),
                ),
                Text(
                  _frenzyTimer.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                )
              ],
            ),
        ],
      ),
    );
  }

  Widget _gameOverOverlay() {
    final missionLines = <Widget>[];
    for (final m in widget.missions) {
      if (m.completed && _completedMissionIds.contains(m.id)) {
        missionLines.add(
          Text(
            '• Mission complete: ${m.description} (+100 coins)',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.lightGreenAccent,
            ),
          ),
        );
      }
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.82),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GAME OVER',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent.shade100,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Score: $_score',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Best Combo (this run): $_bestCombo',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Coins this run: $_coins',
                  style: const TextStyle(fontSize: 16),
                ),
                if (_frenzyCount > 0)
                  Text(
                    'Frenzy triggered: $_frenzyCount time(s)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                const SizedBox(height: 16),
                if (missionLines.isNotEmpty) ...[
                  const Text(
                    'Missions Completed:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightGreenAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...missionLines,
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _exitToMenu,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2338),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Back to Menu',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Text _hudText(String s, Color color) {
    return Text(
      s,
      style: TextStyle(fontSize: 14, color: color),
    );
  }
}

/// ------------------------------------------------------------
/// BALLOON PAINTER
/// ------------------------------------------------------------

class BalloonPainter extends CustomPainter {
  final List<Balloon> balloons;
  final List<Particle> particles;
  final SkinDef skin;
  final bool frenzy;

  BalloonPainter({
    required this.balloons,
    required this.particles,
    required this.skin,
    required this.frenzy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = skin.background;
    canvas.drawRect(Offset.zero & size, bgPaint);

    for (final b in balloons) {
      final glowPaint = Paint()
        ..color = (b.isGolden ? skin.goldGlowColor : skin.glowColor)
            .withOpacity(0.25 + 0.4 * b.glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);

      final corePaint = Paint()
        ..color = b.color
        ..style = PaintingStyle.fill;

      final glowRadius = b.radius * (frenzy ? 2.4 : 1.9);
      canvas.drawCircle(b.position, glowRadius, glowPaint);

      canvas.drawCircle(b.position, b.radius, corePaint);

      if (b.isGolden) {
        final sparklePaint = Paint()
          ..color = Colors.white.withOpacity(0.9)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

        final center = b.position - Offset(b.radius * 0.3, b.radius * 0.3);
        const len = 4.0;
        canvas.drawLine(
          center.translate(-len, 0),
          center.translate(len, 0),
          sparklePaint,
        );
        canvas.drawLine(
          center.translate(0, -len),
          center.translate(0, len),
          sparklePaint,
        );
      }

      if (b.isBomb) {
        final ringPaint = Paint()
          ..color = Colors.redAccent.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(b.position, b.radius * 1.4, ringPaint);
      }
    }

    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(max(0, p.life));
      canvas.drawCircle(p.position, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BalloonPainter oldDelegate) {
    return true;
  }
}

