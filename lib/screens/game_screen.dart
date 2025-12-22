import 'package:flutter/material.dart';
import '../game/game_controller.dart';
import '../gameplay/gameplay_debug.dart';
import '../game/commands/activate_powerup_command.dart';
import '../game/commands/spawn_balloon_command.dart';
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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(GameplayDebug.status(_controller)),
            const SizedBox(height: 12),

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

            ElevatedButton(
              onPressed: () => setState(() {
                _controller.execute(const SpawnBalloonCommand());
              }),
              child: const Text('Spawn Balloon'),
            ),

            ElevatedButton(
              onPressed: () => setState(() {
                _controller.autoExecuteSuggestions();
              }),
              child: const Text('Auto Action'),
            ),
          ],
        ),
      ),
    );
  }
}
