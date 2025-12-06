import 'dart:math';
import 'dart:ui' show Canvas, MaskFilter, BlurStyle;
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(BalloonApp(storage: GameStorage(prefs)));
}

/// Simple storage for scores, coins, and meta.
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
}

/// Root app widget
class BalloonApp extends StatelessWidget {
  final GameStorage storage;
  const BalloonApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Balloon Burst',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: MainMenu(storage: storage),
    );
  }
}

/// ===============================
/// MAIN MENU
/// ===============================
class MainMenu extends StatelessWidget {
  final GameStorage storage;
  const MainMenu({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101528),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                "Best Combo: ${storage.bestCombo}",
                style: const TextStyle(fontSize: 16, color: Colors.cyanAccent),
              ),
              const SizedBox(height: 4),
              Text(
                "Last Score: ${storage.lastScore}",
                style: const TextStyle(fontSize: 16, color: Colors.white54),
              ),
              const SizedBox(height: 4),
              Text(
                "Coins: ${storage.coins}",
                style: const TextStyle(fontSize: 18, color: Colors.amberAccent),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameScreen(storage: storage),
                    ),
                  );
                },
                child: const Text("PLAY"),
              ),
            ],
          ),
        ),
      ),
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
    final game = BalloonGame(storage: storage);

    return Scaffold(
      body: GameWidget(
        game: game,
        overlayBuilderMap: {
          'GameOver': (context, game) =>
              GameOverOverlay(game: game as BalloonGame, storage: storage),
        },
      ),
    );
  }
}

/// Types of balloons
enum BalloonType { normal, golden, bomb, lightning }

/// ===============================
/// CORE GAME (TapJunkie Step A.2)
/// ===============================
class BalloonGame extends FlameGame {
  final GameStorage storage;
  BalloonGame({required this.storage});

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

  late TextComponent scoreText;
  late TextComponent livesText;
  late TextComponent coinsText;
  late TextComponent comboText;
  late TextComponent frenzyText;

  bool _gameOver = false;

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
        return Colors.primaries[rng.nextInt(Colors.primaries.length)];
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
    final nowSeconds = DateTime.now().millisecondsSinceEpoch / 1000.0;
    if (nowSeconds - _lastPopTimeSeconds <= _comboWindowSeconds) {
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

    overlays.add('GameOver');
  }
}

/// ===============================
/// BALLOON COMPONENT WITH GLOW
/// ===============================
class Balloon extends CircleComponent
    with TapCallbacks, HasGameRef<BalloonGame> {
  final double speed;
  final BalloonType type;
  final Color baseColor;

  late final Paint glowPaint;
  double _time = 0;

  Balloon({
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
    paint = Paint()..color = baseColor;

    // Neon glow for special balloons
    final glowColor = _glowColorForType(type);
    glowPaint = Paint()
      ..color = glowColor.withOpacity(0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  }

  Color _glowColorForType(BalloonType type) {
    switch (type) {
      case BalloonType.golden:
        return const Color(0xFFFFEE55); // neon gold
      case BalloonType.bomb:
        return const Color(0xFFFF3333); // hot red
      case BalloonType.lightning:
        return const Color(0xFF33CCFF); // electric blue
      case BalloonType.normal:
      default:
        return Colors.transparent;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    position.y -= speed * dt;

    if (position.y < -radius) {
      gameRef.handleMiss();
      removeFromParent();
    }

    // Bomb pulsation
    if (type == BalloonType.bomb) {
      final pulse = 0.5 + 0.3 * sin(_time * 8);
      glowPaint.color =
          glowPaint.color.withOpacity(pulse.clamp(0.2, 1.0).toDouble());
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw glow for special balloons
    if (type != BalloonType.normal) {
      canvas.drawCircle(Offset.zero, radius * 1.4, glowPaint);
    }
    super.render(canvas);
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Back to Menu"),
            ),
          ],
        ),
      ),
    );
  }
}
