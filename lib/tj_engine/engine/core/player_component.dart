import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

class PlayerComponent extends SpriteComponent with CollisionCallbacks {
  Vector2 velocity = Vector2.zero();
  double maxSpeed = 400;

  PlayerComponent({
    super.position,
    super.size,
    super.anchor = Anchor.center,
  }) {
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    if (velocity.length > maxSpeed) {
      velocity = velocity.normalized() * maxSpeed;
    }
  }
}
