enum DebugEventType {
  hit,
  miss,
}

class GameState {
  double viewportHeight = 0.0;
  bool tapPulse = false;

  // ---- RUN END STATE ----
  bool isGameOver = false;
  String? endReason;

  void log(String message) {
    // ignore: avoid_print
    print(message);
  }

  void resetRun() {
    isGameOver = false;
    endReason = null;
  }
}
