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

/// Models for the new League API and screens.

class CurrentLeague {
  final int seasonNumber;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final int daysRemaining;
  final LeagueCountdown? countdown;

  CurrentLeague({
    required this.seasonNumber,
    this.startDate,
    this.endDate,
    required this.status,
    required this.daysRemaining,
    this.countdown,
  });

  factory CurrentLeague.fromJson(Map<String, dynamic> json) {
    DateTime? start;
    if (json['start_date'] != null) {
      start = DateTime.tryParse(json['start_date'].toString());
    }
    DateTime? end;
    if (json['end_date'] != null) {
      end = DateTime.tryParse(json['end_date'].toString());
    }

    LeagueCountdown? c;
    if (json['countdown'] != null &&
        json['countdown'] is Map<String, dynamic>) {
      c = LeagueCountdown.fromJson(json['countdown']);
    }

    int days =
        c?.days ??
        (json['days_remaining'] as num?)?.toInt() ??
        (json['days'] as num?)?.toInt() ??
        (end != null ? end.difference(DateTime.now()).inDays : 0);

    return CurrentLeague(
      seasonNumber:
          (json['season_number'] as num?)?.toInt() ??
          (json['season'] as num?)?.toInt() ??
          1,
      startDate: start,
      endDate: end,
      status:
          json['status']?.toString() ??
          json['league_status']?.toString() ??
          'active',
      daysRemaining: days > 0 ? days : 0,
      countdown: c,
    );
  }
}

class LeagueLeaderboardResponse {
  final bool success;
  final int seasonNumber;
  final String leagueStatus;
  final List<LeaderboardEntry> top;
  final AroundMeData? aroundMe;

  LeagueLeaderboardResponse({
    required this.success,
    required this.seasonNumber,
    required this.leagueStatus,
    required this.top,
    this.aroundMe,
  });

  factory LeagueLeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] : json;

    var topList = <LeaderboardEntry>[];
    if (data['top'] != null && data['top'] is List) {
      topList = (data['top'] as List)
          .map((e) => LeaderboardEntry.fromJson(e))
          .toList();
    } else if (data['leaderboard'] != null && data['leaderboard'] is List) {
      topList = (data['leaderboard'] as List)
          .map((e) => LeaderboardEntry.fromJson(e))
          .toList();
    } else if (json['data'] is List) {
      topList = (json['data'] as List)
          .map((e) => LeaderboardEntry.fromJson(e))
          .toList();
    }

    AroundMeData? aroundMe;
    if (data['around_me'] != null &&
        data['around_me'] is Map<String, dynamic>) {
      aroundMe = AroundMeData.fromJson(data['around_me']);
    }

    return LeagueLeaderboardResponse(
      success: json['status'] == 'success' || json['success'] == true,
      seasonNumber: data['season_number'] ?? data['season'] ?? 0,
      leagueStatus: data['league_status'] ?? data['status'] ?? 'active',
      top: topList,
      aroundMe: aroundMe,
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final int userId;
  final String name;
  final String? avatarId;
  final String? avatarUrl;
  final double finalScore;
  final double diversityMul;
  final int nDiversity;
  final String trend; // 'up' | 'down' | 'same' | 'new'
  final bool isMe;
  final List<ModeBreakdown> breakdown;

  // Backward compatibility getters
  String get username => name;
  String get playerId => userId.toString();

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    this.avatarId,
    this.avatarUrl,
    required this.finalScore,
    this.diversityMul = 1.0,
    this.nDiversity = 0,
    this.trend = 'new',
    this.isMe = false,
    this.breakdown = const [],
  });

  factory LeaderboardEntry.fromJson(
    Map<String, dynamic> json, {
    int fallbackRank = 0,
  }) {
    var breakdownList = <ModeBreakdown>[];
    if (json['breakdown'] != null && json['breakdown'] is List) {
      breakdownList = (json['breakdown'] as List)
          .map((item) => ModeBreakdown.fromJson(item))
          .toList();
    }

    int parsedUserId = 0;
    if (json['user_id'] != null) {
      parsedUserId = (json['user_id'] as num).toInt();
    } else if (json['player_id'] != null) {
      parsedUserId = int.tryParse(json['player_id'].toString()) ?? 0;
    }

    return LeaderboardEntry(
      rank: json['rank'] ?? json['position'] ?? fallbackRank,
      userId: parsedUserId,
      name:
          json['name'] ??
          json['username'] ??
          json['user']?['username'] ??
          'Player',
      avatarId:
          json['avatar_id']?.toString() ??
          json['user']?['avatar_id']?.toString() ??
          'avatar_1',
      avatarUrl: json['avatar_url']?.toString(),
      finalScore: _parseDouble(
        json['final_score'] ??
            json['total_normalized_score'] ??
            json['score'],
      ),
      diversityMul: _parseDouble(json['diversity_mul'], 1.0),
      nDiversity: _parseInt(json['n_diversity']),
      trend: json['trend']?.toString() ?? 'new',
      isMe: json['is_me'] == true,
      breakdown: breakdownList,
    );
  }
}

typedef LeagueLeaderboardEntry = LeaderboardEntry;

class UnifiedLeaderboardItem {
  final LeaderboardEntry? entry;
  final bool isGap;
  final int? gapFromRank;
  final int? gapToRank;

  const UnifiedLeaderboardItem.entry(this.entry)
      : isGap = false,
        gapFromRank = null,
        gapToRank = null;

  const UnifiedLeaderboardItem.gap({this.gapFromRank, this.gapToRank})
      : isGap = true,
        entry = null;
}

class AroundMeData {
  final int? myRank;
  final double myFinalScore;
  final List<LeaderboardEntry> window;
  final DangerZoneData dangerZone;

  AroundMeData({
    this.myRank,
    required this.myFinalScore,
    required this.window,
    required this.dangerZone,
  });

  factory AroundMeData.fromJson(Map<String, dynamic> json) {
    return AroundMeData(
      myRank: json['my_rank'] ?? json['rank'],
      myFinalScore:
          (json['my_final_score'] as num?)?.toDouble() ??
          (json['final_score'] as num?)?.toDouble() ??
          0.0,
      window: (json['window'] as List? ?? [])
          .map((e) => LeaderboardEntry.fromJson(e))
          .toList(),
      dangerZone: DangerZoneData.fromJson(
        json['danger_zone'] is Map<String, dynamic> ? json['danger_zone'] : {},
      ),
    );
  }
}

class DangerZoneData {
  final bool inDanger;
  final double pointsToSafe;
  final double pointsAtRisk;

  DangerZoneData({
    required this.inDanger,
    required this.pointsToSafe,
    required this.pointsAtRisk,
  });

  factory DangerZoneData.fromJson(Map<String, dynamic> json) {
    return DangerZoneData(
      inDanger: json['in_danger'] == true,
      pointsToSafe: (json['points_to_safe'] as num?)?.toDouble() ?? 0.0,
      pointsAtRisk: (json['points_at_risk'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PersonalBestModel {
  final String gameMode;
  final double allTimeBest;
  final double currentWeekBest;
  final bool isNewRecord;

  PersonalBestModel({
    required this.gameMode,
    required this.allTimeBest,
    required this.currentWeekBest,
    required this.isNewRecord,
  });

  factory PersonalBestModel.fromJson(Map<String, dynamic> json) {
    return PersonalBestModel(
      gameMode: json['game_mode'] ?? json['mode'] ?? '',
      allTimeBest:
          (json['all_time_best'] as num?)?.toDouble() ??
          (json['best_value'] as num?)?.toDouble() ??
          0.0,
      currentWeekBest:
          (json['current_week_best'] as num?)?.toDouble() ??
          (json['week_best'] as num?)?.toDouble() ??
          0.0,
      isNewRecord: json['is_new_record'] == true,
    );
  }
}

class ModeBreakdown {
  final String mode;
  final int bestValue;
  final double normalized;
  final int playedCount;
  final bool inTopK;
  final int allTimeBest;
  final int? weekLeaderId;
  final String? weekLeaderName;
  final int? weekLeaderScore;
  final String? weekLeaderAvatar;

  ModeBreakdown({
    required this.mode,
    required this.bestValue,
    required this.normalized,
    this.playedCount = 0,
    this.inTopK = false,
    this.allTimeBest = 0,
    this.weekLeaderId,
    this.weekLeaderName,
    this.weekLeaderScore,
    this.weekLeaderAvatar,
  });

  factory ModeBreakdown.fromJson(Map<String, dynamic> json) {
    int? leaderId;
    String? leaderName;
    int? leaderScore;
    String? leaderAvatar;

    if (json['week_leader'] != null &&
        json['week_leader'] is Map<String, dynamic>) {
      final wl = json['week_leader'] as Map<String, dynamic>;
      leaderId = (wl['user_id'] as num?)?.toInt() ??
          (wl['id'] as num?)?.toInt() ??
          (wl['player_id'] as num?)?.toInt() ??
          int.tryParse(wl['user_id']?.toString() ?? '') ??
          int.tryParse(wl['id']?.toString() ?? '');
      leaderName = wl['username']?.toString() ?? wl['name']?.toString();
      leaderScore = (wl['score'] as num?)?.toInt() ??
          (wl['best_value'] as num?)?.toInt() ??
          (wl['value'] as num?)?.toInt();
      leaderAvatar =
          wl['avatar_id']?.toString() ?? wl['avatar_url']?.toString();
    } else {
      leaderId = (json['leader_user_id'] as num?)?.toInt() ??
          (json['leader_id'] as num?)?.toInt() ??
          (json['week_leader_id'] as num?)?.toInt() ??
          (json['leader_player_id'] as num?)?.toInt() ??
          int.tryParse(json['leader_user_id']?.toString() ?? '') ??
          int.tryParse(json['leader_id']?.toString() ?? '');
      leaderName = json['leader_username']?.toString() ??
          json['leader_name']?.toString();
      leaderScore = (json['leader_score'] as num?)?.toInt() ??
          (json['leader_best_value'] as num?)?.toInt() ??
          (json['leader_value'] as num?)?.toInt();
      leaderAvatar = json['leader_avatar_id']?.toString();
    }

    return ModeBreakdown(
      mode: json['mode'] ?? json['game_mode'] ?? '',
      bestValue: (json['best_value'] as num?)?.toInt() ??
          (json['current_week_best'] as num?)?.toInt() ??
          (json['my_best_value'] as num?)?.toInt() ??
          0,
      normalized: (json['normalized'] as num?)?.toDouble() ??
          (json['normalized_score'] as num?)?.toDouble() ??
          0.0,
      playedCount: (json['played_count'] as num?)?.toInt() ?? 0,
      inTopK: json['in_top_k'] == true,
      allTimeBest: (json['all_time_best'] as num?)?.toInt() ?? 0,
      weekLeaderId: leaderId,
      weekLeaderName: leaderName,
      weekLeaderScore: leaderScore,
      weekLeaderAvatar: leaderAvatar,
    );
  }
}

class MyRankResponse {
  final int? rank;
  final int seasonNumber;
  final double finalScore;
  final bool isInLeague;
  final double diversityMul;
  final int nDiversity;
  final String trend;
  final List<ModeBreakdown> breakdown;
  final List<PersonalBestModel> personalBests;
  final DangerZoneData? dangerZone;

  bool get hasActiveRank =>
      (isInLeague || (rank != null && rank! > 0)) && finalScore > 0;

  MyRankResponse({
    this.rank,
    this.seasonNumber = 1,
    required this.finalScore,
    this.isInLeague = false,
    this.diversityMul = 1.0,
    this.nDiversity = 0,
    this.trend = 'new',
    required this.breakdown,
    this.personalBests = const [],
    this.dangerZone,
  });

  factory MyRankResponse.fromJson(Map<String, dynamic> json) {
    var breakdownList = <ModeBreakdown>[];
    final rawBreakdown =
        json['breakdown'] ?? json['mode_breakdowns'] ?? json['breakdowns'];
    if (rawBreakdown != null && rawBreakdown is List) {
      breakdownList = rawBreakdown
          .map((item) => ModeBreakdown.fromJson(item))
          .toList();
    }

    var pbList = <PersonalBestModel>[];
    final rawPbs =
        json['personal_bests'] ?? json['personalBests'] ?? json['bests'];
    if (rawPbs != null && rawPbs is List) {
      pbList = rawPbs.map((item) => PersonalBestModel.fromJson(item)).toList();
    }

    DangerZoneData? danger;
    final rawDanger = json['danger_zone'] ?? json['dangerZone'];
    if (rawDanger != null && rawDanger is Map<String, dynamic>) {
      danger = DangerZoneData.fromJson(rawDanger);
    }

    final parsedRank = json['rank'] != null
        ? _parseInt(json['rank'])
        : json['my_rank'] != null
            ? _parseInt(json['my_rank'])
            : json['position'] != null
                ? _parseInt(json['position'])
                : null;

    final parsedScore = _parseDouble(
      json['final_score'] ??
          json['my_final_score'] ??
          json['total_normalized_score'] ??
          json['score'],
    );

    final inLeague =
        json['is_in_league'] == true ||
        (parsedRank != null && parsedRank > 0 && parsedScore > 0);

    return MyRankResponse(
      rank: parsedRank,
      seasonNumber: _parseInt(json['season_number'] ?? json['season'], 1),
      finalScore: parsedScore,
      isInLeague: inLeague,
      diversityMul: _parseDouble(json['diversity_mul'], 1.0),
      nDiversity: _parseInt(json['n_diversity']),
      trend: json['trend']?.toString() ?? 'new',
      breakdown: breakdownList,
      personalBests: pbList,
      dangerZone: danger,
    );
  }
}

class ModeBadge {
  final String mode;
  final String title;
  final String playerId;
  final String username;
  final int valueAchieved;

  ModeBadge({
    required this.mode,
    required this.title,
    required this.playerId,
    required this.username,
    required this.valueAchieved,
  });

  factory ModeBadge.fromJson(Map<String, dynamic> json) {
    return ModeBadge(
      mode: json['mode'] ?? '',
      title: json['title'] ?? '',
      playerId: json['player_id']?.toString() ?? '',
      username: json['username'] ?? 'Player',
      valueAchieved: json['value_achieved'] ?? 0,
    );
  }
}

class LeagueCountdown {
  final int days;
  final int hours;
  final int minutes;
  final int seconds;
  final int totalSecondsRemaining;
  final int? endTimestamp;

  LeagueCountdown({
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.totalSecondsRemaining,
    this.endTimestamp,
  });

  factory LeagueCountdown.fromJson(Map<String, dynamic> json) {
    // If nested in 'countdown' object
    final Map<String, dynamic> cMap = json['countdown'] is Map<String, dynamic>
        ? json['countdown']
        : (json['data'] is Map<String, dynamic> &&
                  json['data']['countdown'] is Map<String, dynamic>
              ? json['data']['countdown']
              : (json['data'] is Map<String, dynamic> ? json['data'] : json));

    int days =
        (cMap['days'] as num?)?.toInt() ??
        (json['days'] as num?)?.toInt() ??
        (json['days_remaining'] as num?)?.toInt() ??
        0;
    int hours =
        (cMap['hours'] as num?)?.toInt() ??
        (json['hours'] as num?)?.toInt() ??
        (json['hours_remaining'] as num?)?.toInt() ??
        0;
    int minutes =
        (cMap['minutes'] as num?)?.toInt() ??
        (json['minutes'] as num?)?.toInt() ??
        (json['minutes_remaining'] as num?)?.toInt() ??
        0;
    int seconds =
        (cMap['seconds'] as num?)?.toInt() ??
        (json['seconds'] as num?)?.toInt() ??
        (json['seconds_remaining'] as num?)?.toInt() ??
        0;

    int total =
        (cMap['total_seconds_remaining'] as num?)?.toInt() ??
        (cMap['seconds_remaining'] as num?)?.toInt() ??
        (json['total_seconds_remaining'] as num?)?.toInt() ??
        (json['seconds_remaining'] as num?)?.toInt() ??
        0;

    final int? endTs =
        (cMap['end_timestamp'] as num?)?.toInt() ??
        (json['end_timestamp'] as num?)?.toInt();

    if (total == 0 && (days > 0 || hours > 0 || minutes > 0 || seconds > 0)) {
      total = days * 86400 + hours * 3600 + minutes * 60 + seconds;
    } else if (total == 0 && endTs != null && endTs > 0) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final diffSeconds = (endTs - nowMs) ~/ 1000;
      if (diffSeconds > 0) {
        total = diffSeconds;
        days = total ~/ 86400;
        hours = (total % 86400) ~/ 3600;
        minutes = (total % 3600) ~/ 60;
        seconds = total % 60;
      }
    } else if (total > 0 &&
        days == 0 &&
        hours == 0 &&
        minutes == 0 &&
        seconds == 0) {
      days = total ~/ 86400;
      hours = (total % 86400) ~/ 3600;
      minutes = (total % 3600) ~/ 60;
      seconds = total % 60;
    }

    return LeagueCountdown(
      days: days,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      totalSecondsRemaining: total,
      endTimestamp: endTs,
    );
  }
}

class PlayerMedal {
  final int season;
  final String medalType; // 'gold', 'silver', 'bronze'
  final String? mode;

  PlayerMedal({required this.season, required this.medalType, this.mode});

  factory PlayerMedal.fromJson(Map<String, dynamic> json) {
    return PlayerMedal(
      season: json['season'] ?? json['season_number'] ?? 0,
      medalType: json['medal_type'] ?? 'bronze',
      mode: json['mode'],
    );
  }
}

class LeagueHistoryEntry {
  final int season;
  final int rank;
  final double finalScore;
  final List<PlayerMedal> medals;
  final String? status;
  final int playedCount;

  double get totalNormalizedScore => finalScore;

  LeagueHistoryEntry({
    required this.season,
    required this.rank,
    required this.finalScore,
    required this.medals,
    this.status,
    this.playedCount = 0,
  });

  factory LeagueHistoryEntry.fromJson(Map<String, dynamic> json) {
    var medalList = <PlayerMedal>[];
    if (json['medals'] != null && json['medals'] is List) {
      medalList = (json['medals'] as List)
          .map((item) => PlayerMedal.fromJson(item))
          .toList();
    }
    return LeagueHistoryEntry(
      season: _parseInt(json['season'] ?? json['season_number']),
      rank: _parseInt(json['rank']),
      finalScore: _parseDouble(
        json['final_score'] ?? json['total_normalized_score'] ?? json['score'],
      ),
      medals: medalList,
      status: json['status']?.toString(),
      playedCount: _parseInt(json['played_count']),
    );
  }
}
