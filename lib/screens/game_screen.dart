import 'package:flutter/material.dart';
import '../game/game_controller.dart';
import '../game/commands/pop_balloon_command.dart';
import '../game/commands/activate_powerup_command.dart';
import '../game/powerups/power_up.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final world = _controller.gameplayWorld;

    if (world == null) {
      return const Scaffold(body: Center(child: Text('Loading…')));
    }

    if (world.isWin) {
      return _endScreen('YOU WIN');
    }

    if (world.isGameOver) {
      return _endScreen('GAME OVER');
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Score: ${world.score}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: List.generate(world.balloons.length, (i) {
                  final b = world.balloons[i];
                  return GestureDetector(
                    onTap: b.isPopped
                        ? null
                        : () => setState(() {
                              _controller.execute(
                                PopBalloonCommand(i),
                              );
                            }),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color:
                            b.isPopped ? Colors.grey : Colors.pinkAccent,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Center(
                        child: Text(
                          b.isPopped ? 'POP!' : 'Balloon ${b.id}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() {
                    _controller.execute(
                      const ActivatePowerUpCommand(DoublePopPowerUp()),
                    );
                  }),
                  child: const Text('Double Pop'),
                ),
                ElevatedButton(
                  onPressed: () => setState(() {
                    _controller.execute(
                      const ActivatePowerUpCommand(BombPopPowerUp()),
                    );
                  }),
                  child: const Text('Bomb Pop'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _endScreen(String text) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() {
                _controller.start();
              }),
              child: const Text('Restart'),
            ),
          ],
        ),
      ),
    );
  }
}
