import 'package:flutter/material.dart';

// Step 5B: Data-only model imports (unused on purpose)
import 'models/player_profile.dart';
import 'models/player_stats.dart';

void main() {
  runApp(const BalloonBurstApp());
}

class BalloonBurstApp extends StatelessWidget {
  const BalloonBurstApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Step 5B: Models wired but intentionally unused
    final PlayerProfile _unusedProfile = PlayerProfile.empty();
    final PlayerStats _unusedStats = PlayerStats.empty();

    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            'Balloon Burst',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
