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

  int _visibleRewardRows = 0;
  int _currentRewardTotal = -1;

  late final AnimationController _shieldPulse;
  late final Animation<double> _shieldScale;

  late final AnimationController _rankController;
  late final Animation<double> _rankScale;

  late final AnimationController _coinController;
  late Animation<int> _coinCounter;

  late final AnimationController _statsController;
  late final Animation<double> _statsSlide;

  late final AnimationController _titleController;
  late final Animation<double> _titleFade;

  late final AnimationController _buttonsController;
  late final Animation<double> _buttonsFade;

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
      elevation: enabled ? 6 : 0,
      shadowColor: const Color(0xAA5A4FCF),
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
      return '🏆 TAPJUNKIE';
    case 'A':
      return '🥇 TAP PRO';
    case 'B':
      return '🥈 TAP SKILLED';
    default:
      return '🥉 TAP ROOKIE';
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

  int _totalForReward(RunReward reward) {
    return reward.baseCoins +
        reward.popCoins +
        reward.worldCoins +
        reward.accuracyCoins +
        reward.streakCoins;
  }

  void _maybeStartRewardAnimation(RunReward reward) {
    final total = _totalForReward(reward);
    if (_currentRewardTotal == total) return;
    AudioPlayerService.playCoinRamp(total);

    _currentRewardTotal = total;
    _rewardSparkle = false;

    _coinController.stop();
    _coinController.reset();

    _coinCounter = IntTween(
      begin: 0,
      end: total,
    ).animate(
      CurvedAnimation(
        parent: _coinController,
        curve: Curves.easeOutExpo,
      ),
    );

    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      if (_currentRewardTotal != total) return;
      _coinController.forward(from: 0);
    });
  }

  Widget _buildStatsHeader() {
    final snapshot = widget.engine.runLifecycle.getSnapshot();
    final accuracy = snapshot.accuracy01;
    final rank = _accuracyRank(accuracy);

    return Column(
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
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
          'Rank tiers: 🏆 TapJunkie • 🥇 Tap Pro • 🥈 Tap Skilled • 🥉 Tap Rookie',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
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
              if (_visibleRewardRows >= 1) row('Base', reward.baseCoins),
              if (_visibleRewardRows >= 2) row('Pops', reward.popCoins),
              if (_visibleRewardRows >= 3) row('World', reward.worldCoins),
              if (_visibleRewardRows >= 4) row('Accuracy', reward.accuracyCoins),
              if (_visibleRewardRows >= 5) row('Streak', reward.streakCoins),
              const SizedBox(height: 8),
              const Divider(color: Colors.white24),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.18),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: AnimatedBuilder(
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
                                  Icons.auto_awesome_rounded,
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
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'BANK',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${widget.engine.wallet.balance}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
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

    _rankController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _rankScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.7, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_rankController);

    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _coinCounter = IntTween(
      begin: 0,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _coinController,
        curve: Curves.easeOutExpo,
      ),
    );

    _coinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _rewardSparkle = true);

        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          setState(() => _rewardSparkle = false);
        });
      }
    });

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _titleFade = CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOut,
    );

    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _statsSlide = Tween<double>(
      begin: 20,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _statsController,
        curve: Curves.easeOut,
      ),
    );

    _buttonsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _buttonsFade = CurvedAnimation(
      parent: _buttonsController,
      curve: Curves.easeOut,
    );

    for (int i = 1; i <= 5; i++) {
      Future.delayed(Duration(milliseconds: 250 * i), () {
        if (!mounted) return;
        setState(() => _visibleRewardRows = i);
      });
    }

    Future.delayed(Duration.zero, () {
      if (mounted) _titleController.forward();
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _statsController.forward();
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _rankController.forward();
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _buttonsController.forward();
    });

    final reward = widget.engine.lastRunReward;
    if (reward != null) {
      _maybeStartRewardAnimation(reward);
    }
  }

  @override
  void didUpdateWidget(RunEndOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    final reward = widget.engine.lastRunReward;
    if (reward != null) {
      _maybeStartRewardAnimation(reward);
    }
  }

  @override
  void dispose() {
    _shieldPulse.dispose();
    _rankController.dispose();
    _coinController.dispose();
    _titleController.dispose();
    _statsController.dispose();
    _buttonsController.dispose();
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

    if (reward != null) {
      _maybeStartRewardAnimation(reward);
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Color(0xFF0D1B2A),
            Color(0xFF000000),
          ],
          radius: 1.2,
        ),
      ),
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
              textAlign: TextAlign.center,
            ),
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
          if (reward != null) ...[
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _statsController,
              builder: (_, child) {
                return Transform.translate(
                  offset: Offset(0, _statsSlide.value),
                  child: Opacity(
                    opacity: _statsController.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  _buildStatsHeader(),
                  _buildRewardBreakdown(reward),
                ],
              ),
            ),
          ],
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
                ScaleTransition(
                  scale: _shieldScale,
                  child: ElevatedButton(
                    style: _pillStyle(enabled: shieldEnabled),
                    onPressed: shieldEnabled ? _purchaseShield : null,
                    child: Text(shieldLabel),
                  ),
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
                    widget.engine.isMuted
                        ? Icons.volume_off
                        : Icons.volume_up,
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
          ),
        ],
      ),
    );
  }
}
