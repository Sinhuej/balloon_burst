import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();
  static bool _ready = false;

  static void warmUp() {
    _player.setVolume(0);
    _player.play(AssetSource('silence.mp3')).then((_) {
      _ready = true;
      _player.stop();
      _player.setVolume(1);
    });
  }

  static void ensureReady() {
    if (!_ready) {
      warmUp();
    }
  }

  static void play(String sound) {
    ensureReady();
    _player.play(AssetSource(sound));
  }
}
