/// SessionSummary
/// ----------------
/// Pure data-only session snapshot.
/// - No UI
/// - No game logic
/// - No engine dependencies
/// - Serializable
/// - Unused (intentional)
///
/// Step 5B: Controlled Re-Attachment (Data-only phase)

class SessionSummary {
  final int balloonsPopped;
  final int scoreEarned;
  final int durationSeconds;
  final bool completed;

  const SessionSummary({
    required this.balloonsPopped,
    required this.scoreEarned,
    required this.durationSeconds,
    required this.completed,
  });

  /// Empty baseline session
  factory SessionSummary.empty() {
    return const SessionSummary(
      balloonsPopped: 0,
      scoreEarned: 0,
      durationSeconds: 0,
      completed: false,
    );
  }

  /// Deserialize from JSON
  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      balloonsPopped: json['balloonsPopped'] as int? ?? 0,
      scoreEarned: json['scoreEarned'] as int? ?? 0,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
    );
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'balloonsPopped': balloonsPopped,
      'scoreEarned': scoreEarned,
      'durationSeconds': durationSeconds,
      'completed': completed,
    };
  }

  /// Copy helper (still data-only)
  SessionSummary copyWith({
    int? balloonsPopped,
    int? scoreEarned,
    int? durationSeconds,
    bool? completed,
  }) {
    return SessionSummary(
      balloonsPopped: balloonsPopped ?? this.balloonsPopped,
      scoreEarned: scoreEarned ?? this.scoreEarned,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      completed: completed ?? this.completed,
    );
  }
}
