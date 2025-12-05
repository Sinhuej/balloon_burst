import 'package:flame/components.dart';
import 'package:tapjunkie_engine/tapjunkie_engine.dart';

class BalloonComponent extends RectangleComponent
    with HasGameReference<TJGame> {
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

    // Move balloon upward
    position.y -= riseSpeed * dt;

    // If balloon goes off-screen → game over
    if (position.y < -200) {
      removeFromParent();
      gameRef.gameManager.setState(GameState.gameOver);
    }
  }

  void pop() {
    removeFromParent();
    // Add scoring logic here if needed
  }

  bool hitTest(Vector2 point) {
    return toRect().contains(point.toOffset());
  }
}

