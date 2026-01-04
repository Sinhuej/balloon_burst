import 'package:audioplayers/audioplayers.dart';

class AudioWarmup {
  static final AudioPlayer _warmupPlayer = AudioPlayer();

  static Future<void> warm() async {
    try {
      await _warmupPlayer.play(
        AssetSource('audio/pop.mp3'),
        volume: 0.0,
      );
      await _warmupPlayer.stop();
    } catch (_) {
      // warm-up should never crash the game
    }
  }
}
