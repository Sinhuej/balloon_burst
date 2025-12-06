import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(BalloonApp(storage: GameStorage(prefs)));
}

class GameStorage {
  final SharedPreferences prefs;
  GameStorage(this.prefs);

  int get highScore => prefs.getInt('high_score') ?? 0;
  set highScore(int v) => prefs.setInt('high_score', v);

  int get coins => prefs.getInt('coins') ?? 0;
  set coins(int v) => prefs.setInt('coins', v);
}

class BalloonApp extends StatelessWidget {
  final GameStorage storage;
  const BalloonApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: MainMenu(storage: storage),
    );
  }
}

class MainMenu extends StatelessWidget {
  final GameStorage storage;
  const MainMenu({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("BALLOON BURST", style: TextStyle(fontSize: 32)),
            const SizedBox(height: 20),
            Text("High Score: ${storage.highScore}"),
            Text("Coins: ${storage.coins}"),
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
    );
  }
}

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

class BalloonGame extends FlameGame with TapCallbacks {
  final GameStorage storage;
  BalloonGame({required this.storage});

  int score = 0;
  int lives = 3;
  final Random rng = Random();

  @override
  Future<void> onLoad() async {
    add(TimerComponent(
      period: 1,
      repeat: true,
      onTick: spawnBalloon,
    ));
  }

  void spawnBalloon() {
    final r = 20 + rng.nextDouble() * 20;
    final x = r + rng.nextDouble() * (size.x - 2 * r);

    add(Balloon(
      radius: r,
      position: Vector2(x, size.y + r),
      speed: 50,
      onPop: () {
        score++;
      },
      onMiss: () {
        lives--;
        if (lives <= 0) {
          storage.highScore = score > storage.highScore
              ? score
              : storage.highScore;
          storage.coins += score;
          pauseEngine();
          overlays.add('GameOver');
        }
      },
    ));
  }
}

class Balloon extends CircleComponent with TapCallbacks, HasGameRef<BalloonGame> {
  final double speed;
  final VoidCallback onPop;
  final VoidCallback onMiss;

  Balloon({
    required double radius,
    required Vector2 position,
    required this.speed,
    required this.onPop,
    required this.onMiss,
  }) : super(
          radius: radius,
          position: position,
          anchor: Anchor.center,
          paint: Paint()..color = Colors.primaries[Random().nextInt(Colors.primaries.length)],
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
    onPop();
    removeFromParent();
  }
}

class GameOverOverlay extends StatelessWidget {
  final BalloonGame game;
  final GameStorage storage;

  const GameOverOverlay({super.key, required this.game, required this.storage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        color: Colors.black54,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("GAME OVER", style: TextStyle(fontSize: 28)),
            Text("Score: ${game.score}"),
            Text("High Score: ${storage.highScore}"),
            const SizedBox(height: 20),
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
