import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  SoundManager._();

  static final AudioPlayer _player = AudioPlayer();

  static bool _ready = false;
  static bool _warming = false;

  /// Warms the audio engine exactly once.
  /// Safe to call repeatedly.
  static Future<void> _warmUp() async {
    if (_ready || _warming) return;

    _warming = true;

    try {
      await _player.setVolume(0.0);

      // Use existing silent asset
      await _player.play(AssetSource('silence.mp3'));

      // Stop immediately — no audible output
      await _player.stop();

      await _player.setVolume(1.0);
    } catch (_) {
      // Never block gameplay on audio
    } finally {
      _ready = true;
      _warming = false;
    }
  }

  /// Ensures audio is ready before playback.
  static Future<void> ensureReady() async {
    if (!_ready) {
      await _warmUp();
    }
  }

  /// Plays a sound safely (no first-tap silence).
  static Future<void> play(String sound) async {
    await ensureReady();
    await _player.play(AssetSource(sound));
  }
}
