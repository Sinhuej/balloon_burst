///This File is edited and built by SlimNation////

import 'dart:async';
import 'package:flutter/material.dart';

import 'package:balloon_burst/audio/audio_warmup.dart';
import 'package:balloon_burst/tj_engine/engine/tj_engine.dart';
import 'package:balloon_burst/screens/leaderboard_screen.dart';

class StartScreen extends StatefulWidget {
  final VoidCallback onStart;
  final TJEngine engine;

  const StartScreen({
    super.key,
    required this.onStart,
    required this.engine,
  });

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();

    // ✅ Tick UI once per second so countdown visibly updates.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _handleStart() async {
    await AudioWarmup.warmUp();
    widget.onStart();
  }

  void _claimReward() {
    final reward = widget.engine.dailyReward.claim(
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
    final status = widget.engine.dailyReward.getStatus(
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
                    builder: (_) =>
                        LeaderboardScreen(engine: widget.engine),
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
