class LeaderboardEntry {
  final int score;
  final int worldReached;
  final double accuracy01;
  final int bestStreak;
  final DateTime timestamp;

  const LeaderboardEntry({
    required this.score,
    required this.worldReached,
    required this.accuracy01,
    required this.bestStreak,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'worldReached': worldReached,
      'accuracy01': accuracy01,
      'bestStreak': bestStreak,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      score: json['score'] as int,
      worldReached: json['worldReached'] as int,
      accuracy01: (json['accuracy01'] as num).toDouble(),
      bestStreak: json['bestStreak'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
