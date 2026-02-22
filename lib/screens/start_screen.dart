///This File is edited and built by SlimNation////

import 'package:flutter/material.dart';

import 'package:balloon_burst/audio/audio_warmup.dart';
import 'package:balloon_burst/tj_engine/engine/tj_engine.dart';
import 'package:balloon_burst/screens/leaderboard_screen.dart';

class StartScreen extends StatefulWidget {
  final VoidCallback onStart;

  const StartScreen({
    super.key,
    required this.onStart,
  });

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late final TJEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = TJEngine(); // temporary engine for reward + leaderboard view
  }

  Future<void> _handleStart() async {
    await AudioWarmup.warmUp();
    widget.onStart();
  }

  void _claimReward() {
    final reward = _engine.dailyReward.claim(
      currentWorldLevel: 1,
    );

    if (reward != null) {
      setState(() {});
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final status = _engine.dailyReward.getStatus(
      currentWorldLevel: 1,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F2F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text(
              'TAPJUNKIE',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 28),

            // 🎁 DAILY REWARD (RESTORED)
            if (status.isAvailable)
              ElevatedButton(
                onPressed: _claimReward,
                child: Text(
                  'Claim Daily Reward\n'
                  '${status.computedReward.coins} Coins '
                  '+ ${status.computedReward.bonusPoints} Bonus',
                  textAlign: TextAlign.center,
                ),
              )
            else
              Text(
                'Daily Reward Available In:\n'
                '${_formatDuration(status.timeRemaining)}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _handleStart,
              child: const Text('START'),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LeaderboardScreen(engine: _engine),
                  ),
                );
              },
              child: const Text(
                'LEADERBOARD',
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
