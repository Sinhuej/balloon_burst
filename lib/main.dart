import 'package:flutter/material.dart';

// Step 5B: Data-only model import (unused on purpose)
import 'models/player_profile.dart';

void main() {
  runApp(const BalloonBurstApp());
}

class BalloonBurstApp extends StatelessWidget {
  const BalloonBurstApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Step 5B: PlayerProfile wired but intentionally unused
    final PlayerProfile _unusedProfile = PlayerProfile.empty();

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
