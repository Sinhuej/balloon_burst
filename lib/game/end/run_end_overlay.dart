import 'dart:async';

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

  Timer? _flashTimer;

  bool _shieldPurchased = false;
  bool _purchasingShield = false;

  // Short-lived “reward flash” flag (separate from pulse animation)
  bool _showRewardFlash = false;

  bool get _canAffordRevive =>
      widget.engine.wallet.balance >= _reviveCost;

  bool get _canAffordShield =>
      widget.engine.wallet.balance >= TJEngine.shieldCost;

  ButtonStyle _pillStyle({
    required bool enabled,
  }) {
    // Match your other ElevatedButtons: pill shape, comfy padding.
    // Override disabled colors so text remains readable and button doesn’t “disappear”.
    const baseBg = Color(0xFFF3F1FF); // soft light (matches your current UI vibe)
    const baseFg = Color(0xFF5A4FCF); // purple-ish text
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

  Future<void> _purchaseShield() async {
    if (_shieldPurchased || _purchasingShield) return;
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

    // Trigger pulse + reward flash
    _shieldPulse.forward(from: 0);

    setState(() {
      _shieldPurchased = true;
      _showRewardFlash = true;
    });

    // Fade the flash away cleanly after a short burst
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
  Widget build(BuildContext context) {
    final shieldEnabled = !_shieldPurchased && !_purchasingShield && _canAffordShield;

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

          // REVIVE
          if (widget.onRevive != null) ...[
            ElevatedButton(
              style: _pillStyle(enabled: _canAffordRevive),
              onPressed: _canAffordRevive ? widget.onRevive : null,
              child: Text('REVIVE ($_reviveCost Coins)'),
            ),
            const SizedBox(height: 12),
          ],

          // SHIELD (pulse + flash)
          AnimatedBuilder(
            animation: _shieldPulse,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Amber reward flash behind button (bursts, then fades cleanly)
                  IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _showRewardFlash ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      child: Container(
                        width: 320,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.55),
                              blurRadius: 26,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Transform.scale(
                    scale: _shieldPulse.isAnimating ? _shieldScale.value : 1.0,
                    child: ElevatedButton(
                      style: _pillStyle(enabled: shieldEnabled),
                      onPressed: shieldEnabled ? _purchaseShield : null,
                      child: Text(shieldLabel),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          // REPLAY
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
