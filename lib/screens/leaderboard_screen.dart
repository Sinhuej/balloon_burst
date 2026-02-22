import 'package:flutter/material.dart';
import 'package:balloon_burst/tj_engine/engine/tj_engine.dart';
import 'package:balloon_burst/tj_engine/engine/leaderboard/leaderboard_entry.dart';

class LeaderboardScreen extends StatefulWidget {
  final TJEngine engine;

  const LeaderboardScreen({
    super.key,
    required this.engine,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 2.0, end: 4.0)
        .animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _prestigeBorderColor(int world) {
    switch (world) {
      case 4:
        return const Color(0xFFFFD700);
      case 3:
        return const Color(0xFFFF3DFF);
      case 2:
        return const Color(0xFF00E5FF);
      default:
        return const Color(0xFF1E88E5);
    }
  }

  Color _prestigeBackground(int world) {
    switch (world) {
      case 4:
        return const Color(0xFF2B1F05);
      case 3:
        return const Color(0xFF1B0F2F);
      case 2:
        return const Color(0xFF0E1E2F);
      default:
        return const Color(0xFF13183F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.engine.leaderboard.entries;

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
          : AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    final rank = index + 1;
                    final world = e.worldReached;

                    final borderColor = _prestigeBorderColor(world);
                    final background = _prestigeBackground(world);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: rank == 1 && world >= 2
                              ? borderColor
                              : Colors.transparent,
                          width: rank == 1 && world >= 2
                              ? _pulse.value
                              : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              '#$rank',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: rank == 1
                                    ? borderColor
                                    : Colors.white,
                              ),
                            ),
                          ),
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
                                  'Acc ${(e.accuracy01 * 100).toStringAsFixed(0)}% • '
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
                );
              },
            ),
    );
  }
}
