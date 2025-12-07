import 'dart:math';
import 'dart:ui' show Canvas, MaskFilter, BlurStyle;
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storage = GameStorage(prefs);
  runApp(BalloonApp(storage: storage));
}

/// Simple storage for scores, coins, meta, and cosmetics.
class GameStorage {
  final SharedPreferences prefs;
  GameStorage(this.prefs);

  int get highScore => prefs.getInt('high_score') ?? 0;
  set highScore(int v) => prefs.setInt('high_score', v);

  int get coins => prefs.getInt('coins') ?? 0;
  set coins(int v) => prefs.setInt('coins', v);

  int get bestCombo => prefs.getInt('best_combo') ?? 0;
  set bestCombo(int v) => prefs.setInt('best_combo', v);

  int get lastScore => prefs.getInt('last_score') ?? 0;
  set lastScore(int v) => prefs.setInt('last_score', v);

  int get dailyStreak => prefs.getInt('daily_streak') ?? 0;
  set dailyStreak(int v) => prefs.setInt('daily_streak', v);

  int get lastDailyClaimDay => prefs.getInt('last_daily_claim_day') ?? 0;
  set lastDailyClaimDay(int v) =>
      prefs.setInt('last_daily_claim_day', v);

  int get missionsDay => prefs.getInt('missions_day') ?? 0;
  set missionsDay(int v) => prefs.setInt('missions_day', v);

  bool get missionScoreRewarded =>
      prefs.getBool('mission_score_rewarded') ?? false;
  set missionScoreRewarded(bool v) =>
      prefs.setBool('mission_score_rewarded', v);

  bool get missionComboRewarded =>
      prefs.getBool('mission_combo_rewarded') ?? false;
  set missionComboRewarded(bool v) =>
      prefs.setBool('mission_combo_rewarded', v);

  bool get missionFrenzyRewarded =>
      prefs.getBool('mission_frenzy_rewarded') ?? false;
  set missionFrenzyRewarded(bool v) =>
      prefs.setBool('mission_frenzy_rewarded', v);

  bool get seenOnboarding =>
      prefs.getBool('seen_onboarding') ?? false;
  set seenOnboarding(bool v) =>
      prefs.setBool('seen_onboarding', v);

  // Cosmetics: skins
  List<String> get ownedSkins =>
      prefs.getStringList('owned_skins') ?? <String>[];
  set ownedSkins(List<String> v) =>
      prefs.setStringList('owned_skins', v);

  String get equippedSkinId =>
      prefs.getString('equipped_skin_id') ?? 'classic';

  set equippedSkinId(String v) =>
      prefs.setString('equipped_skin_id', v);

  // Convenience helpers
  Set<String> get ownedSkinSet => ownedSkins.toSet();

  bool isSkinOwned(String id) {
    final set = ownedSkinSet;
    if (!set.contains('classic')) {
      set.add('classic'); // ensure default is always owned
      ownedSkins = set.toList();
    }
    return set.contains(id);
  }

  void unlockSkin(String id) {
    final set = ownedSkinSet;
    set.add(id);
    ownedSkins = set.toList();
  }

  /// Returns YYYYMMDD as int for "today".
  static int todayKey() {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  /// Ensures mission flags are for *today*, resets if new day.
  void ensureMissionsForToday() {
    final today = todayKey();
    if (missionsDay != today) {
      missionsDay = today;
      missionScoreRewarded = false;
      missionComboRewarded = false;
      missionFrenzyRewarded = false;
    }
  }

  bool get canClaimDailyReward {
    final today = todayKey();
    return lastDailyClaimDay != today;
  }

  /// Claims daily reward, updates streak and coins, returns reward amount.
  int claimDailyReward() {
    final today = todayKey();
    if (lastDailyClaimDay == today) {
      return 0; // already claimed
    }

    int streak = dailyStreak;
    if (lastDailyClaimDay == 0) {
      streak = 1;
    } else if (today == lastDailyClaimDay + 1) {
      streak += 1;
    } else {
      streak = 1;
    }

    dailyStreak = streak;
    lastDailyClaimDay = today;

    // Option B: reasonable but rewarding
    int reward = 50 + (streak - 1) * 10;
    if (reward > 200) reward = 200;

    coins = coins + reward;
    return reward;
  }
}

/// TapJunkie Skin definition.
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

/// Master list of TapJunkie skins (Pack D vibe).
class TapJunkieSkins {
  static const List<SkinDef> all = [
    SkinDef(
      id: 'classic',
      name: 'Classic Mix',
      description: 'Original Balloon Burst palette.',
      price: 0,
      palette: [
        Colors.yellow,
        Colors.blue,
        Colors.green,
        Colors.purple,
        Colors.orange,
        Colors.cyan,
      ],
      accent: Colors.pinkAccent,
    ),
    SkinDef(
      id: 'neon_city',
      name: 'Neon City',
      description: 'Electric blues and magentas from a rainy cyber-night.',
      price: 250,
      palette: [
        Color(0xFF00E5FF),
        Color(0xFFFF00FF),
        Color(0xFF00FFB0),
        Color(0xFF8E24AA),
      ],
      accent: Color(0xFFFF4081),
    ),
    SkinDef(
      id: 'retro_arcade',
      name: 'Retro Arcade',
      description: 'Hot pink, teal, and arcade cabinet glow.',
      price: 300,
      palette: [
        Color(0xFFFF4081),
        Color(0xFF00E676),
        Color(0xFF40C4FF),
        Color(0xFFFFD740),
      ],
      accent: Color(0xFFFFAB40),
    ),
    SkinDef(
      id: 'mystic_glow',
      name: 'Mystic Glow',
      description: 'Purples, teals and deep magic energy.',
      price: 350,
      palette: [
        Color(0xFF7C4DFF),
        Color(0xFF18FFFF),
        Color(0xFF64FFDA),
        Color(0xFF6200EA),
      ],
      accent: Color(0xFFB388FF),
    ),
    SkinDef(
      id: 'cosmic_burst',
      name: 'Cosmic Burst',
      description: 'Galactic gradients from deep space.',
      price: 400,
      palette: [
        Color(0xFF536DFE),
        Color(0xFF9575CD),
        Color(0xFF26C6DA),
        Color(0xFFFFCA28),
      ],
      accent: Color(0xFFFF7043),
    ),
    SkinDef(
      id: 'junkie_juice',
      name: 'Junkie Juice',
      description: 'TapJunkie signature toxic-lime and hot pink.',
      price: 500,
      palette: [
        Color(0xFF00FF6A),
        Color(0xFFFF4081),
        Color(0xFFFFFF00),
        Color(0xFF00E5FF),
      ],
      accent: Color(0xFFFFEA00),
      legendary: true,
    ),
  ];

  static SkinDef get defaultSkin =>
      all.firstWhere((s) => s.id == 'classic');

  static SkinDef byId(String id) {
    return all.firstWhere(
      (s) => s.id == id,
      orElse: () => defaultSkin,
    );
  }
}

/// Root app widget
class BalloonApp extends StatelessWidget {
  final GameStorage storage;
  const BalloonApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    final home = storage.seenOnboarding
        ? MainMenu(storage: storage)
        : OnboardingScreen(storage: storage);

    return MaterialApp(
      title: 'Balloon Burst',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: home,
    );
  }
}

/// ===============================
/// ONBOARDING
/// ===============================
class OnboardingScreen extends StatelessWidget {
  final GameStorage storage;
  const OnboardingScreen({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101528),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "WELCOME TO TAPJUNKIE",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "• Tap balloons to score.\n\n"
                  "• Golden balloons = bonus points & coins.\n\n"
                  "• Lightning balloons zap nearby balloons.\n\n"
                  "• Bomb balloons cost a life ONLY if you tap them.\n"
                  "  Let them float away.\n\n"
                  "• Chain quick pops to build Combo.\n"
                  "  Hit 10+ combo to trigger FRENZY.\n\n"
                  "• Earn coins to unlock skins in the TapJunkie Shop.",
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    storage.seenOnboarding = true;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MainMenu(storage: storage),
                      ),
                    );
                  },
                  child: const Text("Got it — Let’s Play!"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ===============================
/// MAIN MENU (stateful for refresh)
/// ===============================
class MainMenu extends StatefulWidget {
  final GameStorage storage;
  const MainMenu({super.key, required this.storage});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  @override
  void initState() {
    super.initState();
    widget.storage.ensureMissionsForToday();
  }

  @override
  Widget build(BuildContext context) {
    final storage = widget.storage;
    final canClaimDaily = storage.canClaimDailyReward;
    final equipped =
        TapJunkieSkins.byId(storage.equippedSkinId);

    return Scaffold(
      backgroundColor: const Color(0xFF101528),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "BALLOON BURST",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "High Score: ${storage.highScore}",
                  style:
                      const TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  "Best Combo: ${storage.bestCombo}",
                  style: const TextStyle(
                      fontSize: 16, color: Colors.cyanAccent),
                ),
                const SizedBox(height: 4),
                Text(
                  "Last Score: ${storage.lastScore}",
                  style: const TextStyle(
                      fontSize: 16, color: Colors.white54),
                ),
                const SizedBox(height: 4),
                Text(
                  "Coins: ${storage.coins}",
                  style: const TextStyle(
                      fontSize: 18, color: Colors.amberAccent),
                ),
                const SizedBox(height: 8),
                Text(
                  "Equipped Skin: ${equipped.name}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.lightBlueAccent,
                  ),
                ),
                const SizedBox(height: 16),

                // Daily reward section
                if (canClaimDaily)
                  ElevatedButton(
                    onPressed: () {
                      final reward = storage.claimDailyReward();
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Daily Reward"),
                          content: Text(
                            "You received $reward coins!\n"
                            "Streak: ${storage.dailyStreak} days",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );
                      setState(() {});
                    },
                    child: const Text("Claim Daily Reward"),
                  )
                else
                  Text(
                    "Daily streak: ${storage.dailyStreak} day(s)",
                    style: const TextStyle(
                        fontSize: 14, color: Colors.white70),
                  ),

                const SizedBox(height: 16),

                // Simple missions panel
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181C30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Missions",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightBlueAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _missionRow(
                        title: "Score 800+ in a run",
                        done: storage.missionScoreRewarded,
                      ),
                      _missionRow(
                        title: "Reach combo 20+",
                        done: storage.missionComboRewarded,
                      ),
                      _missionRow(
                        title: "Trigger Frenzy 3 times",
                        done: storage.missionFrenzyRewarded,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            GameScreen(storage: storage),
                      ),
                    );
                  },
                  child: const Text("PLAY"),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ShopScreen(storage: storage),
                      ),
                    );
                    setState(() {}); // refresh coins/skin
                  },
                  child: const Text("SHOP"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _missionRow({required String title, required bool done}) {
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: done ? Colors.greenAccent : Colors.white54,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: done ? Colors.greenAccent : Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
}

/// ===============================
/// TAPJUNKIE SHOP (Hybrid: preview + grid)
/// ===============================
class ShopScreen extends StatefulWidget {
  final GameStorage storage;
  const ShopScreen({super.key, required this.storage});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    final equippedId = widget.storage.equippedSkinId;
    final idx = TapJunkieSkins.all
        .indexWhere((s) => s.id == equippedId);
    selectedIndex = idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final storage = widget.storage;
    final skins = TapJunkieSkins.all;
    final selectedSkin = skins[selectedIndex];
    final owned = storage.isSkinOwned(selectedSkin.id);
    final isEquipped =
        storage.equippedSkinId == selectedSkin.id;

    return Scaffold(
      backgroundColor: const Color(0xFF050814),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050814),
        title: const Text("TapJunkie Shop"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top: big preview / carousel feel
            _buildBigPreview(selectedSkin, owned, isEquipped),
            const SizedBox(height: 16),
            // Coins display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.circle, color: Colors.amber),
                const SizedBox(width: 6),
                Text(
                  "Coins: ${storage.coins}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.amberAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Bottom: grid
            Expanded(
              child: GridView.builder(
                itemCount: skins.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  final skin = skins[index];
                  final skinOwned =
                      storage.isSkinOwned(skin.id);
                  final selected = index == selectedIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedIndex = index);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? skin.accent
                              : Colors.white24,
                          width: selected ? 2 : 1,
                        ),
                        gradient: LinearGradient(
                          colors: [
                            skin.palette.first,
                            skin.palette.last,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            skin.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (skin.legendary)
                            const Text(
                              "LEGENDARY",
                              style: TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 10,
                              ),
                            ),
                          Text(
                            skinOwned
                                ? (storage.equippedSkinId ==
                                        skin.id
                                    ? "Equipped"
                                    : "Owned")
                                : "${skin.price}c",
                            style: TextStyle(
                              fontSize: 11,
                              color: skinOwned
                                  ? Colors.greenAccent
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            _buildActionButton(selectedSkin, owned, isEquipped),
          ],
        ),
      ),
    );
  }

  Widget _buildBigPreview(
    SkinDef skin,
    bool owned,
    bool isEquipped,
  ) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF050814),
            skin.palette.first.withOpacity(0.4),
            skin.palette.last.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: skin.accent, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Balloon preview
          Expanded(
            flex: 2,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          skin.palette.first,
                          skin.palette.last,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: skin.accent.withOpacity(0.8),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  if (skin.legendary)
                    const Icon(
                      Icons.star,
                      color: Colors.yellowAccent,
                      size: 30,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Text info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  skin.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: skin.accent,
                  ),
                ),
                Text(
                  skin.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  owned
                      ? (isEquipped
                          ? "Equipped"
                          : "Owned")
                      : "${skin.price} coins",
                  style: TextStyle(
                    fontSize: 13,
                    color: owned
                        ? Colors.greenAccent
                        : Colors.amberAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    SkinDef skin,
    bool owned,
    bool isEquipped,
  ) {
    final storage = widget.storage;

    if (isEquipped) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.withOpacity(0.5),
        ),
        child: const Text("Equipped"),
      );
    }

    if (owned) {
      return ElevatedButton(
        onPressed: () {
          storage.equippedSkinId = skin.id;
          setState(() {});
        },
        child: const Text("Equip"),
      );
    }

    return ElevatedButton(
      onPressed: () {
        if (storage.coins < skin.price) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Not enough coins!"),
            ),
          );
          return;
        }
        storage.coins = storage.coins - skin.price;
        storage.unlockSkin(skin.id);
        storage.equippedSkinId = skin.id;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Unlocked ${skin.name}!",
            ),
          ),
        );
      },
      child: Text("Buy for ${skin.price}"),
    );
  }
}

/// ===============================
/// GAME SCREEN (wraps Flame Game)
/// ===============================
class GameScreen extends StatelessWidget {
  final GameStorage storage;
  const GameScreen({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    final skin =
        TapJunkieSkins.byId(storage.equippedSkinId);
    final game =
        BalloonGame(storage: storage, skin: skin);

    return Scaffold(
      body: GameWidget(
        game: game,
        overlayBuilderMap: {
          'GameOver': (context, game) => GameOverOverlay(
                game: game as BalloonGame,
                storage: storage,
              ),
        },
      ),
    );
  }
}

/// Types of balloons
enum BalloonType { normal, golden, bomb, lightning }

/// ===============================
/// CORE GAME (TapJunkie engine v1 + skins)
/// ===============================
class BalloonGame extends FlameGame {
  final GameStorage storage;
  final SkinDef skin;
  BalloonGame({required this.storage, required this.skin});

  final Random rng = Random();

  int score = 0;
  int lives = 3;
  int coinsEarned = 0;

  int combo = 0;
  int bestCombo = 0;

  bool inFrenzy = false;
  double frenzyTimeLeft = 0;
  double frenzyFlashTime = 0;

  double _lastPopTimeSeconds = 0;
  static const double _comboWindowSeconds = 0.8;

  double comboPulseTime = 0;

  int frenzyTriggersThisRun = 0;

  late TextComponent scoreText;
  late TextComponent livesText;
  late TextComponent coinsText;
  late TextComponent comboText;
  late TextComponent frenzyText;

  bool _gameOver = false;

  /// Messages about missions completed this run.
  List<String> missionMessages = [];

  @override
  Color backgroundColor() {
    if (frenzyFlashTime > 0) {
      return Colors.yellowAccent;
    }
    if (!inFrenzy) {
      return const Color(0xFF101528);
    }

    // Electric-green / firestorm palette
    final t = DateTime.now().millisecondsSinceEpoch ~/ 140 % 4;
    switch (t) {
      case 0:
        return const Color(0xFF00FF66); // neon green
      case 1:
        return const Color(0xFFFF8800); // fire orange
      case 2:
        return const Color(0xFFFFFF33); // electric yellow
      case 3:
      default:
        return const Color(0xFFFF0033); // hot red
    }
  }

  @override
  Future<void> onLoad() async {
    scoreText = TextComponent(
      text: "Score: 0",
      position: Vector2(10, 10),
      textRenderer:
          TextPaint(style: const TextStyle(color: Colors.white, fontSize: 16)),
    );
    livesText = TextComponent(
      text: "Lives: 3",
      position: Vector2(10, 30),
      textRenderer:
          TextPaint(style: const TextStyle(color: Colors.red, fontSize: 16)),
    );
    coinsText = TextComponent(
      text: "Coins: ${storage.coins}",
      position: Vector2(10, 50),
      textRenderer:
          TextPaint(style: const TextStyle(color: Colors.amber, fontSize: 16)),
    );
    comboText = TextComponent(
      text: "Combo: 0",
      position: Vector2(10, 70),
      textRenderer:
          TextPaint(style: const TextStyle(color: Colors.cyan, fontSize: 16)),
    );
    frenzyText = TextComponent(
      text: "",
      position: Vector2(10, 90),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.pinkAccent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    addAll([scoreText, livesText, coinsText, comboText, frenzyText]);

    add(
      TimerComponent(
        period: 0.7, // faster base spawn
        repeat: true,
        onTick: () {
          spawnBalloon();
          // Extra spawn during frenzy for chaos
          if (inFrenzy && rng.nextDouble() < 0.7) {
            spawnBalloon();
          }
        },
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (inFrenzy) {
      frenzyTimeLeft -= dt;
      if (frenzyTimeLeft <= 0) {
        inFrenzy = false;
        frenzyTimeLeft = 0;
        frenzyText.text = "";
      }
    }

    if (frenzyFlashTime > 0) {
      frenzyFlashTime -= dt;
      if (frenzyFlashTime < 0) frenzyFlashTime = 0;
    }

    if (comboPulseTime > 0) {
      comboPulseTime -= dt;
      if (comboPulseTime < 0) comboPulseTime = 0;
    }
    final pulseT = (comboPulseTime / 0.2).clamp(0.0, 1.0);
    final scale = 1.0 + 0.3 * pulseT;
    comboText.scale = Vector2.all(scale);
  }

  void spawnBalloon() {
    if (_gameOver || size.x <= 0 || size.y <= 0) return;

    final radius = 20 + rng.nextDouble() * 25;
    final x = radius + rng.nextDouble() * (size.x - radius * 2);
    final position = Vector2(x, size.y + radius + 20);

    // Balloon type RNG
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

    // TapJunkie speed curve
    double speed = 120 + score * 0.45;
    if (inFrenzy) speed *= 1.7;

    final baseColor = _colorForType(type);

    add(
      Balloon(
        skin: skin,        // 🔥 pass the equipped skin in
        type: type,
        radius: radius,
        position: position,
        speed: speed,
        baseColor: baseColor,
      ),
    );
  }

  Color _colorForType(BalloonType type) {
    switch (type) {
      case BalloonType.golden:
        return Colors.amberAccent;
      case BalloonType.bomb:
        return Colors.redAccent;
      case BalloonType.lightning:
        return Colors.lightBlueAccent;
      case BalloonType.normal:
      default:
        return skin.palette[rng.nextInt(skin.palette.length)];
    }
  }

  void handleBalloonTap(Balloon balloon) {
    if (_gameOver) return;

    // Basic system sound click (no assets needed)
    SystemSound.play(SystemSoundType.click);

    switch (balloon.type) {
      case BalloonType.bomb:
        _handleBombHit();
        break;
      case BalloonType.golden:
        _handlePop(balloonType: BalloonType.golden);
        break;
      case BalloonType.lightning:
        _handlePop(balloonType: BalloonType.lightning);
        _popNearbyBalloons(balloon);
        break;
      case BalloonType.normal:
      default:
        _handlePop(balloonType: BalloonType.normal);
        break;
    }

    balloon.removeFromParent();
  }

  void _handleBombHit() {
    combo = 0;
    comboText.text = "Combo: 0";

    lives -= 1;
    if (lives < 0) lives = 0;
    livesText.text = "Lives: $lives";

    if (lives <= 0) {
      _triggerGameOver();
    }
  }

  void _handlePop({required BalloonType balloonType}) {
    final nowSeconds =
        DateTime.now().millisecondsSinceEpoch / 1000.0;
    if (nowSeconds - _lastPopTimeSeconds <=
        _comboWindowSeconds) {
      combo++;
    } else {
      combo = 1;
    }
    _lastPopTimeSeconds = nowSeconds;

    if (combo > bestCombo) bestCombo = combo;

    // Enter frenzy at 10+ combo
    if (combo >= 10 && !inFrenzy) {
      inFrenzy = true;
      frenzyTimeLeft = 5;
      frenzyText.text = "FRENZY!";
      frenzyFlashTime = 0.15;
      frenzyTriggersThisRun++;
    }

    comboText.text = "Combo: $combo";
    comboPulseTime = 0.2;

    // TapJunkie scoring
    int base;
    switch (balloonType) {
      case BalloonType.golden:
        base = 5;
        break;
      case BalloonType.lightning:
        base = 3;
        break;
      case BalloonType.normal:
      case BalloonType.bomb:
      default:
        base = 1;
        break;
    }

    int multiplier = 1;
    if (combo >= 5) multiplier++;
    if (combo >= 15) multiplier++;
    if (inFrenzy) multiplier++;

    final gained = base * multiplier;

    score += gained;
    coinsEarned += gained;

    scoreText.text = "Score: $score";
    coinsText.text = "Coins: ${storage.coins + coinsEarned}";
  }

  void _popNearbyBalloons(Balloon source) {
    const double radius = 140;
    final toRemove = <Balloon>[];
    for (final c in children.whereType<Balloon>()) {
      if (c == source) continue;
      if (c.position.distanceTo(source.position) <= radius) {
        toRemove.add(c);
      }
    }
    for (final b in toRemove) {
      // chain pops count as normal pops
      _handlePop(balloonType: BalloonType.normal);
      b.removeFromParent();
    }
  }

  void handleMiss() {
    if (_gameOver) return;

    lives -= 1;
    if (lives < 0) lives = 0;
    livesText.text = "Lives: $lives";

    combo = 0;
    comboText.text = "Combo: 0";

    if (lives <= 0) {
      _triggerGameOver();
    }
  }

  void _triggerGameOver() {
    if (_gameOver) return;
    _gameOver = true;
    pauseEngine();

    storage.coins = storage.coins + coinsEarned;
    if (score > storage.highScore) storage.highScore = score;
    if (bestCombo > storage.bestCombo) storage.bestCombo = bestCombo;
    storage.lastScore = score;

    // Missions: ensure today's set, then apply rewards based on this run
    storage.ensureMissionsForToday();
    missionMessages = [];

    if (!storage.missionScoreRewarded && score >= 800) {
      storage.missionScoreRewarded = true;
      storage.coins = storage.coins + 100;
      missionMessages.add(
          "Mission complete: Score 800+ (+100 coins)");
    }
    if (!storage.missionComboRewarded && bestCombo >= 20) {
      storage.missionComboRewarded = true;
      storage.coins = storage.coins + 100;
      missionMessages.add(
          "Mission complete: Reach combo 20+ (+100 coins)");
    }
    if (!storage.missionFrenzyRewarded &&
        frenzyTriggersThisRun >= 3) {
      storage.missionFrenzyRewarded = true;
      storage.coins = storage.coins + 150;
      missionMessages.add(
          "Mission complete: Trigger Frenzy 3 times (+150 coins)");
    }

    overlays.add('GameOver');
  }
}

/// ===============================
/// BALLOON COMPONENT – Skin Engine C2 (Option D)
/// Skins now control color + glow. Legendary goes extra wild.
/// Bombs still only punish on tap (not when missed).
/// ===============================
class Balloon extends CircleComponent
    with TapCallbacks, HasGameRef<BalloonGame> {
  final double speed;
  final BalloonType type;
  final Color baseColor;
  final SkinDef skin; // 🔥 active skin at spawn time

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
    // Core fill starts from baseColor (already using skin palette for normal)
    paint = Paint()..color = _computeCoreColor();

    // Outer glow – strongly styled per skin and type
    glowPaint = Paint()
      ..color = _computeGlowColor().withOpacity(
        skin.legendary ? 0.95 : (type == BalloonType.normal ? 0.55 : 0.75),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    // Inner glow – subtle highlight inside the balloon
    innerGlowPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Hitbox so taps are reliable
    add(
      CircleHitbox()
        ..collisionType = CollisionType.inactive,
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
        return baseColor; // already chosen from skin.palette for normals
    }
  }

  Color _computeGlowColor() {
    switch (type) {
      case BalloonType.golden:
        return const Color(0xFFFFF176); // soft gold glow
      case BalloonType.bomb:
        return const Color(0xFFFF5252); // hot danger red
      case BalloonType.lightning:
        return const Color(0xFF40C4FF); // electric blue
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

    // IMPORTANT: bombs do NOT punish if they escape.
    if (position.y < -radius) {
      if (type != BalloonType.bomb) {
        gameRef.handleMiss();
      }
      removeFromParent();
    }

    // Bomb pulsation
    if (type == BalloonType.bomb) {
      final pulse = 0.5 + 0.3 * sin(_time * 8);
      glowPaint.color = glowPaint.color
          .withOpacity(pulse.clamp(0.25, 1.0).toDouble());
    }

    // Legendary skin: animate glow for ALL balloons under this skin
    if (skin.legendary) {
      final wave = 0.6 + 0.4 * sin(_time * 6);
      final base = _computeGlowColor();
      glowPaint.color = base.withOpacity(wave.clamp(0.4, 1.0));
    }

    // During Frenzy, give normals a subtle color shift for extra chaos
    if (gameRef.inFrenzy && type == BalloonType.normal) {
      final idx =
          ( (_time * 5).floor().abs() ) % skin.palette.length;
      paint.color = skin.palette[idx];
    }
  }

  @override
  void render(Canvas canvas) {
    // Outer aura: larger radius for special / legendary skins
    double auraRadius = radius * 1.6;
    if (skin.legendary) {
      auraRadius = radius * 1.9;
    } else if (type != BalloonType.normal) {
      auraRadius = radius * 1.8;
    }

    // Draw outer glow (TapJunkie identity)
    canvas.drawCircle(Offset.zero, auraRadius, glowPaint);

    // Draw inner soft glow highlight near top-left
    final highlightOffset = const Offset(-6, -6);
    canvas.drawCircle(highlightOffset, radius * 0.7, innerGlowPaint);

    // Base balloon fill
    super.render(canvas);

    // For legendary skin, draw a faint star highlight on top
    if (skin.legendary) {
      final starPaint = Paint()
        ..color = Colors.white.withOpacity(0.5);
      final center = Offset.zero;
      const starRadius = 4.0;

      // Simple 4-point star
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

/// ===============================
/// GAME OVER OVERLAY
/// ===============================
class GameOverOverlay extends StatelessWidget {
  final BalloonGame game;
  final GameStorage storage;

  const GameOverOverlay({
    super.key,
    required this.game,
    required this.storage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "GAME OVER",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
              const SizedBox(height: 12),
              Text("Score: ${game.score}"),
              Text("Best Combo (this run): ${game.bestCombo}"),
              Text("Coins this run: ${game.coinsEarned}"),
              Text("High Score: ${storage.highScore}"),
              Text("Best Combo: ${storage.bestCombo}"),
              Text("Total Coins: ${storage.coins}"),
              const SizedBox(height: 16),
              if (game.missionMessages.isNotEmpty) ...[
                const Text(
                  "Missions Completed:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.lightGreenAccent,
                  ),
                ),
                const SizedBox(height: 8),
                for (final msg in game.missionMessages)
                  Text(
                    "• $msg",
                    style: const TextStyle(
                      color: Colors.lightGreenAccent,
                    ),
                  ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MainMenu(storage: storage),
                    ),
                  );
                },
                child: const Text("Back to Menu"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
