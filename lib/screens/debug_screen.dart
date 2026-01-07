import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/game/balloon_spawner.dart';

class DebugScreen extends StatelessWidget {
  final GameState gameState;
  final BalloonSpawner spawner;
  final VoidCallback onClose;

  const DebugScreen({
    super.key,
    required this.gameState,
    required this.spawner,
    required this.onClose,
  });

  String _debugText() {
    return '''
World: ${gameState.currentWorld}
Frames: ${gameState.framesSinceStart}
Total Pops: ${spawner.totalPops}
Speed Multiplier: ${spawner.speedMultiplier.toStringAsFixed(2)}
Spawn Interval: ${spawner.spawnInterval.toStringAsFixed(2)}
''';
  }

  @override
  Widget build(BuildContext context) {
    final text = _debugText();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug HUD'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onClose,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: const TextStyle(fontFamily: 'monospace')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debug info copied')),
                );
              },
              child: const Text('Copy Debug Info'),
            ),
          ],
        ),
      ),
    );
  }
}
