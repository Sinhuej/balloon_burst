import 'dart:async';

import 'package:flutter/material.dart';
import 'run_end_state.dart';
import 'run_end_messages.dart';
import 'package:balloon_burst/tj_engine/engine/tj_engine.dart';
import 'package:balloon_burst/tj_engine/engine/run/models/run_reward.dart';
import 'package:balloon_burst/audio/audio_player.dart';

class RunEndOverlay extends StatefulWidget {
  final RunEndState state;
  final VoidCallback onReplay;
  final VoidCallback? onRevive;
  final int? placement;
  final VoidCallback? onViewLeaderboard;
  final TJEngine engine;

  const RunEndOverlay({
    super.key,
    required this.state,
    required this.onReplay,
    this.onRevive,
    this.placement,
    this.onViewLeaderboard,
    required this.engine,
  });

  @override
  State<RunEndOverlay> createState() => _RunEndOverlayState();
}

class _RunEndOverlayState extends State<RunEndOverlay>
    with SingleTickerProviderStateMixin {
  static const int _reviveCost = 50;

  late final AnimationController _shieldPulse;
  late final Animation<double> _shieldScale;

  Timer? _flashTimer;

  bool _purchasingShield = false;
  bool _showRewardFlash = false;

  bool get _canAffordRevive =>
      widget.engine.wallet.balance >= _reviveCost;

  bool get _canAffordShield =>
      widget.engine.wallet.balance >= TJEngine.shieldCost;

  bool get _shieldOwned =>
      widget.engine.runLifecycle.isShieldActive ||
      widget.engine.runLifecycle.isShieldArmedForNextRun;

  ButtonStyle _pillStyle({
    required bool enabled,
  }) {
    const baseBg = Color(0xFFF3F1FF);
    const baseFg = Color(0xFF5A4FCF);
    const disabledBg = Color(0xFFDCD7F5);
    const disabledFg = Color(0xFF7A74B8);

    return ElevatedButton.styleFrom(
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      backgroundColor: enabled ? baseBg : disabledBg,
      foregroundColor: enabled ? baseFg : disabledFg,
      disabledBackgroundColor: disabledBg,
      disabledForegroundColor: disabledFg,
      elevation: 0,
    );
  }

  Widget _buildRewardBreakdown(RunReward reward) {
    Widget row(String label, int value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(
              '+$value',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 20),

        const Text(
          'RUN REWARD',
          style: TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Column(
            children: [
              row('Base', reward.baseCoins),
              row('Pops', reward.popCoins),
              row('World', reward.worldCoins),
              row('Accuracy', reward.accuracyCoins),
              row('Streak', reward.streakCoins),

              const SizedBox(height: 8),

              const Divider(color: Colors.white24),

              const SizedBox(height: 6),

              row('TOTAL', reward.totalCoins),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _purchaseShield() async {
    if (_purchasingShield) return;
    if (_shieldOwned) return;
    if (!_canAffordShield) return;

    setState(() {
      _purchasingShield = true;
    });

    final success = await widget.engine.purchaseShield();

    if (!mounted) return;

    setState(() {
      _purchasingShield = false;
    });

    if (!success) return;

    _shieldPulse.forward(from: 0);

    setState(() {
      _showRewardFlash = true;
    });

    _flashTimer?.cancel();
    _flashTimer = Timer(
      const Duration(milliseconds: 380),
      () {
        if (!mounted) return;
        setState(() {
          _showRewardFlash = false;
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _shieldPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _shieldScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.10)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.10, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_shieldPulse);
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _shieldPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.engine.lastRunReward;

    final shieldEnabled =
        !_shieldOwned && !_purchasingShield && _canAffordShield;

    final shieldLabel = _shieldOwned
        ? '🛡 Shield Armed'
        : '🛡 Start Next Run With Shield (${TJEngine.shieldCost})';

    return Container(
      color: Colors.black.withOpacity(0.75),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Text(
            RunEndMessages.title(widget.state),
            style: const TextStyle(
              fontSize: 26,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            RunEndMessages.body(widget.state),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),

          if (reward != null)
            _buildRewardBreakdown(reward),

          if (widget.onRevive != null) ...[
            ElevatedButton(
              style: _pillStyle(enabled: _canAffordRevive),
              onPressed: _canAffordRevive ? widget.onRevive : null,
              child: const Text('REVIVE (50 Coins)'),
            ),
            const SizedBox(height: 12),
          ],

          ElevatedButton(
            style: _pillStyle(enabled: shieldEnabled),
            onPressed: shieldEnabled ? _purchaseShield : null,
            child: Text(shieldLabel),
          ),

          const SizedBox(height: 12),

          ElevatedButton(
            style: _pillStyle(enabled: true),
            onPressed: widget.onReplay,
            child: const Text('REPLAY'),
          ),

          if (widget.onViewLeaderboard != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.onViewLeaderboard,
              child: const Text(
                'VIEW LEADERBOARD',
                style: TextStyle(color: Colors.cyanAccent),
              ),
            ),
          ],

          const SizedBox(height: 16),

          IconButton(
            icon: Icon(
              widget.engine.isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white70,
            ),
            onPressed: () async {
              final muted = await widget.engine.toggleMute();
              AudioPlayerService.setMuted(muted);
              if (!mounted) return;
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
