import 'package:audioplayers/audioplayers.dart';
import 'package:audio_session/audio_session.dart';

class SoundController {
  final AudioPlayer _player = AudioPlayer(playerId: 'sfx');

  SoundController() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;

    // ANDROID-ONLY configuration
    await session.configure(
      AudioSessionConfiguration(
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.sonification,
          usage: AndroidAudioUsage.game,
        ),
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
      ),
    );

    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setPlayerMode(PlayerMode.lowLatency);
    await _player.setVolume(1.0);
  }

  Future<void> playPop() async {
    await _player.play(AssetSource('audio/pop.wav'));
  }

  Future<void> playMiss() async {
    await _player.play(AssetSource('audio/miss.wav'));
  }
}
