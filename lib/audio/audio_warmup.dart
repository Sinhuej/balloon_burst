import 'package:audioplayers/audioplayers.dart';

class AudioWarmup {
  static bool _warmed = false;

  static Future<void> warm() async {
    if (_warmed) return;

    try {
      final player = AudioPlayer();

      // Touch the native audio pipeline WITHOUT playback
      await player.setVolume(0.0);
      await player.setReleaseMode(ReleaseMode.stop);

      await player.dispose();
      _warmed = true;
    } catch (_) {
      // Never crash — warmup is best-effort only
    }
  }
}
