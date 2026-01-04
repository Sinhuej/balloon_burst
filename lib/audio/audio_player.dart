import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playPop() async {
    await _player.play(
      AssetSource('audio/pop.mp3'),
      volume: 1.0,
    );
  }
}
