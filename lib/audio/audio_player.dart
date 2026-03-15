import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

class AudioPlayerService {
  static bool _muted = false;

  /// Injected at runtime by UI/engine load.
  static void setMuted(bool value) {
    _muted = value;
  }

  /// Shared game audio context
  static final AudioContext _gameAudioContext = AudioContext(
    android: AudioContextAndroid(
      usageType: AndroidUsageType.game,
      contentType: AndroidContentType.sonification,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
      options: {
        AVAudioSessionOptions.mixWithOthers,
      },
    ),
  );

  static const int _popPoolSize = 8;
  static const int _coinPoolSize = 4;

  static final List<AudioPlayer> _coinPlayers = List.generate(
    _coinPoolSize,
    (_) => AudioPlayer()..setAudioContext(_gameAudioContext),
  );

  static int _coinIndex = 0;

  static Future<void> playCoin() async {
    if (_muted) return;

    try {
      final player = _coinPlayers[_coinIndex];

      _coinIndex++;
      if (_coinIndex >= _coinPoolSize) {
        _coinIndex = 0;
      }

      await player.stop();

      await player.play(
        AssetSource('audio/coin.wav'),
        volume: 0.9,
      );
    } catch (_) {}
  }

  static void playCoinRamp(int amount) {
    final steps = (amount / 20).clamp(3, 6).round();

    for (int i = 0; i < steps; i++) {
      Future.delayed(const Duration(milliseconds: 80) * i, () {
        playCoin();
      });
    }
  }

  static final List<AudioPlayer> _popPlayers = List.generate(
    _popPoolSize,
    (_) => AudioPlayer()..setAudioContext(_gameAudioContext),
  );

  static int _popIndex = 0;

  // 🔔 World surge cue
  static final AudioPlayer _surgePlayer = AudioPlayer()
    ..setAudioContext(_gameAudioContext);

  // 🏁 Milestone cue
  static final AudioPlayer _milestonePlayer = AudioPlayer()
    ..setAudioContext(_gameAudioContext);

  // 🛡 Shield break cue
  static final AudioPlayer _shieldPlayer = AudioPlayer()
    ..setAudioContext(_gameAudioContext);

  /// Balloon pop (rapid overlapping instances)
  static Future<void> playPop() async {
  if (_muted) return;

  try {
    final player = _popPlayers[_popIndex];

    _popIndex++;
    if (_popIndex >= _popPoolSize) {
      _popIndex = 0;
    }

    final pops = [
      'audio/pop_low.wav',
      'audio/pop_mid.wav',
      'audio/pop_high.wav',
    ];

    final asset = pops[Random().nextInt(pops.length)];

    final volume = 0.9 + Random().nextDouble() * 0.2;

    await player.stop();

    await Future.delayed(const Duration(milliseconds: 8));

    await player.play(
      AssetSource(asset),
      volume: volume,
    );

  } catch (_) {
    // never block gameplay
  }
}

  /// World transition anticipation cue
  static Future<void> playSurge() async {
    if (_muted) return;

    try {
      await _surgePlayer.stop();
      await _surgePlayer.play(
        AssetSource('audio/surge.wav'),
        volume: 1.0,
      );
    } catch (_) {}
  }

  /// Streak milestone cues (10 / 20 / 30)
  static Future<void> playStreakMilestone(int milestoneIndex) async {
    if (_muted) return;

    String asset;
    switch (milestoneIndex) {
      case 1:
        asset = 'audio/milestone_10.mp3';
        break;
      case 2:
        asset = 'audio/milestone_20.mp3';
        break;
      case 3:
        asset = 'audio/milestone_30.mp3';
        break;
      default:
        return;
    }

    try {
      await _milestonePlayer.stop();
      await _milestonePlayer.play(
        AssetSource(asset),
        volume: 1.0,
      );
    } catch (_) {}
  }

  /// Shield break sound
  static Future<void> playShieldBreak() async {
    if (_muted) return;

    try {
      await _shieldPlayer.stop();
      await _shieldPlayer.play(
        AssetSource('audio/milestone_30.mp3'),
        volume: 0.9,
      );
    } catch (_) {}
  }
}
