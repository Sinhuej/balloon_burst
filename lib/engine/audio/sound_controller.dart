import 'package:audioplayers/audioplayers.dart';
import 'package:audio_session/audio_session.dart';

class SoundController {
  final AudioPlayer _player = AudioPlayer(
    playerId: 'sfx',
  )..setReleaseMode(ReleaseMode.stop);

  SoundController() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.ambient,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.sonification,
          usage: AndroidAudioUsage.game,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      ),
    );

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
