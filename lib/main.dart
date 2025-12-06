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

/// SIMPLE DATA STORAGE (coins, high score, skins)
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

  bool isSkinUnlocked(String id) => id == 'classic' || (prefs.getBool('skin_$id') ?? false);
  void unlockSkin(String id) => prefs.setBool('skin_$id', true);
}

/// APP ROOT
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

/// ===============================
/// MAIN MENU
/// ===============================
class MainMenuScreen extends StatefulWidget {
  final GameStorage storage;
  const MainMenuScreen({super.key, required this.storage});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101528),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("BALLOON BURST",
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
            const SizedBox(height: 20),
            Text("High Score: ${widget.storage.highScore}",
                style: const TextStyle(fontSize: 18)),
            Text("Coins: ${widget.storage.coins}",
                style: const TextStyle(fontSize: 18, color: Colors.amberAccent)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => GameScreen(storage: widget.storage),
                  ));
              },
              child: const Text("PLAY"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => ShopScreen(storage: widget.storage),
                  ));
              },
              child: const Text("SHOP"),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================
/// GAME SCREEN (Flame GameWidget)
/// ===============================
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
            onPressed: () => game.pauseGame(),
          )
        ],
      ),
      body: GameWidget<BalloonBurstGame>(
        game: game,
        overlayBuilderMap: {
          'PauseMenu': (context, BalloonBurstGame game) =>
            PauseOverlay(game: game),
          'GameOver': (context, BalloonBurstGame game) =>
            GameOverOverlay(game: game, storage: storage),
        },
      ),
    );
  }
}

/// ===============================
/// FLAME GAME CORE
/// ===============================
class BalloonBurstGame extends FlameGame with HasTappableComponents {
  final GameStorage storage;
  BalloonBurstGame({required this.storage});

  final Random rng = Random();
  int score = 0;
  int lives = 3;
  int coinsEarned = 0;

  bool isGameOver = false;

  late TextComponent scoreText;
  late TextComponent livesText;
  late TextComponent coinsText;

  @override
  Future<void> onLoad() async {
    scoreText = TextComponent(
      text: "Score: 0",
      position: Vector2(10, 10),
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white)),
    );
    livesText = TextComponent(
      text: "Lives: 3",
      position: Vector2(10, 30),
      textRenderer: TextPaint(style: const TextStyle(color: Colors.red)),
    );
    coinsText = TextComponent(
      text: "Coins: ${storage.coins}",
      position: Vector2(10, 50),
      textRenderer: TextPaint(style: const TextStyle(color: Colors.amber)),
    );

    add(scoreText);
    add(livesText);
    add(coinsText);

    add(TimerComponent(
      period: 1,
      repeat: true,
      onTick: spawnBalloon,
    ));
  }

  void spawnBalloon() {
    if (isGameOver) return;

    final radius = 20 + rng.nextDouble() * 25;
    final x = radius + rng.nextDouble() * (size.x - radius * 2);

    final isGolden = rng.nextDouble() < 0.1;

    final balloon = Balloon(
      radius: radius,
      position: Vector2(x, size.y + radius + 10),
      speed: 50 + score * 0.3,
      isGolden: isGolden,
      color: isGolden ? Colors.amberAccent : Colors.primaries[rng.nextInt(Colors.primaries.length)],
      onPop: handlePop,
      onMiss: handleMiss,
    );

    add(balloon);
  }

  void handlePop(bool golden) {
    final gained = golden ? 10 : 1;
    score += gained;
    coinsEarned += gained;

    scoreText.text = "Score: $score";
    coinsText.text = "Coins: ${storage.coins + coinsEarned}";
  }

  void handleMiss() {
    lives -= 1;
    livesText.text = "Lives: $lives";

    if (lives <= 0) {
      endGame();
    }
  }

  void endGame() {
    isGameOver = true;
    pauseEngine();

    storage.coins += coinsEarned;
    if (score > storage.highScore) storage.highScore = score;

    overlays.add("GameOver");
  }

  void pauseGame() {
    pauseEngine();
    overlays.add("PauseMenu");
  }

  void resumeGame() {
    overlays.remove("PauseMenu");
    resumeEngine();
  }

  void restart() {
    children.whereType<Balloon>().forEach((b) => b.removeFromParent());

    score = 0;
    lives = 3;
    coinsEarned = 0;
    isGameOver = false;

    scoreText.text = "Score: 0";
    livesText.text = "Lives: 3";
    coinsText.text = "Coins: ${storage.coins}";

    overlays.remove("GameOver");
    resumeEngine();
  }
}

/// ===============================
/// BALLOON COMPONENT
/// ===============================
class Balloon extends CircleComponent
    with TapCallbacks, HasGameRef<BalloonBurstGame> {
  final double speed;
  final bool isGolden;
  final Function(bool) onPop;
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

/// ===============================
/// PAUSE OVERLAY
/// ===============================
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
            onPressed: game.resumeGame,
            child: const Text("Resume"),
          )
        ],
      ),
    );
  }
}

/// ===============================
/// GAME OVER OVERLAY
/// ===============================
class GameOverOverlay extends StatelessWidget {
  final BalloonBurstGame game;
  final GameStorage storage;

  const GameOverOverlay({super.key, required this.game, required this.storage});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("GAME OVER",
              style: TextStyle(fontSize: 28, color: Colors.pinkAccent)),
          Text("Score: ${game.score}"),
          Text("High Score: ${storage.highScore}"),
          Text("Coins Earned: ${game.coinsEarned}"),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: game.restart,
            child: const Text("Play Again"),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Quit to Menu"),
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// SHOP SCREEN
/// ===============================
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
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text("Coins: ${widget.storage.coins}",
              style: const TextStyle(color: Colors.amber, fontSize: 20)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: skins.map((skin) => _buildTile(skin)).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTile(Skin skin) {
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
                    child: const Text("Equip"),
                    onPressed: () {
                      widget.storage.selectedSkin = skin.id;
                      setState(() {});
                    },
                  ))
            : TextButton(
                child: const Text("Buy"),
                onPressed: () {
                  if (widget.storage.coins >= skin.cost) {
                    widget.storage.coins -= skin.cost;
                    widget.storage.unlockSkin(skin.id);
                    setState(() {});
                  }
                }),
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

