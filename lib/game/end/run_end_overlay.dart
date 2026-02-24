import 'package:flutter/material.dart';
import 'run_end_state.dart';
import 'run_end_messages.dart';

class RunEndOverlay extends StatefulWidget {
  final RunEndState state;
  final VoidCallback onReplay;

  /// Optional: leaderboard placement for this run (1-based).
  /// If placement == 1, we trigger the "NEW #1!" takeover animation.
  final int? placement;

  /// Optional: show a "View Leaderboard" action.
  final VoidCallback? onViewLeaderboard;

  const RunEndOverlay({
    super.key,
    required this.state,
    required this.onReplay,
    this.placement,
    this.onViewLeaderboard,
  });

  @override
  State<RunEndOverlay> createState() => _RunEndOverlayState();
}

class _RunEndOverlayState extends State<RunEndOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _takeover;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  bool get _isNewNumberOne => widget.placement == 1;

  @override
  void initState() {
    super.initState();

    _takeover = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // Scale punch: 1.0 -> 1.06 -> 1.0
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.06).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0).chain(
          CurveTween(curve: Curves.easeInCubic),
        ),
        weight: 55,
      ),
    ]).animate(_takeover);

    // Glow burst: 0.0 -> 1.0 -> 0.0
    _glow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
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
  void didUpdateWidget(covariant RunEndOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    final wasNew = oldWidget.placement == 1;
    final isNew = _isNewNumberOne;

    if (!wasNew && isNew) {
      _takeover.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _takeover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showLeaderboardButton = widget.onViewLeaderboard != null;

    // ✅ Key fix:
    // - Background tap triggers replay.
    // - Content area absorbs taps so replay does NOT fire.
    // - Leaderboard button gets a real, padded hit target.
    return Stack(
      children: [
        // Background dim + replay tap zone
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onReplay,
            child: Container(
              color: Colors.black.withOpacity(0.75),
            ),
          ),
        ),

        // Foreground content (absorbs taps)
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // Absorb taps on the overlay content so they don't fall through to replay.
            },
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
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 360,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isNewNumberOne)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  'NEW #1!',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: Colors.cyanAccent
                                        .withOpacity(0.95),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

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
                            const SizedBox(height: 28),
                            Text(
                              RunEndMessages.action(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white54,
                              ),
                            ),

                            if (showLeaderboardButton) ...[
                              const SizedBox(height: 18),

                              // ✅ Big hit target, never triggers replay
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: widget.onViewLeaderboard,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      'View Leaderboard',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.cyanAccent
                                            .withOpacity(0.9),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
