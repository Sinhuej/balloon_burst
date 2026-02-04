import 'package:flutter/material.dart';

import 'game/game_state.dart';
import 'game/balloon_spawner.dart';
import 'debug/debug_controller.dart';

import 'screens/game_screen.dart';
import 'screens/debug_screen.dart';
import 'screens/blank_screen.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final GameState _gameState = GameState();
  final BalloonSpawner _spawner = BalloonSpawner();
  final DebugController _debug = DebugController();

  @override
  Widget build(BuildContext context) {
    switch (_gameState.screenMode) {
      case ScreenMode.debug:
        return DebugScreen(
          debug: _debug,
          spawner: _spawner,
          onClose: () {
            setState(() {
              _gameState.screenMode = ScreenMode.game;
            });
          },
        );

      case ScreenMode.blank:
        return const BlankScreen();

      case ScreenMode.game:
      default:
        return GameScreen(
          gameState: _gameState,
          spawner: _spawner,
          onRequestDebug: () {
            setState(() {
              _gameState.screenMode = ScreenMode.debug;
            });
          },
        );
    }
  }
}
