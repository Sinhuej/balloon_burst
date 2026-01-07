enum ScreenMode {
  game,
  debug,
  blank,
}

class GameState {
  // Viewport / frame tracking
  double viewportHeight = 0.0;
  int framesSinceStart = 0;

  // Rising Worlds (render-facing)
  int currentWorld = 1;

  // Screen control
  ScreenMode screenMode = ScreenMode.game;

  // Tap feedback
  bool tapPulse = false;
}
