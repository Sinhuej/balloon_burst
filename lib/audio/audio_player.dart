import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  static final AudioContext _gameAudioContext = AudioContext(
    android: AudioContextAndroid(
      usageType: AndroidUsageType.game,
      contentType: AndroidContentType.sonification,
      audioFocus: AndroidAudioFocus.none, // 🔑 allow mixing
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
      options: {
        AVAudioSessionOptions.mixWithOthers,
      },
    ),
  );

  // Rapid tap feedback (can overlap)
  static final AudioPlayer _popPlayer = AudioPlayer()
    ..setAudioContext(_gameAudioContext);

  // Important anticipation cue (must not interrupt taps)
  static final AudioPlayer _surgePlayer = AudioPlayer()
    ..setAudioContext(_gameAudioContext);

  /// Play balloon pop sound (instant feedback)
  static Future<void> playPop() async {
    try {
      // ❌ Do NOT stop — allow overlap for rapid taps
      await _popPlayer.play(
        AssetSource('audio/pop.mp3'),
        volume: 1.0,
      );
    } catch (_) {
      // Never block gameplay on audio
    }
  }

  /// Play world surge anticipation cue
  static Future<void> playSurge() async {
    try {
      await _surgePlayer.stop(); // ensure single surge instance
      await _surgePlayer.play(
        AssetSource('audio/surge.mp3'),
        volume: 1.0, // 🔊 full volume (file is subtle by design)
      );
    } catch (_) {
      // Fail silently
    }
  }
}
