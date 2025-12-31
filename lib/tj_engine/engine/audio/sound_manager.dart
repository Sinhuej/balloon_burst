import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();
  static bool _warmedUp = false;

  static Future<void> warmUp() async {
    if (_warmedUp) return;

    try {
      // Play a silent sound to initialize the audio pipeline
      await _player.setVolume(0.0);
      await _player.play(AssetSource('audio/silence.mp3'));
      await _player.stop();
      await _player.setVolume(1.0);
    } catch (_) {
      // Fail silently — audio warmup should never crash the game
    }

    _warmedUp = true;
  }

  static Future<void> play(String asset) async {
    await _player.play(AssetSource(asset));
  }
}
