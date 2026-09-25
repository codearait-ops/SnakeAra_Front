class Achievement {
  final String key;
  final String title;
  final String description;
  final String icon;
  final String gameMode;
  final String achievedAt;

  Achievement({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.gameMode,
    required this.achievedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      key: json['key'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      gameMode: json['game_mode'] ?? '',
      achievedAt: json['achieved_at'] ?? '',
    );
  }
}

class UniversalPlayerProfile {
  final int id;
  final String username;
  final String? avatarId;
  final String? avatarUrl;
  final String? bio;
  final int xp;
  final int level;
  final int? nextLevelXp;
  final int honor;
  final String createdAt;
  final Map<String, int> playCounts;
  final Map<String, int> bestScores;
  final Map<String, dynamic> dailyChallengeMedals;
  final Map<String, dynamic> hallOfFameMedals;
  final List<Achievement> achievements;

  UniversalPlayerProfile({
    required this.id,
    required this.username,
    this.avatarId,
    this.avatarUrl,
    this.bio,
    required this.xp,
    this.level = 1,
    this.nextLevelXp,
    required this.honor,
    required this.createdAt,
    required this.playCounts,
    required this.bestScores,
    required this.dailyChallengeMedals,
    required this.hallOfFameMedals,
    required this.achievements,
  });

  factory UniversalPlayerProfile.fromJson(Map<String, dynamic> json) {
    final rawXp = json['xp_total'] ?? json['xp'] ?? json['total_xp'] ?? 0;
    final parsedLevel = json['level'] ?? 1;

    Map<String, int> parseStringIntMap(dynamic source) {
      if (source is! Map) return {};
      final map = <String, int>{};
      source.forEach((k, v) {
        if (k != null) {
          map[k.toString()] = (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 0;
        }
      });
      return map;
    }

    return UniversalPlayerProfile(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? 'Player',
      avatarId: json['avatar_id']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      bio: json['bio']?.toString(),
      xp: rawXp is num ? rawXp.toInt() : int.tryParse(rawXp.toString()) ?? 0,
      level: parsedLevel is num ? parsedLevel.toInt() : int.tryParse(parsedLevel.toString()) ?? 1,
      nextLevelXp: json['next_level_xp'] is num
          ? (json['next_level_xp'] as num).toInt()
          : int.tryParse(json['next_level_xp']?.toString() ?? ''),
      honor: json['honor'] is num
          ? (json['honor'] as num).toInt()
          : int.tryParse(json['honor']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      playCounts: parseStringIntMap(json['play_counts']),
      bestScores: parseStringIntMap(json['best_scores']),
      dailyChallengeMedals: () {
        final map = json['daily_challenge_medals'] is Map
            ? Map<String, dynamic>.from(json['daily_challenge_medals'])
            : <String, dynamic>{};
        final missionsTotal = json['missions_completed_total'] ??
            json['completed_missions'] ??
            json['missions_completed'];
        if (missionsTotal != null) {
          map['completed_count'] ??= missionsTotal;
          map['missions_completed_total'] ??= missionsTotal;
        }
        return map;
      }(),
      hallOfFameMedals: json['hall_of_fame_medals'] is Map
          ? Map<String, dynamic>.from(json['hall_of_fame_medals'])
          : {},
      achievements: (json['achievements'] as List?)
              ?.map((e) => Achievement.fromJson(
                  e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );
  }
}
