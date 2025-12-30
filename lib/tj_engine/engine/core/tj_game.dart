import 'package:flame/game.dart';

class TJGame extends FlameGame {
  Vector2 viewportSize = Vector2.zero();

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    viewportSize = size.clone();
  }

  void triggerFailure() {
    // existing failure handling
  }
}
