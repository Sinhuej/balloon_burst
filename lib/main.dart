import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storage = GameStorage(prefs);
  runApp(BalloonBurstApp(storage: storage));
}

/// Handles coins, skins, and high scores.
class GameStorage {
  final SharedPreferences prefs;

  static const _keyHighScore = 'high_score';
  static const _keyCoins = 'coins';
  static const _keySkin = 'selected_skin';

  GameStorage(this.prefs);

  int get highScore => prefs.getInt(_keyHighScore) ?? 0;
  set highScore(int v) => prefs.setInt(_keyHighScore, v);

  int get coins => prefs.getInt(_keyCoins) ?? 0;
  set coins(int v) => prefs.setInt(_keyCoins, v);

  String get selectedSkin => prefs.getString(_keySkin) ?? 'classic';
  set selectedSkin(String v) => prefs.setString(_keySkin, v);

  bool isSkinUnlocked(String id) {
    if (id == 'classic') return true;
    return prefs.getBool('skin_$id') ?? false;
  }

  void unlockSkin(String id) {
    if (id != 'classic') prefs.setBool('skin_$id', true);
  }
}

class BalloonBurstApp extends StatelessWidget {
  final GameStorage storage;
  const BalloonBurstApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: MainMenuScreen(storage: storage),
    );
  }
}

/// ------------------------------
/// MAIN MENU UI
/// ------------------------------
class MainMenuScreen extends StatefulWidget {
  final GameStorage storage;
  const MainMenuScreen({super.key, required this.storage});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  late int _coins;
  late int _highScore;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _coins = widget.storage.coins;
    _highScore = widget.storage.highScore;
  }

  Future<void> _startGame() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(storage: widget.storage),
      ),
    );
    setState(_refresh);
  }

  Future<void> _openShop() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopScreen(storage: widget.storage),
      ),
    );
    setState(_refresh);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101528),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "BALLOON BURST",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "High Score: $_highScore",
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 5),
              Text(
                "Coins: $_coins",
                style: const TextStyle(fontSize: 18, color: Colors.amberAccent),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _startGame,
                child: const Text("PLAY"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _openShop,
                child: const Text("SHOP & SKINS"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ------------------------------
/// GAME SCREEN
/// ------------------------------
class GameScreen extends StatelessWidget {
  final GameStorage storage;
  const GameScreen({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    final game = BalloonBurstGame(storage: storage);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Balloon Burst"),
        actions: [
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () => game.pause(),
          )
        ],
      ),
      body: GameWidget(
        game: game,
        overlayBuilderMap: {
          'PauseMenu': (ctx, game) => PauseOverlay(game: game),
          'GameOver': (ctx, game) =>
              GameOverOverlay(game: game, storage: storage),
        },
      ),
    );
  }
}

/// ------------------------------
/// FLAME GAME CORE LOGIC
/// ------------------------------
class BalloonBurstGame extends FlameGame with HasTappables {
  final GameStorage storage;
  BalloonBurstGame({required this.storage});

  final Random _rng = Random();
  int score = 0;
  int lives = 3;
  int coinsEarned = 0;

  late TextComponent scoreText;
  late TextComponent livesText;
  late TextComponent coinsText;

  bool gameOver = false;

  @override
  Color backgroundColor() => const Color(0xFF101528);

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

    add(scoreText);
    add(livesText);
    add(coinsText);

    add(TimerComponent(
      period: 0.9,
      repeat: true,
      onTick: spawnBalloon,
    ));
  }

  void spawnBalloon() {
    if (gameOver || size.x == 0) return;

    final radius = 20 + _rng.nextDouble() * 25;
    final x = radius + _rng.nextDouble() * (size.x - radius * 2);
    final isGolden = _rng.nextDouble() < 0.08;

    final balloon = Balloon(
      radius: radius,
      position: Vector2(x, size.y + radius + 20),
      speed: 60 + score * 0.3,
      isGolden: isGolden,
      color: isGolden ? Colors.amberAccent : Colors.primaries[_rng.nextInt(Colors.primaries.length)],
      onPop: handlePop,
      onMiss: handleMiss,
    );
    add(balloon);
  }

  void handlePop(bool golden) {
    final amount = golden ? 10 : 1;
    score += amount;
    coinsEarned += amount;

    scoreText.text = "Score: $score";
    coinsText.text = "Coins: ${storage.coins + coinsEarned}";
  }

  void handleMiss() {
    lives -= 1;
    if (lives <= 0) {
      triggerGameOver();
    }
    livesText.text = "Lives: $lives";
  }

  void triggerGameOver() {
    gameOver = true;
    pauseEngine();

    // Save coins
    storage.coins += coinsEarned;

    // Save high score
    if (score > storage.highScore) {
      storage.highScore = score;
    }

    overlays.add("GameOver");
  }

  void pause() {
    pauseEngine();
    overlays.add("PauseMenu");
  }

  void resume() {
    overlays.remove("PauseMenu");
    resumeEngine();
  }

  void restart() {
    children.whereType<Balloon>().forEach((b) => b.removeFromParent());
    score = 0;
    lives = 3;
    coinsEarned = 0;
    gameOver = false;

    scoreText.text = "Score: 0";
    livesText.text = "Lives: 3";
    coinsText.text = "Coins: ${storage.coins}";

    overlays.remove("GameOver");
    resumeEngine();
  }
}

/// ------------------------------
/// BALLOON COMPONENT
/// ------------------------------
class Balloon extends CircleComponent with TapCallbacks, HasGameRef<BalloonBurstGame> {
  final double speed;
  final bool isGolden;
  final Function(bool golden) onPop;
  final VoidCallback onMiss;

  Balloon({
    required double radius,
    required Vector2 position,
    required this.speed,
    required this.isGolden,
    required Color color,
    required this.onPop,
    required this.onMiss,
  }) : super(
          radius: radius,
          position: position,
          anchor: Anchor.center,
          paint: Paint()..color = color,
        );

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= speed * dt;

    if (position.y < -radius) {
      onMiss();
      removeFromParent();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    onPop(isGolden);
    removeFromParent();
  }
}

/// ------------------------------
/// PAUSE OVERLAY
/// ------------------------------
class PauseOverlay extends StatelessWidget {
  final BalloonBurstGame game;
  const PauseOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black45,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Paused", style: TextStyle(fontSize: 24)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: game.resume,
            child: const Text("Resume"),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------
/// GAME OVER OVERLAY
/// ------------------------------
class GameOverOverlay extends StatelessWidget {
  final BalloonBurstGame game;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "GAME OVER",
            style: TextStyle(fontSize: 28, color: Colors.pinkAccent),
          ),
          const SizedBox(height: 10),
          Text("Score: ${game.score}"),
          Text("High Score: ${storage.highScore}"),
          Text("Coins Earned: ${game.coinsEarned}"),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: game.restart,
            child: const Text("Play Again"),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Quit to Menu"),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------
/// SHOP SCREEN
/// ------------------------------
class ShopScreen extends StatefulWidget {
  final GameStorage storage;
  const ShopScreen({super.key, required this.storage});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  Widget build(BuildContext context) {
    final skins = [
      Skin("classic", "Classic Party", 0),
      Skin("sunset", "Sunset Glow", 150),
      Skin("neon", "Neon Arcade", 300),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Shop & Skins")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Coins: ${widget.storage.coins}",
            style: const TextStyle(color: Colors.amberAccent, fontSize: 20),
          ),
          const SizedBox(height: 20),
          ...skins.map((skin) => _buildSkinTile(skin)),
        ],
      ),
    );
  }

  Widget _buildSkinTile(Skin skin) {
    final unlocked = widget.storage.isSkinUnlocked(skin.id);
    final equipped = widget.storage.selectedSkin == skin.id;

    return Card(
      child: ListTile(
        title: Text(skin.name),
        subtitle: Text("Cost: ${skin.cost}"),
        trailing: unlocked
            ? (equipped
                ? const Chip(label: Text("Equipped"))
                : TextButton(
                    onPressed: () {
                      widget.storage.selectedSkin = skin.id;
                      setState(() {});
                    },
                    child: const Text("Equip"),
                  ))
            : TextButton(
                onPressed: () {
                  if (widget.storage.coins >= skin.cost) {
                    widget.storage.coins -= skin.cost;
                    widget.storage.unlockSkin(skin.id);
                    setState(() {});
                  }
                },
                child: const Text("Buy"),
              ),
      ),
    );
  }
}

class Skin {
  final String id;
  final String name;
  final int cost;
  Skin(this.id, this.name, this.cost);
}

