class GameState {
  double viewportHeight = 0;

  // One-frame tap feedback pulse
  bool tapPulse = false;

  // Intro banner timing (frame-based)
  int framesSinceStart = 0;
}
