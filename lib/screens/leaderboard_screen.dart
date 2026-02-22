import 'package:flutter/material.dart';
import 'package:balloon_burst/tj_engine/engine/tj_engine.dart';
import 'package:balloon_burst/tj_engine/engine/leaderboard/leaderboard_entry.dart';

class LeaderboardScreen extends StatelessWidget {
  final TJEngine engine;

  const LeaderboardScreen({
    super.key,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    final entries = engine.leaderboard.entries;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F2F),
        elevation: 0,
        title: const Text(
          'TJ LEADERBOARD',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text(
                'No runs yet.\nBe the first.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                vertical: 24,
                horizontal: 16,
              ),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final LeaderboardEntry e = entries[index];
                final rank = index + 1;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13183F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: rank == 1
                          ? Colors.cyanAccent
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Rank
                      SizedBox(
                        width: 40,
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: rank == 1
                                ? Colors.cyanAccent
                                : Colors.white,
                          ),
                        ),
                      ),

                      // Score + Stats
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${e.score}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'World ${e.worldReached} • '
                              '${(e.accuracy01 * 100).toStringAsFixed(0)}% • '
                              'Streak ${e.bestStreak}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
