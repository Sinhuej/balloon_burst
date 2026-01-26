import 'run_end_state.dart';

class RunEndMessages {
  static String title(RunEndState state) {
    switch (state.reason) {
      case RunEndReason.miss:
        return 'Slow down, you’ve got this';
      case RunEndReason.escape:
        return 'Too many slipped away';
    }
  }

  static String body(RunEndState state) {
    switch (state.reason) {
      case RunEndReason.miss:
        return 'Accuracy matters more than speed.\nTake a breath and try again.';
      case RunEndReason.escape:
        return 'Keep your eyes up.\nYou can’t save what you don’t see.';
    }
  }

  static String action() {
    return 'Tap to Replay';
  }
}
