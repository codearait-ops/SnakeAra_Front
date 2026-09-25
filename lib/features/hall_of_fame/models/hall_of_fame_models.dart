import '../../league/models/league_models.dart';

class HallOfFamePlayer {
  final String playerId;
  final String username;
  final String avatarId;

  HallOfFamePlayer({
    required this.playerId,
    required this.username,
    required this.avatarId,
  });

  factory HallOfFamePlayer.fromJson(Map<String, dynamic> json) {
    return HallOfFamePlayer(
      playerId: json['player_id']?.toString() ?? json['user_id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Player',
      avatarId: json['avatar_id']?.toString() ?? 'avatar_1',
    );
  }
}

class HallOfFameEntry {
  final int season;
  final String? mode;
  final String? tier;
  final HallOfFamePlayer? goldPlayer;
  final HallOfFamePlayer? silverPlayer;
  final HallOfFamePlayer? bronzePlayer;
  final int goldScore;
  final int silverScore;
  final int bronzeScore;

  HallOfFameEntry({
    required this.season,
    this.mode,
    this.tier,
    this.goldPlayer,
    this.silverPlayer,
    this.bronzePlayer,
    required this.goldScore,
    required this.silverScore,
    required this.bronzeScore,
  });

  factory HallOfFameEntry.fromJson(Map<String, dynamic> json) {
    int parseScore(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return double.tryParse(val.toString())?.round() ?? 0;
    }

    HallOfFamePlayer? parsePlayer(dynamic val) {
      if (val == null || val is! Map) return null;
      final m = Map<String, dynamic>.from(val);
      if (m['player_id'] == null && m['user_id'] == null && m['username'] == null) {
        return null;
      }
      return HallOfFamePlayer.fromJson(m);
    }

    HallOfFamePlayer? goldPlayer;
    int goldScore = 0;
    if (json['gold'] != null && json['gold'] is Map) {
      goldPlayer = parsePlayer(json['gold']);
      goldScore = parseScore(json['gold']['score']);
    } else if (json['gold_player'] != null) {
      goldPlayer = parsePlayer(json['gold_player']);
      goldScore = parseScore(json['gold_score']);
    }

    HallOfFamePlayer? silverPlayer;
    int silverScore = 0;
    if (json['silver'] != null && json['silver'] is Map) {
      silverPlayer = parsePlayer(json['silver']);
      silverScore = parseScore(json['silver']['score']);
    } else if (json['silver_player'] != null) {
      silverPlayer = parsePlayer(json['silver_player']);
      silverScore = parseScore(json['silver_score']);
    }

    HallOfFamePlayer? bronzePlayer;
    int bronzeScore = 0;
    if (json['bronze'] != null && json['bronze'] is Map) {
      bronzePlayer = parsePlayer(json['bronze']);
      bronzeScore = parseScore(json['bronze']['score']);
    } else if (json['bronze_player'] != null) {
      bronzePlayer = parsePlayer(json['bronze_player']);
      bronzeScore = parseScore(json['bronze_score']);
    }

    final rawSeason = json['season_number'] ?? json['season'] ?? 0;
    final season = rawSeason is num ? rawSeason.toInt() : (int.tryParse(rawSeason.toString()) ?? 0);

    return HallOfFameEntry(
      season: season,
      mode: json['mode']?.toString(),
      tier: json['tier']?.toString(),
      goldPlayer: goldPlayer,
      silverPlayer: silverPlayer,
      bronzePlayer: bronzePlayer,
      goldScore: goldScore,
      silverScore: silverScore,
      bronzeScore: bronzeScore,
    );
  }
}

/// Aggregated response for GET /hall-of-fame/bundle
class HallOfFameBundleResponse {
  final List<HallOfFameEntry> currentSeason;
  final List<HallOfFameEntry> pastSeasons;

  HallOfFameBundleResponse({
    this.currentSeason = const [],
    this.pastSeasons = const [],
  });

  List<HallOfFameEntry> get allSeasons => [...currentSeason, ...pastSeasons];

  factory HallOfFameBundleResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;

    final currentList = <HallOfFameEntry>[];
    if (data['current_season'] != null && data['current_season'] is List) {
      for (final item in data['current_season'] as List) {
        if (item is Map) {
          currentList.add(HallOfFameEntry.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final pastList = <HallOfFameEntry>[];
    if (data['past_seasons'] != null && data['past_seasons'] is List) {
      for (final item in data['past_seasons'] as List) {
        if (item is Map) {
          pastList.add(HallOfFameEntry.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return HallOfFameBundleResponse(
      currentSeason: currentList,
      pastSeasons: pastList,
    );
  }
}

class SeasonDetail {
  final int season;
  final CurrentLeague? leagueInfo;
  final List<HallOfFameEntry> overallWinners;
  final List<ModeBadge> badges;

  SeasonDetail({
    required this.season,
    this.leagueInfo,
    required this.overallWinners,
    required this.badges,
  });

  factory SeasonDetail.fromJson(Map<String, dynamic> json) {
    var overallList = <HallOfFameEntry>[];
    if (json['overall_winners'] != null && json['overall_winners'] is List) {
      overallList = (json['overall_winners'] as List)
          .map((item) => HallOfFameEntry.fromJson(item))
          .toList();
    }
    
    var badgeList = <ModeBadge>[];
    if (json['badges'] != null && json['badges'] is List) {
      badgeList = (json['badges'] as List)
          .map((item) => ModeBadge.fromJson(item))
          .toList();
    }

    return SeasonDetail(
      season: json['season'] ?? 0,
      leagueInfo: json['league_info'] != null ? CurrentLeague.fromJson(json['league_info']) : null,
      overallWinners: overallList,
      badges: badgeList,
    );
  }
}
