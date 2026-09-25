/// Model representing an online player entry in the Classic Mode League.
class OnlineLeaderboardEntry {
  final int rank;
  final int userId;
  final String username;
  final String avatarId;
  final String? avatarUrl;
  final String? bio;
  final int score;

  OnlineLeaderboardEntry({
    required this.rank,
    this.userId = 0,
    required this.username,
    required this.avatarId,
    this.avatarUrl,
    this.bio,
    required this.score,
  });

  factory OnlineLeaderboardEntry.fromJson(Map<String, dynamic> json, {int fallbackRank = 0}) {
    return OnlineLeaderboardEntry(
      rank: json['rank'] ?? json['position'] ?? fallbackRank,
      userId: json['user_id'] ?? json['userId'] ?? json['id'] ?? json['user']?['id'] ?? 0,
      username: json['username'] ?? json['user']?['username'] ?? json['name'] ?? 'Player',
      avatarId: (json['avatar_id'] ?? json['avatarId'] ?? json['user']?['avatar_id'] ?? json['avatar'] ?? 'avatar_1')?.toString() ?? 'avatar_1',
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl'] ?? json['user']?['avatar_url'])?.toString(),
      bio: json['bio']?.toString() ?? json['user']?['bio']?.toString() ?? json['player']?['bio']?.toString(),
      score: json['best_value'] ?? json['value'] ?? json['score'] ?? json['classic_highscore'] ?? json['highScore'] ?? 0,
    );
  }
}
