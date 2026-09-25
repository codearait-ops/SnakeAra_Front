import 'league_tier_models.dart';

int _parseInt(dynamic val, [int defaultValue = 0]) {
  if (val == null) return defaultValue;
  if (val is int) return val;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString()) ?? defaultValue;
}

double _parseDouble(dynamic val, [double defaultValue = 0.0]) {
  if (val == null) return defaultValue;
  if (val is double) return val;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? defaultValue;
}

bool _parseBool(dynamic val, [bool defaultValue = false]) {
  if (val == null) return defaultValue;
  if (val is bool) return val;
  final s = val.toString().toLowerCase().trim();
  if (s == 'true' || s == '1') return true;
  if (s == 'false' || s == '0') return false;
  return defaultValue;
}

class LeaguePlayerUser {
  final int id;
  final String username;
  final String? avatarId;
  final String? avatarUrl;
  final LeagueTier tier;
  final int? currentRank;
  final double? finalScore;

  LeaguePlayerUser({
    required this.id,
    required this.username,
    this.avatarId,
    this.avatarUrl,
    this.tier = LeagueTier.bronze,
    this.currentRank,
    this.finalScore,
  });

  factory LeaguePlayerUser.fromJson(Map<String, dynamic> json) {
    LeagueTier tier = LeagueTier.bronze;
    if (json['tier'] != null) {
      final tStr = json['tier'].toString().toLowerCase();
      tier = LeagueTier.values.firstWhere(
        (t) => t.name.toLowerCase() == tStr,
        orElse: () => LeagueTier.bronze,
      );
    }

    return LeaguePlayerUser(
      id: _parseInt(json['id'] ?? json['user_id']),
      username: (json['username'] ?? json['name'] ?? 'Player').toString(),
      avatarId: json['avatar_id']?.toString(),
      avatarUrl: json['avatar_url']?.toString() ?? json['avatar']?.toString(),
      tier: tier,
      currentRank: json['current_rank'] != null
          ? _parseInt(json['current_rank'])
          : (json['rank'] != null ? _parseInt(json['rank']) : null),
      finalScore: json['final_score'] != null
          ? _parseDouble(json['final_score'])
          : (json['score'] != null ? _parseDouble(json['score']) : null),
    );
  }
}

class LeaguePlayerSeasonInfo {
  final int seasonId;
  final int seasonNumber;
  final bool isActive;

  LeaguePlayerSeasonInfo({
    required this.seasonId,
    required this.seasonNumber,
    this.isActive = true,
  });

  factory LeaguePlayerSeasonInfo.fromJson(Map<String, dynamic> json) {
    return LeaguePlayerSeasonInfo(
      seasonId: _parseInt(json['season_id'] ?? json['id']),
      seasonNumber: _parseInt(json['season_number'] ?? json['season_id'] ?? 1, 1),
      isActive: _parseBool(json['is_active'], true),
    );
  }
}

class LeaguePlayerModeStat {
  final String mode;
  final int playedCount;
  final int bestScore;
  final bool isLeagueRecord;
  final int leagueHighestScore;

  LeaguePlayerModeStat({
    required this.mode,
    required this.playedCount,
    required this.bestScore,
    required this.isLeagueRecord,
    required this.leagueHighestScore,
  });

  factory LeaguePlayerModeStat.fromJson(Map<String, dynamic> json) {
    final best = _parseInt(json['best_score'] ?? json['score'] ?? json['best_value']);
    final highest = _parseInt(
      json['league_highest_score'] ?? json['highest_score'] ?? json['top_score'] ?? best,
      best,
    );
    final isRecord = _parseBool(
      json['is_league_record'] ?? json['is_record'] ?? json['is_highest'],
      (best > 0 && best >= highest),
    );

    return LeaguePlayerModeStat(
      mode: (json['mode'] ?? json['game_mode'] ?? '').toString(),
      playedCount: _parseInt(json['played_count'] ?? json['attempts'] ?? json['play_count']),
      bestScore: best,
      isLeagueRecord: isRecord,
      leagueHighestScore: highest,
    );
  }
}

class LeaguePlayerDailyStats {
  final int completedCount;
  final int streakDays;

  LeaguePlayerDailyStats({
    required this.completedCount,
    required this.streakDays,
  });

  factory LeaguePlayerDailyStats.fromJson(Map<String, dynamic> json) {
    return LeaguePlayerDailyStats(
      completedCount: _parseInt(
        json['completed_count'] ??
            json['missions_completed_total'] ??
            json['total_completed'] ??
            json['count'],
      ),
      streakDays: _parseInt(json['streak_days'] ?? json['streak']),
    );
  }
}

class PastPodiumEntry {
  final int seasonNumber;
  final LeagueTier tier;
  final int rank;
  final double score;

  PastPodiumEntry({
    required this.seasonNumber,
    required this.tier,
    required this.rank,
    required this.score,
  });

  factory PastPodiumEntry.fromJson(Map<String, dynamic> json) {
    LeagueTier tier = LeagueTier.bronze;
    if (json['tier'] != null) {
      final tStr = json['tier'].toString().toLowerCase();
      tier = LeagueTier.values.firstWhere(
        (t) => t.name.toLowerCase() == tStr,
        orElse: () => LeagueTier.bronze,
      );
    }

    return PastPodiumEntry(
      seasonNumber: _parseInt(json['season_number'] ?? json['season'] ?? 1, 1),
      tier: tier,
      rank: _parseInt(json['rank'] ?? json['position'] ?? 1, 1),
      score: _parseDouble(json['score'] ?? json['final_score']),
    );
  }
}

class LeaguePlayerHallOfFame {
  final int gold;
  final int silver;
  final int bronze;
  final List<PastPodiumEntry> pastPodiums;

  LeaguePlayerHallOfFame({
    required this.gold,
    required this.silver,
    required this.bronze,
    this.pastPodiums = const [],
  });

  factory LeaguePlayerHallOfFame.fromJson(Map<String, dynamic> json) {
    final medalsMap = json['medals'] is Map ? json['medals'] as Map : json;
    final gold = _parseInt(medalsMap['gold']);
    final silver = _parseInt(medalsMap['silver']);
    final bronze = _parseInt(medalsMap['bronze']);

    var podiums = <PastPodiumEntry>[];
    if (json['past_podiums'] is List) {
      podiums = (json['past_podiums'] as List)
          .whereType<Map>()
          .map((e) => PastPodiumEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return LeaguePlayerHallOfFame(
      gold: gold,
      silver: silver,
      bronze: bronze,
      pastPodiums: podiums,
    );
  }
}

class LeaguePlayerSummary {
  final LeaguePlayerUser user;
  final LeaguePlayerSeasonInfo? seasonInfo;
  final List<LeaguePlayerModeStat> modeStats;
  final LeaguePlayerDailyStats? dailyChallengeStats;
  final LeaguePlayerHallOfFame? hallOfFame;

  LeaguePlayerSummary({
    required this.user,
    this.seasonInfo,
    this.modeStats = const [],
    this.dailyChallengeStats,
    this.hallOfFame,
  });

  factory LeaguePlayerSummary.fromJson(Map<String, dynamic> json) {
    final root = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : (json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json);

    // User parsing
    final userJson = root['user'] is Map
        ? Map<String, dynamic>.from(root['user'] as Map)
        : root;
    final user = LeaguePlayerUser.fromJson(userJson);

    // Season Info parsing
    LeaguePlayerSeasonInfo? season;
    if (root['season_info'] is Map) {
      season = LeaguePlayerSeasonInfo.fromJson(
        Map<String, dynamic>.from(root['season_info'] as Map),
      );
    } else if (root['season'] is Map) {
      season = LeaguePlayerSeasonInfo.fromJson(
        Map<String, dynamic>.from(root['season'] as Map),
      );
    }

    // Mode stats parsing (handles both List and Map formats)
    final modeStats = <LeaguePlayerModeStat>[];
    final rawModes = root['mode_stats'] ?? root['modes'] ?? root['stats'];
    if (rawModes is List) {
      for (final item in rawModes) {
        if (item is Map) {
          modeStats.add(LeaguePlayerModeStat.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    } else if (rawModes is Map) {
      rawModes.forEach((k, v) {
        if (v is Map) {
          final m = Map<String, dynamic>.from(v);
          m['mode'] ??= k;
          modeStats.add(LeaguePlayerModeStat.fromJson(m));
        }
      });
    }

    // Daily Challenge parsing
    LeaguePlayerDailyStats? daily;
    if (root['daily_challenge_stats'] is Map) {
      daily = LeaguePlayerDailyStats.fromJson(
        Map<String, dynamic>.from(root['daily_challenge_stats'] as Map),
      );
    } else if (root['daily_challenges'] is Map) {
      daily = LeaguePlayerDailyStats.fromJson(
        Map<String, dynamic>.from(root['daily_challenges'] as Map),
      );
    }

    // Hall of fame parsing
    LeaguePlayerHallOfFame? hof;
    if (root['hall_of_fame'] is Map) {
      hof = LeaguePlayerHallOfFame.fromJson(
        Map<String, dynamic>.from(root['hall_of_fame'] as Map),
      );
    }

    return LeaguePlayerSummary(
      user: user,
      seasonInfo: season,
      modeStats: modeStats,
      dailyChallengeStats: daily,
      hallOfFame: hof,
    );
  }
}
