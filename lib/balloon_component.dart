import 'package:flame/components.dart';
import 'package:tapjunkie_engine/tapjunkie_engine.dart';
import 'package:tapjunkie_engine/engine/core/states.dart';

class BalloonComponent extends RectangleComponent
    with HasGameRef<TJGame> {
  BalloonComponent({required Vector2 startPosition})
      : super(
          position: startPosition,
          size: Vector2(80, 120),
          anchor: Anchor.center,
        );

  double riseSpeed = 150;

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= riseSpeed * dt;

    if (position.y < -200) {
      removeFromParent();
      gameRef.gameManager.setState(GameState.gameOver);
    }
  }

  void pop() {
    removeFromParent();
  }

  bool hitTest(Vector2 point) {
    return toRect().contains(point.toOffset());
  }
}
