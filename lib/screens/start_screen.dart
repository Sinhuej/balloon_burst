import 'dart:async';
import 'package:flutter/material.dart';

import 'package:balloon_burst/audio/audio_warmup.dart';
import 'package:balloon_burst/audio/audio_player.dart';
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
  Timer? _tick;
  bool _showPurchaseFlash = false;

  @override
  void initState() {
    super.initState();

    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _handleStart() async {
    await AudioWarmup.warmUp();
    widget.onStart();
  }

  Future<void> _claimReward() async {
    final reward =
        await widget.engine.claimDailyRewardAndCredit(
      currentWorldLevel: 1,
    );

    if (reward != null) {
      setState(() {});
    }
  }

  Future<void> _purchaseShield() async {
    final success = await widget.engine.purchaseShield();
    if (!mounted) return;

    if (success) {
      setState(() {
        _showPurchaseFlash = true;
      });

      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() {
          _showPurchaseFlash = false;
        });
      });
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

  ButtonStyle _pillStyle({
    required bool enabled,
  }) {
    const bg = Color(0xFFF3F1FF);
    const fg = Color(0xFF5A4FCF);
    const disabledBg = Color(0xFFDCD7F5);
    const disabledFg = Color(0xFF7A74B8);

    return ElevatedButton.styleFrom(
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      backgroundColor: enabled ? bg : disabledBg,
      foregroundColor: enabled ? fg : disabledFg,
      disabledBackgroundColor: disabledBg,
      disabledForegroundColor: disabledFg,
      elevation: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;

    final status = engine.dailyReward.getStatus(
      currentWorldLevel: 1,
    );

    final canAfford =
        engine.wallet.balance >= TJEngine.shieldCost;

    final alreadyActive =
        engine.runLifecycle.isShieldArmedForNextRun;

    final shieldEnabled = canAfford && !alreadyActive;

    String shieldLabel;
    String? helperText;

    if (alreadyActive) {
      shieldLabel = '🛡 Shield Ready';
      helperText = 'Absorbs your first escape';
    } else if (canAfford) {
      shieldLabel =
          '🛡 Add Shield Protection (${TJEngine.shieldCost} Coins)';
      helperText = 'Absorbs your first escape';
    } else {
      shieldLabel =
          '🛡 Shield (${TJEngine.shieldCost} Coins)';
      helperText = 'Need more coins';
    }

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

            const SizedBox(height: 8),

            Text(
              'Coins: ${engine.wallet.balance}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.amber,
              ),
            ),

            const SizedBox(height: 12),

            IconButton(
              onPressed: () async {
                final muted = await engine.toggleMute();
                AudioPlayerService.setMuted(muted);
                if (!mounted) return;
                setState(() {});
              },
              icon: Icon(
                engine.isMuted
                    ? Icons.volume_off
                    : Icons.volume_up,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 28),

            if (status.isAvailable)
              ElevatedButton(
                style: _pillStyle(enabled: true),
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

            const SizedBox(height: 34),

            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: _showPurchaseFlash
                    ? [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.6),
                          blurRadius: 24,
                          spreadRadius: 4,
                        )
                      ]
                    : [],
              ),
              child: ElevatedButton(
                style: _pillStyle(enabled: shieldEnabled),
                onPressed:
                    shieldEnabled ? _purchaseShield : null,
                child: Text(shieldLabel),
              ),
            ),

            if (helperText != null) ...[
              const SizedBox(height: 6),
              Text(
                helperText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],

            const SizedBox(height: 24),

            ElevatedButton(
              style: _pillStyle(enabled: true),
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
                        LeaderboardScreen(engine: engine),
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
