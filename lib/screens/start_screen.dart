///This File is edited and built by SlimNation////

import 'package:flutter/material.dart';

import 'package:balloon_burst/audio/audio_warmup.dart';

class StartScreen extends StatelessWidget {
  final VoidCallback onStart;

  const StartScreen({
    super.key,
    required this.onStart,
  });

  Future<void> _handleStart() async {
    // 🔓 TapJunkie Standard: unlock audio on first user gesture
    await AudioWarmup.warmUp();

    // ▶️ Continue normal start flow
    onStart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _handleStart,
          child: const Text('START'),
        ),
      ),
    );
  }
}
