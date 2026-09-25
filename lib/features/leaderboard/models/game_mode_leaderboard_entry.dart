class GameModeLeaderboardEntry {
  final int rank;
  final int userId;
  final String username;
  final String? avatarId;
  final String? avatarUrl;
  final String? bio;
  final int bestValue;

  GameModeLeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    this.avatarId,
    this.avatarUrl,
    this.bio,
    required this.bestValue,
  });

  factory GameModeLeaderboardEntry.fromJson(Map<String, dynamic> json, {int fallbackRank = 0}) {
    return GameModeLeaderboardEntry(
      rank: json['rank'] ?? json['position'] ?? fallbackRank,
      userId: json['user_id'] ?? json['userId'] ?? json['id'] ?? 0,
      username: json['username'] ?? json['user']?['username'] ?? json['name'] ?? 'Player',
      avatarId: (json['avatar_id'] ?? json['avatarId'] ?? json['user']?['avatar_id'] ?? json['avatar'] ?? 'avatar_1')?.toString(),
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl'] ?? json['user']?['avatar_url'])?.toString(),
      bio: json['bio']?.toString() ?? json['user']?['bio']?.toString() ?? json['player']?['bio']?.toString() ?? json['profile']?['bio']?.toString(),
      bestValue: json['best_value'] ?? json['bestValue'] ?? json['value'] ?? json['score'] ?? json['highscore'] ?? json['classic_highscore'] ?? 0,
    );
  }
}
