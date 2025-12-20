/// PlayerProfile
/// ----------------
/// Pure data model.
/// - No UI
/// - No game logic
/// - No engine dependencies
/// - Serializable
/// - Safe to include without usage
///
/// Step 5B: Controlled Re-Attachment (Data-only phase)

class PlayerProfile {
  final String playerId;
  final String displayName;
  final int coins;
  final int highScore;
  final int gamesPlayed;

  const PlayerProfile({
    required this.playerId,
    required this.displayName,
    required this.coins,
    required this.highScore,
    required this.gamesPlayed,
  });

  factory PlayerProfile.empty() {
    return const PlayerProfile(
      playerId: 'guest',
      displayName: 'Guest',
      coins: 0,
      highScore: 0,
      gamesPlayed: 0,
    );
  }

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      playerId: json['playerId'] as String? ?? 'guest',
      displayName: json['displayName'] as String? ?? 'Guest',
      coins: json['coins'] as int? ?? 0,
      highScore: json['highScore'] as int? ?? 0,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'displayName': displayName,
      'coins': coins,
      'highScore': highScore,
      'gamesPlayed': gamesPlayed,
    };
  }

  PlayerProfile copyWith({
    String? playerId,
    String? displayName,
    int? coins,
    int? highScore,
    int? gamesPlayed,
  }) {
    return PlayerProfile(
      playerId: playerId ?? this.playerId,
      displayName: displayName ?? this.displayName,
      coins: coins ?? this.coins,
      highScore: highScore ?? this.highScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
    );
  }
}
