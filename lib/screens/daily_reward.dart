import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
class DailyRewardScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final PlayerProfile profile;

  const DailyRewardScreen({
    super.key,
    required this.prefs,
    required this.profile,
  });

  @override
  State<DailyRewardScreen> createState() => _DailyRewardScreenState();
}

class _DailyRewardScreenState extends State<DailyRewardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _chestController;
  Timer? _timer;

  bool _canClaim = false;
  Duration _timeRemaining = Duration.zero;
  int _previewReward = 0;
  bool _claimedThisVisit = false;
  bool _showCoinBurst = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chestController.dispose();
    super.dispose();
  }

  void _tick() {
    if (!_canClaim) {
      _evaluateState();
    }
  }

  void _evaluateState() {
    final now = DateTime.now();
    final last = widget.profile.lastDailyClaimDate;

    if (last == null) {
      setState(() {
        _canClaim = true;
        _timeRemaining = Duration.zero;
        _previewReward = _calculateRewardPreview(1);
      });
      return;
    }

    final diff = now.difference(last);
    if (diff >= const Duration(hours: 24)) {
      final nextStreak =
          _nextStreakValue(now, last, widget.profile.dailyStreak);
      setState(() {
        _canClaim = true;
        _timeRemaining = Duration.zero;
        _previewReward = _calculateRewardPreview(nextStreak);
      });
    } else {
      final remaining = const Duration(hours: 24) - diff;
      setState(() {
        _canClaim = false;
        _timeRemaining = remaining.isNegative ? Duration.zero : remaining;
        _previewReward = _calculateRewardPreview(
            widget.profile.dailyStreak == 0 ? 1 : widget.profile.dailyStreak);
      });
    }
  }

  int _nextStreakValue(DateTime now, DateTime last, int currentStreak) {
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(last.year, last.month, last.day);
    final dayDiff = today.difference(lastDay).inDays;

    if (dayDiff == 1) {
      return currentStreak + 1;
    } else if (dayDiff > 1) {
      return 1;
    } else {
      return currentStreak == 0 ? 1 : currentStreak;
    }
  }

  int _calculateRewardPreview(int streakValue) {
    int base = 50;
    int streakBonus = max(0, streakValue - 1) * 10;
    int reward = base + streakBonus;
    if (streakValue % 7 == 0) {
      reward += 100;
    }
    return reward;
  }

  Future<void> _claimReward() async {
    if (!_canClaim) return;

    final now = DateTime.now();
    final last = widget.profile.lastDailyClaimDate;
    final currentStreak = widget.profile.dailyStreak;

    final nextStreak = last == null
        ? 1
        : _nextStreakValue(now, last, currentStreak);

    final rewardCoins = _calculateRewardPreview(nextStreak);

    widget.profile.dailyStreak = nextStreak;
    widget.profile.lastDailyClaimDate = now;
    widget.profile.totalCoins += rewardCoins;

    await widget.profile.save(widget.prefs);

    setState(() {
      _canClaim = false;
      _claimedThisVisit = true;
      _showCoinBurst = true;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _showCoinBurst = false;
      });
    });

    _evaluateState();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(h)}:${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_claimedThisVisit);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daily Reward'),
          backgroundColor: const Color(0xFF050817),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(_claimedThisVisit);
            },
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TapJunkie Treasure Chest',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _canClaim
                        ? 'Your daily reward is ready!'
                        : 'Come back after the countdown to claim again.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // (rest of widget continues unchanged)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
