import 'package:flutter/material.dart';
import 'package:balloon_burst/audio/audio_warmup.dart';
import 'package:balloon_burst/tj_engine/engine/tj_engine.dart';
import 'leaderboard_screen.dart';

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

  @override
  Widget build(BuildContext context) {
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
                        LeaderboardScreen(engine: _engine),
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
