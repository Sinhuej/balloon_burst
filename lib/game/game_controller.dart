import '../gameplay/gameplay_world.dart';
import '../gameplay/balloon.dart';

class GameController {
  GameplayWorld? gameplayWorld;

  void start() {
    final List<Balloon> balloons = List.generate(
      5,
      (i) => Balloon(
        id: 'balloon_$i',
      ),
    );

    gameplayWorld = GameplayWorld(
      balloons: balloons,
    );
  }
}
