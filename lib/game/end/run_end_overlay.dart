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
  static const int _reviveCost = 50;

  late final AnimationController _shieldPulse;
  late final Animation<double> _shieldScale;
  late final Animation<double> _shieldGlow;

  bool _shieldPurchased = false;

  bool get _canAffordRevive => widget.engine.wallet.balance >= _reviveCost;
  bool get _canAffordShield =>
      widget.engine.wallet.balance >= TJEngine.shieldCost;

  ButtonStyle _pillStyle({
    bool isPrimary = true,
  }) {
    // Match your existing pill look:
    // - white pill
    // - purple-ish text
    // - stays readable even when disabled
    final bg = Colors.white.withOpacity(0.92);
    final fg = const Color(0xFF5B4AA6);

    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      disabledBackgroundColor: bg, // DO NOT dim to gray
      disabledForegroundColor: fg.withOpacity(0.55), // still readable
      minimumSize: const Size(260, 48),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      elevation: 0,
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

    _shieldGlow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.45)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.45, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_shieldPulse);
  }

  @override
  void dispose() {
    _shieldPulse.dispose();
    super.dispose();
  }

  Future<void> _purchaseShield() async {
    if (_shieldPurchased) return;

    final success = await widget.engine.purchaseShield();
    if (!success) return;

    _shieldPulse.forward(from: 0);

    if (!mounted) return;
    setState(() {
      _shieldPurchased = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviveEnabled = widget.onRevive != null && _canAffordRevive;

    final shieldEnabled = !_shieldPurchased && _canAffordShield;
    final shieldLabel = _shieldPurchased
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
          const SizedBox(height: 24),

          if (widget.onRevive != null) ...[
            ElevatedButton(
              style: _pillStyle(),
              onPressed: reviveEnabled ? widget.onRevive : null,
              child: Text('REVIVE ($_reviveCost Coins)'),
            ),
            const SizedBox(height: 12),
          ],

          AnimatedBuilder(
            animation: _shieldPulse,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Tight pulse glow behind the button (temporary)
                  IgnorePointer(
                    child: Container(
                      width: 260,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: _shieldGlow.value > 0
                            ? [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(_shieldGlow.value),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ]
                            : const [],
                      ),
                    ),
                  ),

                  Transform.scale(
                    scale: _shieldScale.value,
                    child: ElevatedButton(
                      style: _pillStyle(),
                      onPressed: shieldEnabled ? _purchaseShield : null,
                      child: Text(shieldLabel),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          ElevatedButton(
            style: _pillStyle(),
            onPressed: widget.onReplay,
            child: const Text('REPLAY'),
          ),

          if (widget.onViewLeaderboard != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.onViewLeaderboard,
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
