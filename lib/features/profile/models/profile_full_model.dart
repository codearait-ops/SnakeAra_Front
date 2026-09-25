import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/parse_route.dart';
import '../../auth/models/user_model.dart';
import '../../game/models/game_mode_config.dart';

/// Single game mode record returned in ProfileMeFullResponse (GET /profile/me/full).
class ModeRecordModel {
  final String gameMode;
  final int bestValue;
  final int playCount;

  ModeRecordModel({
    required this.gameMode,
    this.bestValue = 0,
    this.playCount = 0,
  });

  /// Matching GameModeConfig resolved by mode string
  GameModeConfig? get config => GameModeConfig.findByModeString(gameMode);

  /// Canonical ID (e.g. 'classic', 'laser', 'blindMemory', 'infection', 'meltdown')
  String get canonicalId => config?.id ?? gameMode;

  /// Theme color for this mode
  Color get color =>
      config?.accentColor ?? GameModeConfig.getColorForMode(gameMode);

  factory ModeRecordModel.fromJson(Map<String, dynamic> json) {
    final rawBest = json['best_value'] ?? json['bestValue'] ?? json['score'];
    final bestValue = rawBest is num
        ? rawBest.toInt()
        : (int.tryParse(rawBest?.toString() ?? '') ?? 0);

    final rawCount = json['play_count'] ?? json['playCount'] ?? json['count'];
    final playCount = rawCount is num
        ? rawCount.toInt()
        : (int.tryParse(rawCount?.toString() ?? '') ?? 0);

    return ModeRecordModel(
      gameMode: json['game_mode']?.toString() ?? json['mode']?.toString() ?? '',
      bestValue: bestValue,
      playCount: playCount,
    );
  }
}

/// Medals summary in weekly league.
class LeagueMedalsSummary {
  final int gold;
  final int silver;
  final int bronze;
  final int total;

  LeagueMedalsSummary({
    this.gold = 0,
    this.silver = 0,
    this.bronze = 0,
    this.total = 0,
  });

  factory LeagueMedalsSummary.fromJson(Map<String, dynamic> json) {
    final gold =
        (json['gold'] as num?)?.toInt() ??
        int.tryParse(json['gold']?.toString() ?? '') ??
        0;
    final silver =
        (json['silver'] as num?)?.toInt() ??
        int.tryParse(json['silver']?.toString() ?? '') ??
        0;
    final bronze =
        (json['bronze'] as num?)?.toInt() ??
        int.tryParse(json['bronze']?.toString() ?? '') ??
        0;
    final total =
        (json['total'] as num?)?.toInt() ??
        int.tryParse(json['total']?.toString() ?? '') ??
        (gold + silver + bronze);

    return LeagueMedalsSummary(
      gold: gold,
      silver: silver,
      bronze: bronze,
      total: total,
    );
  }
}

/// Comprehensive full player profile response (GET /profile/me/full).
class ProfileMeFullResponse {
  final UserModel user;
  final List<ModeRecordModel> modeRecords;
  final int totalGamesPlayed;
  final LeagueMedalsSummary leagueMedals;
  final int missionsCompletedTotal;

  ProfileMeFullResponse({
    required this.user,
    this.modeRecords = const [],
    this.totalGamesPlayed = 0,
    required this.leagueMedals,
    this.missionsCompletedTotal = 0,
  });

  /// Helper to find a specific mode record by any ID or mode name
  ModeRecordModel? getRecordForMode(String modeId) {
    final norm = modeId.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    for (final rec in modeRecords) {
      if (rec.gameMode.toLowerCase().replaceAll('_', '').replaceAll(' ', '') ==
              norm ||
          rec.canonicalId.toLowerCase() == norm) {
        return rec;
      }
    }
    return null;
  }

  factory ProfileMeFullResponse.fromJson(
    Map<String, dynamic> json, {
    String? token,
  }) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final userJson = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : <String, dynamic>{};
    var user = UserModel.fromJson(userJson, fallbackToken: token);

    final recordsList = <ModeRecordModel>[];
    if (data['mode_records'] != null && data['mode_records'] is List) {
      for (final item in data['mode_records'] as List) {
        if (item is Map) {
          recordsList.add(
            ModeRecordModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    // Sync classic high score into user if available from mode records
    if (user.classicHighscore == 0 && recordsList.isNotEmpty) {
      final classicRec = recordsList.firstWhereOrNull(
        (r) => r.gameMode == 'classic' || r.canonicalId == 'classic',
      );
      if (classicRec != null && classicRec.bestValue > 0) {
        user = user.copyWith(classicHighscore: classicRec.bestValue);
      }
    }

    final rawTotalGames =
        data['total_games_played'] ??
        data['totalGamesPlayed'] ??
        userJson['total_games_played'] ??
        0;
    final totalGamesPlayed = rawTotalGames is num
        ? rawTotalGames.toInt()
        : (int.tryParse(rawTotalGames.toString()) ?? 0);

    final medalsJson = data['league_medals'] is Map
        ? Map<String, dynamic>.from(data['league_medals'] as Map)
        : <String, dynamic>{};
    final leagueMedals = LeagueMedalsSummary.fromJson(medalsJson);

    final rawMissions = data['missions_completed_total'] ??
        data['completed_missions'] ??
        data['missions_completed'] ??
        userJson['missions_completed_total'] ??
        userJson['completed_missions'] ??
        userJson['missions_completed'] ??
        json['missions_completed_total'] ??
        json['completed_missions'] ??
        0;
    final missionsCompletedTotal = rawMissions is num
        ? rawMissions.toInt()
        : (int.tryParse(rawMissions.toString()) ?? 0);

    return ProfileMeFullResponse(
      user: user,
      modeRecords: recordsList,
      totalGamesPlayed: totalGamesPlayed,
      leagueMedals: leagueMedals,
      missionsCompletedTotal: missionsCompletedTotal,
    );
  }
}
