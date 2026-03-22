import 'run_end_state.dart';

class RunEndMessages {
  static int _variantIndex(RunEndState state, int count) {
    final seed = state.misses + (state.escapes * 7);
    return count == 0 ? 0 : seed % count;
  }

  static final List<Map<String, String>> _missVariants = [
    {
      'title': 'Slow down, you’ve got this',
      'body': 'Accuracy matters more than speed.\nTake a breath and try again.',
    },
    {
      'title': 'You were close',
      'body': 'The pace was there.\nNow clean up the taps and own the round.',
    },
    {
      'title': 'Pressure got loud',
      'body': 'Settle the rhythm.\nThe next run can be sharper and cleaner.',
    },
  ];

  static final List<Map<String, String>> _escapeVariants = [
    {
      'title': 'Too many slipped away',
      'body': 'Keep your eyes up.\nYou can’t save what you don’t see.',
    },
    {
      'title': 'The sky got away from you',
      'body': 'Track the field sooner.\nGet ahead of the rush next run.',
    },
    {
      'title': 'They broke through',
      'body': 'Read the screen earlier.\nA stronger next run is right there.',
    },
  ];

  static Map<String, String> _variant(RunEndState state) {
    switch (state.reason) {
      case RunEndReason.miss:
        return _missVariants[_variantIndex(state, _missVariants.length)];
      case RunEndReason.escape:
        return _escapeVariants[_variantIndex(state, _escapeVariants.length)];
    }
  }

  static String title(RunEndState state) => _variant(state)['title']!;

  static String body(RunEndState state) => _variant(state)['body']!;

  static String action() {
    return 'Tap to Replay';
  }
}
