import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  // Dedicated player for rapid tap feedback (never blocks)
  static final AudioPlayer _popPlayer = AudioPlayer();

  // Dedicated player for rare, important cues (surge)
  static final AudioPlayer _surgePlayer = AudioPlayer();

  /// Play balloon pop sound (instant feedback)
  static Future<void> playPop() async {
    try {
      await _popPlayer.stop();
      await _popPlayer.play(
        AssetSource('audio/pop.mp3'),
        volume: 1.0,
      );
    } catch (_) {
      // Audio failure should never block gameplay
    }
  }

  /// Play world surge anticipation cue (once per surge)
  static Future<void> playSurge() async {
    try {
      await _surgePlayer.stop();
      await _surgePlayer.play(
        AssetSource('audio/surge.mp3'),
        volume: 0.65, // subtle, felt-not-heard
      );
    } catch (_) {
      // Fail silently
    }
  }
}
