import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storage = GameStorage(prefs);
  runApp(BalloonBurstApp(storage: storage));
}

/// Simple storage wrapper for coins, high score, and skins.
class GameStorage {
  final SharedPreferences prefs;

  static const _keyHighScore = 'high_score';
  static const _keyCoins = 'coins';
  static const _keySkin = 'selected_skin';

  GameStorage(this.prefs);

  int get highScore => prefs.getInt(_keyHighScore) ?? 0;
  set highScore(int value) => prefs.setInt(_keyHighScore, value);

  int get coins => prefs.getInt(_keyCoins) ?? 0;
  set coins(int value) => prefs.setInt(_keyCoins, value);

  String get selectedSkin => prefs.getString(_keySkin) ?? 'classic';
  set selectedSkin(String value) => prefs.setString(_keySkin, value);

  bool isSkinUnlocked(String id) {
    if (id == 'classic') return true;
    return prefs.getBool('skin_$id') ?? false;
  }

  void unlockSkin(String id) {
    if (id == 'classic') return;
    prefs.setBool('skin_$id', true);
  }
}

class BalloonBurstApp extends StatelessWidget {
  final GameStorage storage;
  const BalloonBurstApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Balloon Burst',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pinkAccent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF101528),
      ),
      home: MainMenuScreen(storage: storage),
    );
  }
}

/// MAIN MENU SCREEN
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
    _load();
  }

  void _load() {
    _coins = widget.storage.coins;
    _highScore = widget.storage.highScore;
  }

  Future<void> _openGame() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(storage: widget.storage),
      ),
    );
    setState(_load);
  }

  Future<void> _openShop() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShopScreen(storage: widget.storage),
      ),
    );
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoChip(
                      icon: Icons.star,
                      label: 'Best',
                      value: '$_highScore',
                    ),
                    _InfoChip(
                      icon: Icons.monetization_on,
                      label: 'Coins',
                      value: '$_coins',
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Balloon Burst',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap. Pop. Combo. Cash in.',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 32),
                _MenuButton(
                  icon: Icons.play_arrow,
                  text: 'Play',
                  onTap: _openGame,
                ),
                const SizedBox(height: 12),
                _MenuButton(
                  icon: Icons.store,
                  text: 'Shop & Skins',
                  onTap: _openShop,
                ),
                const SizedBox(height: 24),
                // TapJunkie cross-promo strip
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TapJunkie Arcade',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          _PromoCard(
                            title: 'Ticket Quest',
                            subtitle: 'Win tickets, claim prizes',
                          ),
                          _PromoCard(
                            title: 'Kitchen Chaos',
                            subtitle: 'Survive the dinner rush',
                          ),
                          _PromoCard(
                            title: 'Spot the Clock',
                            subtitle: 'Hidden object speed run',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white10,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.amberAccent),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PromoCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const Spacer(),
          const Text(
            'Coming soon',
            style: TextStyle(fontSize: 10, color: Colors.pinkAccent),
          ),
        ],
      ),
    );
  }
}

/// GAME SCREEN (hosts Flame GameWidget)
class GameScreen extends StatefulWidget {
  final GameStorage storage;
  const GameScreen({super.key, required this.storage});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late BalloonBurstGame _game;

  @override
  void initState() {
    super.initState();
    _game = BalloonBurstGame(storage: widget.storage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101528),
      appBar: AppBar(
        title: const Text('Balloon Burst'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () {
              _game.pauseGame(showOverlay: true);
            },
          ),
        ],
      ),
      body: GameWidget<BalloonBurstGame>(
        game: _game,
        overlayBuilderMap: {
          'PauseMenu': (ctx, game) => PauseOverlay(
                game: game,
              ),
          'GameOver': (ctx, game) => GameOverOverlay(
                game: game,
                storage: widget.storage,
                onQuitToMenu: () {
                  Navigator.of(context).pop();
                },
              ),
        },
      ),
    );
  }
}

/// TapJunkie Ads stub – safe placeholder for real networks.
class TapJunkieAds {
  static Future<void> showInterstitial(
    BuildContext context, {
    VoidCallback? onClosed,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Showing interstitial ad (placeholder)…'),
        duration: Duration(milliseconds: 800),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 900));
    onClosed?.call();
  }

  static Future<void> showRewarded(
    BuildContext context, {
    required VoidCallback onReward,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Showing rewarded ad (placeholder)…'),
        duration: Duration(seconds: 1),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    onReward();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You earned a reward!'),
      ),
    );
  }
}

/// FLAME GAME LOGIC
class BalloonBurstGame extends FlameGame with HasTappables {
  final GameStorage storage;
  final Random _rng = Random();

  int score = 0;
  int lives = 3;
  int highScore = 0;
  int totalCoins = 0;
  int coinsThisRun = 0;

  double _lastPopTimeSeconds = 0;
  int comboCount = 0;
  int bestCombo = 0;

  late TimerComponent _spawnTimer;

  late TextComponent _scoreText;
  late TextComponent _livesText;
  late TextComponent _coinsText;

  bool isGameOver = false;

  late List<Color> _palette;

  BalloonBurstGame({required this.storage});

  @override
  Color backgroundColor() => const Color(0xFF101528);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    highScore = storage.highScore;
    totalCoins = storage.coins;
    _configurePalette();

    _scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(8, 8),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    _livesText = TextComponent(
      text: 'Lives: 3',
      position: Vector2(8, 34),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 18,
        ),
      ),
    );

    _coinsText = TextComponent(
      text: 'Coins: $totalCoins',
      anchor: Anchor.topRight,
      position: Vector2(size.x - 8, 8),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.amberAccent,
          fontSize: 18,
        ),
      ),
    );

    add(_scoreText);
    add(_livesText);
    add(_coinsText);

    _spawnTimer = TimerComponent(
      period: 0.9,
      repeat: true,
      onTick: _spawnBalloon,
    );
    add(_spawnTimer);
  }

  void _configurePalette() {
    switch (storage.selectedSkin) {
      case 'sunset':
        _palette = [
          Colors.deepOrange,
          Colors.orange,
          Colors.pinkAccent,
          Colors.redAccent,
        ];
        break;
      case 'neon':
        _palette = [
          Colors.cyanAccent,
          Colors.limeAccent,
          Colors.pinkAccent,
          Colors.purpleAccent,
        ];
        break;
      default:
        _palette = Colors.primaries;
        break;
    }
  }

  void _spawnBalloon() {
    if (isGameOver || size.y == 0) return;

    final double radius = 20 + _rng.nextDouble() * 25;
    final bool isGolden = _rng.nextDouble() < 0.08; // 8% powerup balloons

    final double x = radius + _rng.nextDouble() * (size.x - 2 * radius);
    final double y = size.y + radius + 10;

    final double baseSpeed = 60 + _rng.nextDouble() * 80;
    final double difficultyBoost = score * 0.4;
    final double speed = baseSpeed + difficultyBoost;

    final color = isGolden
        ? Colors.amberAccent
        : _palette[_rng.nextInt(_palette.length)];

    final balloon = Balloon(
      radius: radius,
      position: Vector2(x, y),
      speed: speed,
      isGolden: isGolden,
      color: color,
      onPop: _handlePop,
      onMiss: _handleMiss,
    );
    add(balloon);
  }

  void _handlePop(bool isGolden) {
    if (isGameOver) return;

    final nowSeconds = DateTime.now().millisecondsSinceEpoch / 1000.0;
    if (nowSeconds - _lastPopTimeSeconds <= 2.0) {
      comboCount++;
    } else {
      comboCount = 1;
    }
    _lastPopTimeSeconds = nowSeconds;
    if (comboCount > bestCombo) bestCombo = comboCount;

    int base = isGolden ? 10 : 1;
    int multiplier = 1 + (comboCount ~/ 5);
    int gained = base * multiplier;

    score += gained;
    coinsThisRun += gained;

    _scoreText.text = 'Score: $score';
    _coinsText.text = 'Coins: ${totalCoins + coinsThisRun}';
  }

  void _handleMiss() {
    if (isGameOver) return;
    lives -= 1;
    if (lives < 0) lives = 0;
    _livesText.text = 'Lives: $lives';

    if (lives <= 0) {
      _triggerGameOver();
    }
  }

  void _triggerGameOver() {
    if (isGameOver) return;
    isGameOver = true;
    pauseEngine();

    totalCoins = storage.coins + coinsThisRun;
    storage.coins = totalCoins;

    if (score > highScore) {
      highScore = score;
      storage.highScore = highScore;
    }

    overlays.add('GameOver');
  }

  void pauseGame({bool showOverlay = false}) {
    if (isGameOver) return;
    pauseEngine();
    if (showOverlay) {
      overlays.add('PauseMenu');
    }
  }

  void resumeGame() {
    if (isGameOver) return;
    overlays.remove('PauseMenu');
    resumeEngine();
  }

  void restartGame() {
    // Remove existing balloons
    for (final b in children.whereType<Balloon>().toList()) {
      b.removeFromParent();
    }

    score = 0;
    lives = 3;
    coinsThisRun = 0;
    comboCount = 0;
    bestCombo = 0;
    isGameOver = false;

    _scoreText.text = 'Score: 0';
    _livesText.text = 'Lives: 3';
    _coinsText.text = 'Coins: $totalCoins';

    overlays.remove('GameOver');
    resumeEngine();
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    // Keep coins text anchored to top-right on resize.
    if (_coinsText.isMounted) {
      _coinsText.position = Vector2(canvasSize.x - 8, 8);
    }
  }
}

class Balloon extends CircleComponent
    with TapCallbacks, HasGameRef<BalloonBurstGame> {
  final double speed;
  final bool isGolden;
  final void Function(bool isGolden) onPop;
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

    if (position.y + radius < 0) {
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

/// PAUSE OVERLAY
class PauseOverlay extends StatelessWidget {
  final BalloonBurstGame game;
  const PauseOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Colors.black54),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF202840),
              borderRadius: BorderRadius.circular(16),
            ),
            width: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Paused',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Score: ${game.score}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    game.resumeGame();
                  },
                  child: const Text('Resume'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// GAME OVER OVERLAY WITH REWARD OPTION
class GameOverOverlay extends StatelessWidget {
  final BalloonBurstGame game;
  final GameStorage storage;
  final VoidCallback onQuitToMenu;

  const GameOverOverlay({
    super.key,
    required this.game,
    required this.storage,
    required this.onQuitToMenu,
  });

  @override
  Widget build(BuildContext context) {
    final totalCoins = storage.coins;
    final coinsThisRun = game.coinsThisRun;

    return Stack(
      children: [
        Container(color: Colors.black87),
        Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF202840),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Game Over',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.pinkAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Score: ${game.score}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Best: ${game.highScore}',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Run coins: $coinsThisRun',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.amberAccent,
                    ),
                  ),
                  Text(
                    'Total coins: $totalCoins',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      game.restartGame();
                    },
                    child: const Text('Play Again'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await TapJunkieAds.showRewarded(
                        context,
                        onReward: () {
                          storage.coins = storage.coins + 50;
                          game.totalCoins = storage.coins;
                        },
                      );
                    },
                    icon: const Icon(Icons.play_circle_fill),
                    label: const Text('+50 Coins (Reward Ad)'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: onQuitToMenu,
                    child: const Text('Back to Menu'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// SHOP / SKIN SCREEN
class ShopScreen extends StatefulWidget {
  final GameStorage storage;
  const ShopScreen({super.key, required this.storage});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late int _coins;
  late String _selectedSkin;

  @override
  void initState() {
    super.initState();
    _coins = widget.storage.coins;
    _selectedSkin = widget.storage.selectedSkin;
  }

  void _refresh() {
    setState(() {
      _coins = widget.storage.coins;
      _selectedSkin = widget.storage.selectedSkin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final skins = [
      _SkinDef(
        id: 'classic',
        name: 'Classic Party',
        cost: 0,
        description: 'Original balloon colors.',
      ),
      _SkinDef(
        id: 'sunset',
        name: 'Sunset Glow',
        cost: 150,
        description: 'Warm oranges & pink skies.',
      ),
      _SkinDef(
        id: 'neon',
        name: 'Neon Arcade',
        cost: 300,
        description: 'Bright neon pop for TapJunkie.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop & Skins'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amberAccent),
                const SizedBox(width: 8),
                Text(
                  'Coins: $_coins',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: skins.length,
                itemBuilder: (context, index) {
                  final skin = skins[index];
                  final unlocked =
                      widget.storage.isSkinUnlocked(skin.id) || skin.cost == 0;
                  final isSelected = _selectedSkin == skin.id;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(skin.name),
                      subtitle: Text(
                        '${skin.description}\nCost: ${skin.cost} coins',
                      ),
                      isThreeLine: true,
                      trailing: unlocked
                          ? (isSelected
                              ? const Chip(
                                  label: Text('Equipped'),
                                  backgroundColor: Colors.pinkAccent,
                                )
                              : TextButton(
                                  onPressed: () {
                                    widget.storage.selectedSkin = skin.id;
                                    _refresh();
                                  },
                                  child: const Text('Equip'),
                                ))
                          : TextButton(
                              onPressed: () {
                                if (_coins >= skin.cost) {
                                  widget.storage.coins =
                                      widget.storage.coins - skin.cost;
                                  widget.storage.unlockSkin(skin.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Unlocked ${skin.name} skin!'),
                                    ),
                                  );
                                  _refresh();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Not enough coins!'),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Buy'),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkinDef {
  final String id;
  final String name;
  final int cost;
  final String description;

  _SkinDef({
    required this.id,
    required this.name,
    required this.cost,
    required this.description,
  });
}

