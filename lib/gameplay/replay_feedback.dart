import 'dart:math';

class ReplayFeedback {
  static final Random _rng = Random();

  static const Map<int, List<String>> _messagesByWorld = {
    // World 1 — Learning
    1: [
      'Getting warmed up.',
      'You’ve got the timing.',
      'Nice start.',
      'Almost locked in.',
      'You’re learning fast.',
      'That’s the rhythm.',
      'Good instincts.',
      'Try that again.',
    ],

    // World 2 — Competent
    2: [
      'Now it’s getting serious.',
      'You’re finding the rhythm.',
      'That was solid.',
      'You belong here.',
      'This is your pace.',
      'That felt right.',
      'You’re dialing it in.',
      'Keep it clean.',
    ],

    // World 3 — Skilled (LOCKED)
    3: [
      'You were so close.',
      'That pace is no joke.',
      'You can handle this.',
      'One cleaner run.',
      'Run it back.',
      'Again.',
      'You’re in range.',
      'That run mattered.',
      'Victory’s close.',
      'Show me what you got.',
      'You can top that.',
      'Your comeback starts here.',
    ],

    // World 4 — Elite
    4: [
      'That speed breaks people.',
      'Not many make it here.',
      'You earned that run.',
      'No room for mistakes.',
      'Stay sharp.',
      'This is elite pace.',
      'That was real.',
      'Run it.',
    ],
  };

  /// Returns a replay message for the given world.
  /// Falls back gracefully if world is missing.
  static String forWorld(int world) {
    final list = _messagesByWorld[world] ??
        _messagesByWorld[_messagesByWorld.keys.reduce(max)]!;

    return list[_rng.nextInt(list.length)];
  }
}
