import 'package:flutter/material.dart';
import 'game_screen_args.dart';

class GameScreen extends StatelessWidget {
  final GameScreenArgs? args;

  const GameScreen({
    super.key,
    this.args,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Game Screen (WIP)',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
