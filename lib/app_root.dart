import 'package:flutter/material.dart';

import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/game/balloon_spawner.dart';

import 'package:balloon_burst/screens/game_screen.dart';
import 'package:balloon_burst/screens/debug_screen.dart';

import 'package:balloon_burst/debug/debug_controller.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final GameState _gameState = GameState();
  final BalloonSpawner _spawner = BalloonSpawner();

  // Legacy – kept for now so nothing explodes
  final DebugController _debug = DebugController();

  void _openDebug() {
    setState(() {
      _gameState.screenMode = ScreenMode.debug;
    });
  }

  void _closeDebug() {
    setState(() {
      _gameState.screenMode = ScreenMode.game;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_gameState.screenMode) {
      case ScreenMode.debug:
        return DebugScreen(
          gameState: _gameState,      // 🔑 THIS WAS MISSING
          spawner: _spawner,
          debug: _debug,              // still passed, but ignored internally
          onClose: _closeDebug,
        );

      case ScreenMode.game:
      default:
        return GameScreen(
          gameState: _gameState,
          spawner: _spawner,
          onRequestDebug: _openDebug,
        );
    }
  }
}
