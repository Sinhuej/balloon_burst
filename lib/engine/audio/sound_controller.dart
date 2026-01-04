import 'package:audioplayers/audioplayers.dart';

class SoundController {
  final AudioPlayer _player = AudioPlayer(
    playerId: 'sfx',
  )..setReleaseMode(ReleaseMode.stop);

  SoundController() {
    // REQUIRED on Android for short sound effects
    _player.setPlayerMode(PlayerMode.lowLatency);
  }

  Future<void> playPop() async {
    await _player.play(
      AssetSource('audio/pop.wav'),
      volume: 1.0,
    );
  }

  Future<void> playMiss() async {
    await _player.play(
      AssetSource('audio/miss.wav'),
      volume: 1.0,
    );
  }
}
