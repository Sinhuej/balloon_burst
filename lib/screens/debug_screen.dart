import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:balloon_burst/game/game_state.dart';
import 'package:balloon_burst/game/balloon_spawner.dart';
import 'package:balloon_burst/debug/debug_log.dart'; // ✅ REQUIRED

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
              'Frames: ${widget.gameState.framesSinceStart}\n'
              'Total Pops: ${widget.spawner.totalPops}\n'
              'Speed Multiplier: ${widget.spawner.speedMultiplier.toStringAsFixed(2)}\n'
              'Spawn Interval: ${widget.spawner.spawnInterval.toStringAsFixed(2)}',
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
