import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  static bool _muted = false;

  static void setMuted(bool value) {
    _muted = value;
  }

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
      _coinIndex = (_coinIndex + 1) % _coinPoolSize;

      await player.play(
        AssetSource('audio/coin.wav'),
        volume: 0.9,
      );
    } catch (_) {}
  }

  static void playCoinRamp(int amount) {
    final steps = (amount / 20).clamp(3, 6).round();

    for (int i = 0; i < steps; i++) {
      Future.delayed(Duration(milliseconds: 80 * i), () {
        playCoin();
      });
    }
  }

  static final List<AudioPlayer> _popPlayers = List.generate(
    _popPoolSize,
    (_) => AudioPlayer()..setAudioContext(_gameAudioContext),
  );

  static int _popIndex = 0;

  static final AudioPlayer _surgePlayer = AudioPlayer()
    ..setAudioContext(_gameAudioContext);

  static final AudioPlayer _milestonePlayer = AudioPlayer()
    ..setAudioContext(_gameAudioContext);

  static final AudioPlayer _shieldPlayer = AudioPlayer()
    ..setAudioContext(_gameAudioContext);

  static Future<void> playPop() async {
    if (_muted) return;

    try {
      final player = _popPlayers[_popIndex];
      _popIndex = (_popIndex + 1) % _popPoolSize;

      final pops = [
        'audio/pop_low.wav',
        'audio/pop_mid.wav',
        'audio/pop_high.wav',
      ];

      final asset = pops[Random().nextInt(pops.length)];
      final volume = 0.9 + Random().nextDouble() * 0.2;

      await player.play(
        AssetSource(asset),
        volume: volume,
      );
    } catch (_) {
      // never block gameplay
    }
  }

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
