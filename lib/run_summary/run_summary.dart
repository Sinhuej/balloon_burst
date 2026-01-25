class RunSummary {
  final String reason;
  final int world;
  final int pops;
  final int escapes;
  final int missStreak;
  final double accuracy;

  const RunSummary({
    required this.reason,
    required this.world,
    required this.pops,
    required this.escapes,
    required this.missStreak,
    required this.accuracy,
  });

  @override
  String toString() {
    return 'RunSummary('
        'reason=$reason, '
        'world=$world, '
        'pops=$pops, '
        'escapes=$escapes, '
        'missStreak=$missStreak, '
        'accuracy=${accuracy.toStringAsFixed(2)}'
        ')';
  }
}
