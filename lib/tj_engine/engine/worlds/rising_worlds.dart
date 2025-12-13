// lib/engine/worlds/rising_worlds.dart

/// Rising Worlds system
///
/// Converts universal momentum into discrete world tiers.
/// Worlds are used to gate difficulty, content, rewards,
/// and cross-game progression across the TJ Universe.
class RisingWorlds {
  final List<double> thresholds;

  RisingWorlds(this.thresholds);

  /// Determine the current world level based on universal momentum.
  ///
  /// Worlds start at level 1.
  int getWorldLevel(double universalMomentum) {
    for (int i = thresholds.length - 1; i >= 0; i--) {
      if (universalMomentum >= thresholds[i]) {
        return i + 1;
      }
    }
    return 1;
  }
}

