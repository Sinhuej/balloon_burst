import 'package:audioplayers/audioplayers.dart';

/// TapJunkie Standard
/// -----------------
/// AudioWarmup preloads audio on first user interaction
/// to prevent first-tap latency on Android.
class AudioWarmup {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> warmUp() async {
    try {
      // Play silently once to unlock audio pipeline
      await _player.play(
        AssetSource('audio/pop.mp3'),
        volume: 0.0,
      );

      // Stop immediately
      await _player.stop();
    } catch (_) {
      // Fail silently — warmup should NEVER block start
    }
  }
}
