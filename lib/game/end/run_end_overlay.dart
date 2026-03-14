import 'dart:async';

import 'package:flutter/material.dart';
import 'package:balloon_burst/audio/audio_player.dart';
import 'package:balloon_burst/tj_engine/engine/tj_engine.dart';
import 'package:balloon_burst/tj_engine/engine/run/models/run_reward.dart';

import 'run_end_messages.dart';
import 'run_end_state.dart';

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

  late final AnimationController _cinematic;

  late final Animation<double> _titleFade;
  late final Animation<double> _statsSlide;
  late final Animation<double> _rankScale;
  late final Animation<double> _buttonsFade;

  late final AnimationController _coinController;
  late Animation<int> _coinCounter;

  bool _rewardSparkle = false;
  bool _purchasingShield = false;

  bool get _canAffordRevive =>
      widget.engine.wallet.balance >= _reviveCost;

  bool get _canAffordShield =>
      widget.engine.wallet.balance >= TJEngine.shieldCost;

  bool get _shieldOwned =>
      widget.engine.runLifecycle.isShieldActive ||
      widget.engine.runLifecycle.isShieldArmedForNextRun;

  ButtonStyle _pillStyle({required bool enabled}) {
    return ElevatedButton.styleFrom(
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      backgroundColor: enabled ? const Color(0xFFF3F1FF) : const Color(0xFFDCD7F5),
      foregroundColor: enabled ? const Color(0xFF5A4FCF) : const Color(0xFF7A74B8),
      elevation: enabled ? 3 : 0,
      shadowColor: const Color(0x665A4FCF),
    );
  }

  String _accuracyRank(double accuracy) {
    if (accuracy >= 0.95) return 'S';
    if (accuracy >= 0.90) return 'A';
    if (accuracy >= 0.80) return 'B';
    return 'C';
  }

  String _rankLabel(String rank) {
    switch (rank) {
      case 'S':
        return '🏆 ELITE PLAYER';
      case 'A':
        return '🥇 PRO PLAYER';
      case 'B':
        return '🥈 SKILLED PLAYER';
      default:
        return '🥉 ROOKIE';
    }
  }

  Color _rankColor(String rank) {
    switch (rank) {
      case 'S':
        return Colors.amber;
      case 'A':
        return Colors.cyanAccent;
      case 'B':
        return const Color(0xFFB0C4DE);
      default:
        return Colors.white70;
    }
  }

  @override
  void initState() {
    super.initState();

    _cinematic = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _titleFade = CurvedAnimation(
      parent: _cinematic,
      curve: const Interval(0.0, 0.15, curve: Curves.easeOut),
    );

    _statsSlide = CurvedAnimation(
      parent: _cinematic,
      curve: const Interval(0.15, 0.35, curve: Curves.easeOut),
    );

    _rankScale = CurvedAnimation(
      parent: _cinematic,
      curve: const Interval(0.35, 0.55, curve: Curves.elasticOut),
    );

    _buttonsFade = CurvedAnimation(
      parent: _cinematic,
      curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
    );

    final reward = widget.engine.lastRunReward;

    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _coinCounter = IntTween(
      begin: 0,
      end: reward?.totalCoins ?? 0,
    ).animate(
      CurvedAnimation(
        parent: _coinController,
        curve: Curves.easeOutCubic,
      ),
    );

    _cinematic.forward();

    Future.delayed(const Duration(milliseconds: 450), () {
      if (reward != null) {
        _coinController.forward();

        _coinController.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            setState(() => _rewardSparkle = true);

            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() => _rewardSparkle = false);
              }
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _cinematic.dispose();
    _coinController.dispose();
    super.dispose();
  }

  Widget _buildStats() {
    final snapshot = widget.engine.runLifecycle.getSnapshot();
    final accuracy = snapshot.accuracy01;
    final rank = _accuracyRank(accuracy);

    return Transform.translate(
      offset: Offset(0, 40 * (1 - _statsSlide.value)),
      child: Opacity(
        opacity: _statsSlide.value,
        child: Column(
          children: [
            const Text(
              'RUN STATS',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Accuracy ${(accuracy * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            ScaleTransition(
              scale: _rankScale,
              child: Text(
                _rankLabel(rank),
                style: TextStyle(
                  color: _rankColor(rank),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Best Streak ×${snapshot.bestStreak}',
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Rank tiers: 🏆 Elite • 🥇 Pro • 🥈 Skilled • 🥉 Rookie',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReward(RunReward reward) {
    Widget row(String label, int value) {
      return Row(
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
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Column(
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
          row('Base', reward.baseCoins),
          row('Pops', reward.popCoins),
          row('World', reward.worldCoins),
          row('Accuracy', reward.accuracyCoins),
          row('Streak', reward.streakCoins),
          const Divider(color: Colors.white24),
          AnimatedBuilder(
            animation: _coinCounter,
            builder: (context, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL EARNED',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      if (_rewardSparkle)
                        const Positioned(
                          right: 40,
                          child: Icon(
                            Icons.auto_awesome,
                            color: Colors.amber,
                            size: 18,
                          ),
                        ),
                      Text(
                        '+${_coinCounter.value}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BANK',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              Text(
                '${widget.engine.wallet.balance}',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

          FadeTransition(
            opacity: _titleFade,
            child: Text(
              RunEndMessages.title(widget.state),
              style: const TextStyle(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          FadeTransition(
            opacity: _titleFade,
            child: Text(
              RunEndMessages.body(widget.state),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          if (reward != null) ...[
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _cinematic,
              builder: (_, __) => _buildStats(),
            ),
            _buildReward(reward),
          ],

          const SizedBox(height: 20),

          FadeTransition(
            opacity: _buttonsFade,
            child: Column(
              children: [

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
                  onPressed: shieldEnabled ? () {} : null,
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
              ],
            ),
          ),

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
