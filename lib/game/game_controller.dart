import '../gameplay/gameplay_world.dart';
import '../gameplay/balloon.dart';

class GameController {
  GameplayWorld? gameplayWorld;

  void start() {
    // Force-create balloons for verification
    final balloons = List.generate(
      5,
      (i) => Balloon(
        id: 'balloon_$i',
        type: BalloonType.normal,
      ),
    );

    gameplayWorld = GameplayWorld(
      balloons: balloons,
    );
  }
}
