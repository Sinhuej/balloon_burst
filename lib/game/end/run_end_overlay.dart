import 'package:flutter/material.dart';
import 'package:balloon_burst/screens/leaderboard_screen.dart';
import 'run_end_state.dart';
import 'run_end_messages.dart';
import 'package:balloon_burst/tj_engine/engine/tj_engine.dart';

class RunEndOverlay extends StatelessWidget {
  final RunEndState state;
  final VoidCallback onReplay;
  final int? placement;
  final TJEngine engine;

  const RunEndOverlay({
    super.key,
    required this.state,
    required this.onReplay,
    required this.engine,
    this.placement,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onReplay,
      child: Container(
        color: Colors.black.withOpacity(0.75),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            if (placement != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'NEW #$placement!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),

            Text(
              RunEndMessages.title(state),
              style: const TextStyle(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              RunEndMessages.body(state),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            Text(
              RunEndMessages.action(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        LeaderboardScreen(engine: engine),
                  ),
                );
              },
              child: const Text(
                'View Leaderboard',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
