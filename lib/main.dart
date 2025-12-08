import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ---------- ENTRYPOINT ----------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

/// ---------- ENUMS ----------

/// How strict / generous tap hit detection should be.
enum TapPrecisionMode {
  skinDefault, // use whatever the skin says
  precision,   // smaller hitbox, more skill
  tapJunkie,   // default - generous, fun
  overlord,    // huge hitbox, chaos mode
}

enum MissionType { score, combo, frenzy }

/// ---------- DATA MODELS ----------

class PlayerProfile {
  int highScore;
  int bestCombo;
  int lastScore;
  int totalCoins;
  int dailyStreak;
  String equippedSkinId;
  Set<String> ownedSkins;
  DateTime? lastLoginDate;

  /// Stored as index of TapPrecisionMode
  int tapPrecisionIndex;
  bool useSkinDefaultPrecision;

  PlayerProfile({
    required this.highScore,
    required this.bestCombo,
    required this.lastScore,
    required this.totalCoins,
    required this.dailyStreak,
    required this.equippedSkinId,
    required this.ownedSkins,
    required this.lastLoginDate,
    required this.tapPrecisionIndex,
    required this.useSkinDefaultPrecision,
  });

  factory PlayerProfile.fromPrefs(SharedPreferences prefs) {
    final highScore = prefs.getInt('highScore') ?? 0;
    final bestCombo = prefs.getInt('bestCombo') ?? 0;
    final lastScore = prefs.getInt('lastScore') ?? 0;
    final totalCoins = prefs.getInt('totalCoins') ?? 50;
    final equippedSkinId = prefs.getString('equippedSkinId') ?? 'classic';
    final ownedSkinsList = prefs.getStringList('ownedSkins') ?? ['classic'];

    final lastLoginStr = prefs.getString('lastLoginDate');
    DateTime? lastLogin;
    if (lastLoginStr != null) {
      lastLogin = DateTime.tryParse(lastLoginStr);
    }

    int dailyStreak = prefs.getInt('dailyStreak') ?? 0;
    final today = DateTime.now();

    if (lastLogin == null) {
      dailyStreak = 1;
    } else {
      final diff = today
          .difference(DateTime(lastLogin.year, lastLogin.month, lastLogin.day))
          .inDays;
      if (diff == 0) {
        // same day, keep streak
      } else if (diff == 1) {
        dailyStreak += 1;
      } else {
        dailyStreak = 1;
      }
    }

    final tapPrecisionIndex = prefs.getInt('tap_precision_mode') ?? 1; // TapJunkie
    final useSkinDefaultPrecision =
        prefs.getBool('use_skin_default_precision') ?? true;

    return PlayerProfile(
      highScore: highScore,
      bestCombo: bestCombo,
      lastScore: lastScore,
      totalCoins: totalCoins,
      dailyStreak: dailyStreak,
      equippedSkinId: equippedSkinId,
      ownedSkins: ownedSkinsList.toSet(),
      lastLoginDate: today,
      tapPrecisionIndex: tapPrecisionIndex,
      useSkinDefaultPrecision: useSkinDefaultPrecision,
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
    if (lastLoginDate != null) {
      await prefs.setString('lastLoginDate', lastLoginDate!.toIso8601String());
    }

    await prefs.setInt('tap_precision_mode', tapPrecisionIndex);
    await prefs.setBool('use_skin_default_precision', useSkinDefaultPrecision);
  }
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
  final String rarity; // e.g. COMMON / LEGENDARY
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

/// ---------- CORE APP WIDGET ----------

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
      // Reload from prefs for safety
      profile = PlayerProfile.fromPrefs(widget.prefs);
      setState(() {});
    }
  }

  Future<void> _startGame() async {
    if (loading) return;

    final equipped = skinById(profile.equippedSkinId);

    // convert stored index to enum safely
    final mode = TapPrecisionMode.values[
        profile.tapPrecisionIndex.clamp(0, TapPrecisionMode.values.length - 1)];

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
          tapPrecisionMode: mode,
          useSkinDefaultPrecision: profile.useSkinDefaultPrecision,
          equippedSkinId: profile.equippedSkinId,
        ),
      ),
    );

    if (result == null) return;

    // Update stats
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
          const SizedBox(height: 8),
        ],
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
    Navigator.of(context).pop(true);
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
            color:
                selectedSkin.id == skin.id ? Colors.white : Colors.transparent,
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

/// ---------- GAME DATA STRUCTS ----------

class Balloon {
  Offset position;
  double radius;
  double speed;
  Color color;
  bool isGolden;
  bool isBomb;
  double glowIntensity; // 0–1 for subtle per-balloon variation

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

/// ---------- TAP PRECISION ENGINE (Overlord Dynamic) ----------

double getTapPrecisionMultiplier({
  required TapPrecisionMode tapPrecisionMode,
  required bool useSkinDefault,
  required String equippedSkinId,
  required bool isGolden,
  required bool isBomb,
  required bool isFrenzy,
  required double balloonSpeed,
  required int combo,
}) {
  double base = 1.0;

  // Skin defaults (subtle differences)
  if (useSkinDefault || tapPrecisionMode == TapPrecisionMode.skinDefault) {
    switch (equippedSkinId) {
      case 'classic':
        base = 1.15;
        break;
      case 'neon_city':
        base = 1.2;
        break;
      case 'retro_arcade':
        base = 1.22;
        break;
      case 'mystic_glow':
        base = 1.25;
        break;
      case 'cosmic_burst':
        base = 1.3;
        break;
      case 'junkie_juice':
        base = 1.35;
        break;
      default:
        base = 1.2;
        break;
    }
  }

  // Mode scaling
  double modeFactor;
  switch (tapPrecisionMode) {
    case TapPrecisionMode.precision:
      modeFactor = 0.7;
      break;
    case TapPrecisionMode.tapJunkie:
      modeFactor = 1.0;
      break;
    case TapPrecisionMode.overlord:
      modeFactor = 1.6;
      break;
    case TapPrecisionMode.skinDefault:
      modeFactor = 1.0;
      break;
  }

  // Combo-based assistance (higher combo = slightly bigger hitbox)
  final comboBoost = min(combo / 80.0, 0.3); // max +30%
  final comboFactor = 1.0 + comboBoost;

  // Speed-based assistance (very fast balloons get slight bonus)
  final speedFactor = balloonSpeed > 160.0 ? 1.12 : 1.0;

  // Rarity & bomb logic
  double rarityFactor = 1.0;
  if (isGolden) {
    rarityFactor = 1.1; // easier to hit golden
  }
  if (isBomb) {
    rarityFactor *= 0.85; // slightly tighter hitbox on bombs
  }

  // Frenzy: small assist because chaos
  final frenzyFactor = isFrenzy ? 1.12 : 1.0;

  double total = base * modeFactor * comboFactor * speedFactor * rarityFactor * frenzyFactor;

  // Overlord: ensure it's chunky but not insane
  if (tapPrecisionMode == TapPrecisionMode.overlord) {
    total = max(total, 1.8);
    total = min(total, 2.6);
  }

  // Precision: keep from getting too big
  if (tapPrecisionMode == TapPrecisionMode.precision) {
    total = min(total, 1.1);
  }

  return total;
}

/// ---------- GAME SCREEN (PURE FLUTTER) ----------

class GameScreen extends StatefulWidget {
  final SkinDef skin;
  final List<Mission> missions;
  final TapPrecisionMode tapPrecisionMode;
  final bool useSkinDefaultPrecision;
  final String equippedSkinId;

  const GameScreen({
    super.key,
    required this.skin,
    required this.missions,
    required this.tapPrecisionMode,
    required this.useSkinDefaultPrecision,
    required this.equippedSkinId,
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

      final spawnInterval = _frenzy ? 0.25 : 0.55;

      while (_spawnTimer >= spawnInterval) {
        _spawnTimer -= spawnInterval;
        _spawnBalloon();
      }

      // Move balloons
      for (var b in _balloons) {
        b.position = Offset(
          b.position.dx,
          b.position.dy - b.speed * dt,
        );
      }

      // Remove off-screen balloons & handle missed
      _balloons.removeWhere((b) {
        if (b.position.dy + b.radius < 0) {
          // Off-screen
          if (!b.isBomb) {
            // miss normal balloon: lose life + break combo
            _lives -= 1;
            _combo = 0;
          } else {
            // Bombs only hurt when tapped
          }
          if (_lives <= 0) {
            _triggerGameOver();
          }
          return true;
        }
        return false;
      });

      // Frenzy timer
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

    final baseSpeed = 70.0;
    final speedScale = 1.0 + (_score / 300.0); // gets faster over time
    final speed = baseSpeed * speedScale * (0.8 + _rand.nextDouble() * 0.4);

    final isGoldenChance = _frenzy ? 0.25 : 0.06;
    final isBombChance = _frenzy ? 0.08 : 0.12;

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

  void _handleTap(Offset pos) {
    if (_gameOver) return;

    // Topmost balloon first (last drawn)
    for (int i = _balloons.length - 1; i >= 0; i--) {
      final b = _balloons[i];
      final dist = (pos - b.position).distance;

      final multiplier = getTapPrecisionMultiplier(
        tapPrecisionMode: widget.tapPrecisionMode,
        useSkinDefault: widget.useSkinDefaultPrecision,
        equippedSkinId: widget.equippedSkinId,
        isGolden: b.isGolden,
        isBomb: b.isBomb,
        isFrenzy: _frenzy,
        balloonSpeed: b.speed,
        combo: _combo,
      );

      final effectiveRadius = b.radius * multiplier;

      if (dist <= effectiveRadius) {
        _popBalloon(i);
        return;
      }
    }

    // Tap in empty space: reset combo softly
    setState(() {
      _combo = 0;
    });
  }

  void _popBalloon(int index) {
    final b = _balloons[index];
    setState(() {
      _balloons.removeAt(index);

      if (b.isBomb) {
        // Bomb tapped: lose life + combo reset, no score
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

        final comboBonus = (_combo ~/ 5); // small extra
        int gainedScore = baseScore + comboBonus;
        int gainedCoins = baseCoins + (_frenzy ? 1 : 0);

        if (_frenzy) {
          gainedScore = (gainedScore * 1.5).round();
          gainedCoins += 1;
        }

        _score += gainedScore;
        _coins += gainedCoins;

        // Frenzy progress: depending on combo and golden pops
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

    // Evaluate missions
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
        bonusCoins += 100; // flat 100c per mission
      }
    }
    _completedMissionIds = completedIds;
    _coins += bonusCoins;

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
                  skin: widget.skin,
                  frenzy: _frenzy,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            _buildHud(),
            if (_gameOver) _buildGameOverOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHud() {
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

  Widget _buildGameOverOverlay() {
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
                        fontSize: 14, color: Colors.white70),
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

/// ---------- BALLOON PAINTER ----------

class BalloonPainter extends CustomPainter {
  final List<Balloon> balloons;
  final SkinDef skin;
  final bool frenzy;

  BalloonPainter({
    required this.balloons,
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

      // Glow halo
      final glowRadius = b.radius * (frenzy ? 2.4 : 1.9);
      canvas.drawCircle(b.position, glowRadius, glowPaint);

      // Core balloon
      canvas.drawCircle(b.position, b.radius, corePaint);

      // Small sparkle on golden balloons
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

      // Bomb pulse ring
      if (b.isBomb) {
        final ringPaint = Paint()
          ..color = Colors.redAccent.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(b.position, b.radius * 1.4, ringPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BalloonPainter oldDelegate) {
    return true;
  }
}

