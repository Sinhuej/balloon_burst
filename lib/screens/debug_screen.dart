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

  String _headerText() {
    return '''
World: ${spawner.currentWorld}
Frames: ${gameState.framesSinceStart}
Total Pops: ${spawner.totalPops}
Speed Multiplier: ${spawner.speedMultiplier.toStringAsFixed(2)}
Spawn Interval: ${spawner.spawnInterval.toStringAsFixed(2)}
''';
  }

  String _allLogsText() {
    return gameState.debugLogs.reversed.join('\n');
  }

  void _copyAll(BuildContext context) {
    final text = '''
=== BALLOON BURST DEBUG ===
${_headerText()}
--- EVENT LOG ---
${_allLogsText()}
''';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debug log copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            // --------------------
            // Snapshot state
            // --------------------
            Text(
              _headerText(),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 12),

            // --------------------
            // Copy button
            // --------------------
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy Debug Info'),
              onPressed: () => _copyAll(context),
            ),

            const SizedBox(height: 16),

            const Text(
              'Event Log',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // --------------------
            // Scrollable log view
            // --------------------
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black12,
                child: ListView.builder(
                  itemCount: gameState.debugLogs.length,
                  itemBuilder: (context, index) {
                    final line = gameState.debugLogs[index];
                    return Text(
                      line,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
