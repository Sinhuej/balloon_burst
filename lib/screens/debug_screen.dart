import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:balloon_burst/debug/debug_controller.dart';
import 'package:balloon_burst/game/balloon_spawner.dart';

class DebugScreen extends StatelessWidget {
  final DebugController debug;
  final BalloonSpawner spawner;
  final VoidCallback onClose;

  const DebugScreen({
    super.key,
    required this.debug,
    required this.spawner,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: debug,
      builder: (context, _) {
        final events = debug.events.reversed.toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Debug HUD'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onClose,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear logs',
                onPressed: debug.clear,
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SUMMARY ---
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'World: ${spawner.currentWorld}\n'
                  'Frame: ${debug.frame}\n'
                  'Total Pops: ${spawner.totalPops}\n'
                  'Speed Multiplier: ${spawner.speedMultiplier.toStringAsFixed(2)}\n'
                  'Spawn Interval: ${spawner.spawnInterval.toStringAsFixed(2)}',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),

              // --- COPY BUTTON ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Debug Log'),
                  onPressed: () {
                    final text = events
                        .map((e) =>
                            '[${e.frame}] ${e.category}: ${e.message}')
                        .join('\n');

                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Debug log copied')),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // --- LOG VIEW ---
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  color: Colors.black.withOpacity(0.05),
                  child: ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final e = events[index];
                      return Text(
                        '[${e.frame}] ${e.category}: ${e.message}',
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
        );
      },
    );
  }
}
