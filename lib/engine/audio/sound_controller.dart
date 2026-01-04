import 'package:audioplayers/audioplayers.dart';

class SoundController {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playPop() async {
    await _player.play(AssetSource('audio/pop.wav'));
  }

  Future<void> playMiss() async {
    await _player.play(AssetSource('audio/miss.wav'));
  }
}
