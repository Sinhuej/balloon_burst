/// PlayerStats
/// ----------------
/// Pure data-only aggregate.
/// - No UI
/// - No game logic
/// - No engine dependencies
/// - Serializable
/// - Unused (intentional)
///
/// Step 5B: Controlled Re-Attachment (Data-only phase)

class PlayerStats {
  final int balloonsPopped;
  final int levelsCompleted;
  final int totalScore;
  final int totalPlayTimeSeconds;

  const PlayerStats({
    required this.balloonsPopped,
    required this.levelsCompleted,
    required this.totalScore,
    required this.totalPlayTimeSeconds,
  });

  factory PlayerStats.empty() {
    return const PlayerStats(
      balloonsPopped: 0,
      levelsCompleted: 0,
      totalScore: 0,
      totalPlayTimeSeconds: 0,
    );
  }

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      balloonsPopped: json['balloonsPopped'] as int? ?? 0,
      levelsCompleted: json['levelsCompleted'] as int? ?? 0,
      totalScore: json['totalScore'] as int? ?? 0,
      totalPlayTimeSeconds: json['totalPlayTimeSeconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balloonsPopped': balloonsPopped,
      'levelsCompleted': levelsCompleted,
      'totalScore': totalScore,
      'totalPlayTimeSeconds': totalPlayTimeSeconds,
    };
  }

  PlayerStats copyWith({
    int? balloonsPopped,
    int? levelsCompleted,
    int? totalScore,
    int? totalPlayTimeSeconds,
  }) {
    return PlayerStats(
      balloonsPopped: balloonsPopped ?? this.balloonsPopped,
      levelsCompleted: levelsCompleted ?? this.levelsCompleted,
      totalScore: totalScore ?? this.totalScore,
      totalPlayTimeSeconds:
          totalPlayTimeSeconds ?? this.totalPlayTimeSeconds,
    );
  }
}
