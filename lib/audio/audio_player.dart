import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  static final AudioContext _gameAudioContext = AudioContext(
    android: AudioContextAndroid(
      usageType: AndroidUsageType.game,
      contentType: AndroidContentType.sonification,
      audioFocus: AndroidAudioFocus.none, // allow mixing
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
      options: {
        AVAudioSessionOptions.mixWithOthers,
      },
    ),
  );

  // 🔔 World surge cue (single instance, gated)
  static final AudioPlayer _surgePlayer = AudioPlayer()
    ..setAudioContext(_gameAudioContext);

  /// Balloon pop (rapid, overlapping, fire-and-forget)
  static Future<void> playPop() async {
    try {
      final player = AudioPlayer();
      await player.setAudioContext(_gameAudioContext);
      await player.play(
        AssetSource('audio/pop.mp3'),
        volume: 1.0,
      );
    } catch (_) {
      // Never block gameplay on audio
    }
  }

  /// World transition anticipation cue
  static Future<void> playSurge() async {
    try {
      await _surgePlayer.stop(); // ensure only one surge at a time
      await _surgePlayer.play(
        AssetSource('audio/surge.mp3'),
        volume: 1.0,
      );
    } catch (_) {
      // Fail silently
    }
  }
}
