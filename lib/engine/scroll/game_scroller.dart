/// TapJunkie CORE SYSTEM
/// ---------------------
/// GameScroller maintains a continuously advancing scroll position.
/// What "scroll" means is defined by the game (background, entities, camera).
class GameScroller {
  /// Current scroll position (units).
  double scrollY = 0.0;

  /// Advance the scroll position.
  /// `speed` is units per second.
  void update(double dt, double speed) {
    if (dt <= 0) return;
    scrollY += speed * dt;
  }

  /// Reset scroll position for a new run.
  void reset() {
    scrollY = 0.0;
  }
}
