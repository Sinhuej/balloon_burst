import 'package:flutter/material.dart';
import 'run_end_state.dart';
import 'run_end_messages.dart';
import 'package:balloon_burst/tj_engine/engine/tj_engine.dart';
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

  late final AnimationController _takeover;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  static const int _reviveCost = 50;

  bool get _isNewNumberOne => widget.placement == 1;

  bool get _canAffordRevive =>
      widget.engine.wallet.balance >= _reviveCost;

  bool get _canAffordShield =>
      widget.engine.wallet.balance >= TJEngine.shieldCost;

  bool get _shieldAlreadyArmed =>
      widget.engine.runLifecycle.isShieldActive;

  @override
  void initState() {
    super.initState();

    _takeover = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 55,
      ),
    ]).animate(_takeover);

    _glow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_takeover);

    if (_isNewNumberOne) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _takeover.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _takeover.dispose();
    super.dispose();
  }

  Future<void> _purchaseShield() async {
    final success = await widget.engine.purchaseShield();
    if (!success) return;

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.75),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _takeover,
        builder: (context, child) {

          final glowOpacity =
              _isNewNumberOne ? (_glow.value * 0.25) : 0.0;

          return Stack(
            alignment: Alignment.center,
            children: [

              if (_isNewNumberOne)
                IgnorePointer(
                  child: Container(
                    width: 340,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent
                              .withOpacity(glowOpacity),
                          blurRadius: 40,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),

              Transform.scale(
                scale: _isNewNumberOne ? _scale.value : 1.0,
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

                    const SizedBox(height: 24),

                    // REVIVE
                    if (widget.onRevive != null) ...[
                      ElevatedButton(
                        onPressed: _canAffordRevive
                            ? widget.onRevive
                            : null,
                        child: Text(
                          'REVIVE ($_reviveCost Coins)',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // SHIELD PURCHASE
                    ElevatedButton(
                      onPressed: (!_shieldAlreadyArmed && _canAffordShield)
                          ? _purchaseShield
                          : null,
                      child: Text(
                        _shieldAlreadyArmed
                            ? '🛡 Shield Armed'
                            : '🛡 Start Next Run With Shield (${TJEngine.shieldCost})',
                      ),
                    ),

                    const SizedBox(height: 12),

                    // REPLAY
                    ElevatedButton(
                      onPressed: widget.onReplay,
                      child: const Text('REPLAY'),
                    ),

                    if (widget.onViewLeaderboard != null) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed:
                            widget.onViewLeaderboard,
                        child: const Text(
                          'VIEW LEADERBOARD',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                          ),
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
                        final muted =
                            await widget.engine.toggleMute();
                        AudioPlayerService.setMuted(muted);
                        if (!mounted) return;
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
