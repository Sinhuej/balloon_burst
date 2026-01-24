import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/game/balloon_spawner.dart';

class DebugScreen extends StatefulWidget {
  final GameState gameState;
  final BalloonSpawner spawner;
  final VoidCallback onClose;

  const DebugScreen({
    super.key,
    required this.gameState,
    required this.spawner,
    required this.onClose,
  });

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  @override
  Widget build(BuildContext context) {
    final logs = widget.gameState.debugLogs.reversed.toList();

    final accuracyPercent =
        (widget.spawner.accuracyModifier * 100).clamp(0, 100);

    final worldProgressPercent =
        (widget.spawner.worldProgress * 100).clamp(0, 100);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug HUD'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onClose,
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.gameState.debugFrozen
                  ? Icons.play_arrow
                  : Icons.pause,
            ),
            tooltip: widget.gameState.debugFrozen
                ? 'Resume logging'
                : 'Freeze logging',
            onPressed: () {
              setState(() {
                widget.gameState.toggleFreeze();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear logs',
            onPressed: () {
              setState(() {
                widget.gameState.clearLogs();
              });
            },
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
              'World: ${widget.spawner.currentWorld}\n'
              'World Progress: ${worldProgressPercent.toStringAsFixed(1)}%\n'
              'Frames: ${widget.gameState.framesSinceStart}\n'
              'Total Pops: ${widget.spawner.totalPops}\n'
              'Recent Misses: ${widget.spawner.recentMisses}\n'
              'Accuracy: ${accuracyPercent.toStringAsFixed(1)}%\n'
              'Speed Multiplier: ${widget.spawner.speedMultiplier.toStringAsFixed(2)}\n'
              'Spawn Interval: ${widget.spawner.spawnIntervalValue.toStringAsFixed(2)}\n'
              'Game Over: ${widget.gameState.isGameOver}\n'
              'End Reason: ${widget.gameState.endReason ?? "-"}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),

          // --- FILTERS ---
          Wrap(
            spacing: 8,
            children: DebugEventType.values.map((type) {
              final enabled =
                  widget.gameState.enabledFilters.contains(type);

              return FilterChip(
                label: Text(type.name.toUpperCase()),
                selected: enabled,
                onSelected: (_) {
                  setState(() {
                    if (enabled) {
                      widget.gameState.enabledFilters.remove(type);
                    } else {
                      widget.gameState.enabledFilters.add(type);
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // --- COPY BUTTON ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy Debug Log'),
              onPressed: () {
                final text = logs.join('\n');
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
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  return Text(
                    logs[index],
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
  }
}
