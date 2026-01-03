import 'package:audioplayers/audioplayers.dart';

class AudioWarmup {
  static bool _warmed = false;

  static Future<void> warm() async {
    if (_warmed) return;

    final player = AudioPlayer();
    try {
      // Play a zero-volume silent asset to initialize audio pipeline
      await player.setVolume(0.0);
      await player.play(AssetSource('audio/silence.mp3'));
      await player.stop();
    } catch (_) {
      // Fail silently — warmup should never crash gameplay
    } finally {
      await player.dispose();
      _warmed = true;
    }
  }
}
