import 'package:flutter/material.dart';

import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/game/balloon_spawner.dart';

import 'package:balloon_burst/screens/game_screen.dart';
import 'package:balloon_burst/screens/debug_screen.dart';

import 'package:balloon_burst/debug/debug_controller.dart';

import 'package:balloon_burst/tj_engine/engine/tj_engine.dart';

class AppRoot extends StatefulWidget {
  final TJEngine engine;

  const AppRoot({
    super.key,
    required this.engine,
  });

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final GameState _gameState = GameState();
  final BalloonSpawner _spawner = BalloonSpawner();
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
          gameState: _gameState,
          spawner: _spawner,
          debug: _debug,
          onClose: _closeDebug,
        );

      case ScreenMode.game:
      default:
        return GameScreen(
          gameState: _gameState,
          spawner: _spawner,
          engine: widget.engine,
          onRequestDebug: _openDebug,
        );
    }
  }
}
