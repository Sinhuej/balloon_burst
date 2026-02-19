///This File is edited and built by SlimNation////

import 'package:flutter/material.dart';

import 'package:balloon_burst/audio/audio_warmup.dart';
import 'package:balloon_burst/tj_engine/engine/tj_engine.dart';

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
    _engine = TJEngine();
  }

  Future<void> _handleStart() async {
    await AudioWarmup.warmUp();
    widget.onStart();
  }

  void _claimReward() {
    final reward = _engine.dailyReward.claim(
      currentWorldLevel: 1, // 🔹 temporary until RisingWorlds wiring
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // ==============================
            // 🎁 Daily Reward Section
            // ==============================

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
              ),

            const SizedBox(height: 40),

            // ==============================
            // ▶️ Start Button
            // ==============================

            ElevatedButton(
              onPressed: _handleStart,
              child: const Text('START'),
            ),
          ],
        ),
      ),
    );
  }
}
