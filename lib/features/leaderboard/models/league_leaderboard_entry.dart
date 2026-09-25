class LeagueModeBreakdown {
  final String mode;
  final int bestValue;
  final double normalized;
  final int playedCount;
  final bool inTopK;

  LeagueModeBreakdown({
    required this.mode,
    required this.bestValue,
    required this.normalized,
    required this.playedCount,
    required this.inTopK,
  });

  factory LeagueModeBreakdown.fromJson(Map<String, dynamic> json) {
    return LeagueModeBreakdown(
      mode: json['mode'] ?? '',
      bestValue: json['best_value'] ?? 0,
      normalized: (json['normalized'] as num?)?.toDouble() ?? 0.0,
      playedCount: json['played_count'] ?? 0,
      inTopK: json['in_top_k'] ?? false,
    );
  }
}

class LeagueLeaderboardEntry {
  final int rank;
  final int userId;
  final int playerId;
  final String username;
  final String? avatarId;
  final String? avatarUrl;
  final double finalScore;
  final double diversityMul;
  final int nDiversity;
  final List<LeagueModeBreakdown> breakdown;

  LeagueLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.playerId,
    required this.username,
    this.avatarId,
    this.avatarUrl,
    required this.finalScore,
    required this.diversityMul,
    required this.nDiversity,
    required this.breakdown,
  });

  factory LeagueLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeagueLeaderboardEntry(
      rank: json['rank'] ?? 0,
      userId: json['user_id'] ?? 0,
      playerId: json['player_id'] ?? 0,
      username: json['username'] ?? '',
      avatarId: json['avatar_id'],
      avatarUrl: json['avatar_url'],
      finalScore: (json['final_score'] as num?)?.toDouble() ?? 0.0,
      diversityMul: (json['diversity_mul'] as num?)?.toDouble() ?? 0.0,
      nDiversity: json['n_diversity'] ?? 0,
      breakdown: (json['breakdown'] as List?)
              ?.map((e) => LeagueModeBreakdown.fromJson(e))
              .toList() ??
          [],
    );
  }
}
