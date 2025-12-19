import 'screens/daily_reward.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'game/balloon.dart';
import 'game/missions.dart';
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

    final profile = widget.profile;
    final owned = profile.ownedSkins.contains(skin.id);
    final equipped = profile.equippedSkinId == skin.id;

    return GestureDetector(
      onTap: null,
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


