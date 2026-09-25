import 'package:flutter/material.dart';

import 'league_tier_models.dart';

/// The 5 phases of the Weekend League lifecycle.
enum LeagueSeasonPhase {
  registrationOpen,
  grouping,
  active,
  completed,
  cancelledLowTurnout,
  unknown;

  static LeagueSeasonPhase fromString(String? val) {
    switch (val?.trim().toLowerCase()) {
      case 'registration_open':
      case 'registering':
      case 'registration':
      case 'open':
        return LeagueSeasonPhase.registrationOpen;
      case 'grouping':
      case 'matching':
        return LeagueSeasonPhase.grouping;
      case 'active':
      case 'in_progress':
      case 'running':
        return LeagueSeasonPhase.active;
      case 'completed':
      case 'ended':
      case 'results_announced':
        return LeagueSeasonPhase.completed;
      case 'cancelled_low_turnout':
      case 'cancelled':
      case 'canceled':
        return LeagueSeasonPhase.cancelledLowTurnout;
      default:
        return LeagueSeasonPhase.unknown;
    }
  }

  String get apiValue {
    switch (this) {
      case LeagueSeasonPhase.registrationOpen:
        return 'registration_open';
      case LeagueSeasonPhase.grouping:
        return 'grouping';
      case LeagueSeasonPhase.active:
        return 'active';
      case LeagueSeasonPhase.completed:
        return 'completed';
      case LeagueSeasonPhase.cancelledLowTurnout:
        return 'cancelled_low_turnout';
      case LeagueSeasonPhase.unknown:
        return 'unknown';
    }
  }
}

/// Final results model for the completed season phase.
class LeagueCompletedResult {
  final int? rank;
  final String status; // 'promoted', 'relegated', 'stayed'
  final LeagueTier tier;
  final LeagueTier? previousTier;
  final int? coinsRewarded; // Kept in model per backend spec requirement

  LeagueCompletedResult({
    this.rank,
    required this.status,
    required this.tier,
    this.previousTier,
    this.coinsRewarded,
  });

  bool get isPromoted => status.toLowerCase() == 'promoted';
  bool get isRelegated => status.toLowerCase() == 'relegated';
  bool get isStayed => status.toLowerCase() == 'stayed';

  factory LeagueCompletedResult.fromJson(Map<String, dynamic> json) {
    LeagueTier tier = LeagueTier.bronze;
    if (json['tier'] != null) {
      final tStr = json['tier'].toString().toLowerCase();
      tier = LeagueTier.values.firstWhere(
        (t) => t.name.toLowerCase() == tStr,
        orElse: () => LeagueTier.bronze,
      );
    }

    LeagueTier? prevTier;
    if (json['previous_tier'] != null) {
      final ptStr = json['previous_tier'].toString().toLowerCase();
      prevTier = LeagueTier.values.firstWhere(
        (t) => t.name.toLowerCase() == ptStr,
        orElse: () => tier,
      );
    }

    return LeagueCompletedResult(
      rank: json['rank'] != null ? int.tryParse(json['rank'].toString()) : null,
      status: json['status']?.toString() ?? 'stayed',
      tier: tier,
      previousTier: prevTier,
      coinsRewarded: json['coins_rewarded'] != null
          ? int.tryParse(json['coins_rewarded'].toString())
          : (json['reward_coins'] != null
                ? int.tryParse(json['reward_coins'].toString())
                : (json['coins'] != null
                      ? int.tryParse(json['coins'].toString())
                      : null)),
    );
  }
}

/// Response data model for GET /league/status.
class LeagueSeasonStatus {
  final int? seasonId;
  final String rawStatus;
  final LeagueSeasonPhase phase;
  final int seasonNumber;
  final DateTime? registrationOpensAt;
  final DateTime? registrationClosesAt;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? secondsRemainingInPhase;
  final int entryCost;
  final bool isFreeEntry;
  final bool isRegistered;
  final bool autoEnroll;
  final String? userRawStatus;
  final LeagueTier? tier;
  final int? groupId;
  final int? groupIndex;
  final String? registeredVia;
  final bool isFreeRegistration;
  final int? userCoins;
  final LeagueCompletedResult? completedResult;
  final bool refunded;

  LeagueSeasonStatus({
    this.seasonId,
    required this.rawStatus,
    required this.phase,
    required this.seasonNumber,
    this.registrationOpensAt,
    this.registrationClosesAt,
    this.startsAt,
    this.endsAt,
    this.secondsRemainingInPhase,
    this.entryCost = 150,
    this.isFreeEntry = false,
    this.isRegistered = false,
    this.autoEnroll = false,
    this.userRawStatus,
    this.tier,
    this.groupId,
    this.groupIndex,
    this.registeredVia,
    this.isFreeRegistration = false,
    this.userCoins,
    this.completedResult,
    this.refunded = false,
  });

  static DateTime? _parseUtc(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val.toUtc();
    final str = val.toString();
    if (str.isEmpty) return null;
    try {
      final dt = DateTime.parse(str);
      return dt.isUtc ? dt : dt.toUtc();
    } catch (_) {
      final ms = int.tryParse(str);
      if (ms != null) {
        if (ms > 100000000000) {
          return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
        } else {
          return DateTime.fromMillisecondsSinceEpoch(ms * 1000, isUtc: true);
        }
      }
      return null;
    }
  }

  factory LeagueSeasonStatus.fromJson(Map<String, dynamic> json) {
    // If wrapped in 'data', unwrap it:
    final root = (json['data'] is Map)
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    // Extract nested maps: 'season' and 'user_status', falling back to root for flat payloads
    final season = (root['season'] is Map)
        ? Map<String, dynamic>.from(root['season'] as Map)
        : root;

    final userStatus = (root['user_status'] is Map)
        ? Map<String, dynamic>.from(root['user_status'] as Map)
        : root;

    // --- Season details ---
    final seasonId = season['id'] != null
        ? int.tryParse(season['id'].toString())
        : (root['id'] != null ? int.tryParse(root['id'].toString()) : null);

    final seasonNum = season['season_number'] != null
        ? int.tryParse(season['season_number'].toString()) ?? 1
        : (season['season_id'] != null
              ? int.tryParse(season['season_id'].toString()) ?? 1
              : (root['season_number'] != null
                    ? int.tryParse(root['season_number'].toString()) ?? 1
                    : (root['season_id'] != null
                          ? int.tryParse(root['season_id'].toString()) ?? 1
                          : (seasonId ?? 1))));

    final statusStr =
        (season['phase'] ??
                season['status'] ??
                root['phase'] ??
                root['status'] ??
                '')
            .toString();
    final phase = LeagueSeasonPhase.fromString(statusStr);

    final registrationOpensAt = _parseUtc(
      season['registration_opens_at'] ?? root['registration_opens_at'],
    );
    final registrationClosesAt = _parseUtc(
      season['registration_closes_at'] ?? root['registration_closes_at'],
    );
    final startsAt = _parseUtc(season['starts_at'] ?? root['starts_at']);
    final endsAt = _parseUtc(season['ends_at'] ?? root['ends_at']);

    final secondsRemaining = season['seconds_remaining_in_phase'] != null
        ? int.tryParse(season['seconds_remaining_in_phase'].toString())
        : (root['seconds_remaining_in_phase'] != null
              ? int.tryParse(root['seconds_remaining_in_phase'].toString())
              : null);

    final cost = season['entry_cost'] != null
        ? int.tryParse(season['entry_cost'].toString()) ?? 150
        : (season['cost'] != null
              ? int.tryParse(season['cost'].toString()) ?? 150
              : (root['entry_cost'] != null
                    ? int.tryParse(root['entry_cost'].toString()) ?? 150
                    : (root['cost'] != null
                          ? int.tryParse(root['cost'].toString()) ?? 150
                          : 150)));

    // --- User status details ---
    final userSeasonId = userStatus['season_id'] != null
        ? int.tryParse(userStatus['season_id'].toString())
        : (userStatus['season_number'] != null
              ? int.tryParse(userStatus['season_number'].toString())
              : null);

    // Helper for resilient boolean/truthy parsing across MySQL, Laravel, and JSON formats
    bool isTruthy(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      if (val is num) return val != 0;
      final s = val.toString().trim().toLowerCase();
      return s == 'true' ||
          s == '1' ||
          s == 'yes' ||
          s == 'registered' ||
          s == 'entered' ||
          s == 'joined' ||
          s == 'active';
    }

    bool isReg =
        isTruthy(userStatus['is_registered']) ||
        isTruthy(userStatus['registered']) ||
        isTruthy(userStatus['is_entered']) ||
        isTruthy(userStatus['has_entered']) ||
        isTruthy(userStatus['user_entered']) ||
        isTruthy(userStatus['joined']) ||
        isTruthy(userStatus['is_joined']) ||
        isTruthy(userStatus['status']) ||
        isTruthy(root['is_registered']) ||
        isTruthy(root['registered']) ||
        isTruthy(root['is_entered']) ||
        isTruthy(root['user_status']);

    debugPrint(
      '🔍 [LeagueSeasonStatus] parsed status: seasonId=$seasonId, userSeasonId=$userSeasonId, isReg=$isReg, userStatus=$userStatus',
    );

    final auto =
        isTruthy(userStatus['auto_enroll_enabled']) ||
        isTruthy(userStatus['auto_enroll']) ||
        isTruthy(userStatus['auto_enrolled']) ||
        isTruthy(root['auto_enroll_enabled']) ||
        isTruthy(root['auto_enroll']) ||
        isTruthy(root['auto_enrolled']);

    final isFreeReg =
        userStatus['is_free_registration'] == true ||
        root['is_free_registration'] == true;

    final isFree =
        isFreeReg ||
        userStatus['is_free_entry'] == true ||
        userStatus['free_entry'] == true ||
        season['is_free_entry'] == true ||
        season['free_entry'] == true ||
        root['is_free_entry'] == true ||
        root['is_first_league'] == true ||
        root['free_entry'] == true ||
        cost == 0;

    final userRawStatus =
        userStatus['status']?.toString() ??
        (root['user_status'] is String ? root['user_status'].toString() : null);

    final registeredVia =
        userStatus['registered_via']?.toString() ??
        root['registered_via']?.toString();

    LeagueTier? parsedTier;
    final rawTier = (userStatus['tier'] ?? root['tier'])
        ?.toString()
        .toLowerCase();
    if (rawTier != null && rawTier.isNotEmpty) {
      parsedTier = LeagueTier.values.firstWhere(
        (t) => t.name.toLowerCase() == rawTier,
        orElse: () => LeagueTier.bronze,
      );
    }

    final groupId = userStatus['group_id'] != null
        ? int.tryParse(userStatus['group_id'].toString())
        : (root['group_id'] != null
              ? int.tryParse(root['group_id'].toString())
              : null);

    final groupIndex = userStatus['group_index'] != null
        ? int.tryParse(userStatus['group_index'].toString())
        : (root['group_index'] != null
              ? int.tryParse(root['group_index'].toString())
              : null);

    int? coins;
    final coinsRaw =
        userStatus['user_coins'] ??
        userStatus['wallet_balance'] ??
        userStatus['balance'] ??
        root['user_coins'] ??
        root['wallet_balance'] ??
        root['balance'];
    if (coinsRaw != null) {
      coins = int.tryParse(coinsRaw.toString());
    }

    LeagueCompletedResult? completed;
    final resultsRaw =
        season['results'] ??
        season['last_season_result'] ??
        season['result'] ??
        root['results'] ??
        root['last_season_result'] ??
        root['result'];
    if (resultsRaw is Map) {
      completed = LeagueCompletedResult.fromJson(
        Map<String, dynamic>.from(resultsRaw as Map),
      );
    } else if (phase == LeagueSeasonPhase.completed &&
        (season['result'] is Map || root['result'] is Map)) {
      final res =
          (season['result'] is Map ? season['result'] : root['result']) as Map;
      completed = LeagueCompletedResult.fromJson(
        Map<String, dynamic>.from(res),
      );
    }

    final isRefunded =
        userStatus['refunded'] == true ||
        userStatus['is_refunded'] == true ||
        season['refunded'] == true ||
        season['is_refunded'] == true ||
        root['refunded'] == true ||
        root['is_refunded'] == true ||
        root['coins_refunded'] == true;

    return LeagueSeasonStatus(
      seasonId: seasonId,
      rawStatus: statusStr,
      phase: phase,
      seasonNumber: seasonNum,
      registrationOpensAt: registrationOpensAt,
      registrationClosesAt: registrationClosesAt,
      startsAt: startsAt,
      endsAt: endsAt,
      secondsRemainingInPhase: secondsRemaining,
      entryCost: cost,
      isFreeEntry: isFree,
      isRegistered: isReg,
      autoEnroll: auto,
      userRawStatus: userRawStatus,
      tier: parsedTier,
      groupId: groupId,
      groupIndex: groupIndex,
      registeredVia: registeredVia,
      isFreeRegistration: isFreeReg,
      userCoins: coins,
      completedResult: completed,
      refunded: isRefunded,
    );
  }

  LeagueSeasonStatus copyWith({
    int? seasonId,
    String? rawStatus,
    LeagueSeasonPhase? phase,
    int? seasonNumber,
    DateTime? registrationOpensAt,
    DateTime? registrationClosesAt,
    DateTime? startsAt,
    DateTime? endsAt,
    int? secondsRemainingInPhase,
    int? entryCost,
    bool? isFreeEntry,
    bool? isRegistered,
    bool? autoEnroll,
    String? userRawStatus,
    LeagueTier? tier,
    int? groupId,
    int? groupIndex,
    String? registeredVia,
    bool? isFreeRegistration,
    int? userCoins,
    LeagueCompletedResult? completedResult,
    bool? refunded,
  }) {
    return LeagueSeasonStatus(
      seasonId: seasonId ?? this.seasonId,
      rawStatus: rawStatus ?? this.rawStatus,
      phase: phase ?? this.phase,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      registrationOpensAt: registrationOpensAt ?? this.registrationOpensAt,
      registrationClosesAt: registrationClosesAt ?? this.registrationClosesAt,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      secondsRemainingInPhase:
          secondsRemainingInPhase ?? this.secondsRemainingInPhase,
      entryCost: entryCost ?? this.entryCost,
      isFreeEntry: isFreeEntry ?? this.isFreeEntry,
      isRegistered: isRegistered ?? this.isRegistered,
      autoEnroll: autoEnroll ?? this.autoEnroll,
      userRawStatus: userRawStatus ?? this.userRawStatus,
      tier: tier ?? this.tier,
      groupId: groupId ?? this.groupId,
      groupIndex: groupIndex ?? this.groupIndex,
      registeredVia: registeredVia ?? this.registeredVia,
      isFreeRegistration: isFreeRegistration ?? this.isFreeRegistration,
      userCoins: userCoins ?? this.userCoins,
      completedResult: completedResult ?? this.completedResult,
      refunded: refunded ?? this.refunded,
    );
  }
}

/// Member in the live group leaderboard.
class LeagueGroupMember {
  final int rank;
  final int userId;
  final String username;
  final String? avatar;
  final num score;
  final bool isMe;
  final LeagueTier? tier;

  LeagueGroupMember({
    required this.rank,
    required this.userId,
    required this.username,
    this.avatar,
    required this.score,
    required this.isMe,
    this.tier,
  });

  factory LeagueGroupMember.fromJson(
    Map<String, dynamic> json, {
    int? currentUserId,
    String? currentUsername,
  }) {
    final uid = json['user_id'] != null
        ? int.tryParse(json['user_id'].toString()) ?? 0
        : (json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0);

    final name = (json['username'] ?? json['name'] ?? 'Player').toString();

    final isMeExplicit =
        json['is_me'] == true || json['is_current_user'] == true;
    final isMeMatched =
        (currentUserId != null && currentUserId > 0 && uid == currentUserId) ||
        (currentUsername != null &&
            currentUsername.isNotEmpty &&
            name.trim().toLowerCase() == currentUsername.trim().toLowerCase());

    LeagueTier? tier;
    if (json['tier'] != null) {
      final tStr = json['tier'].toString().toLowerCase();
      tier = LeagueTier.values.firstWhere(
        (t) => t.name.toLowerCase() == tStr,
        orElse: () => LeagueTier.bronze,
      );
    }

    return LeagueGroupMember(
      rank: json['rank'] != null
          ? int.tryParse(json['rank'].toString()) ?? 0
          : 0,
      userId: uid,
      username: name,
      avatar: json['avatar']?.toString() ?? json['avatar_url']?.toString(),
      score: json['score'] != null
          ? num.tryParse(json['score'].toString()) ?? 0
          : (json['final_score'] != null
                ? num.tryParse(json['final_score'].toString()) ?? 0
                : 0),
      isMe: isMeExplicit || isMeMatched,
      tier: tier,
    );
  }
}

/// Response data model for GET /league/group.
class LeagueGroupResponse {
  final dynamic groupId;
  final LeagueTier tier;
  final int promotionCutoff; // Top count promoted
  final int relegationCutoff; // Bottom count relegated
  final List<LeagueGroupMember> members;
  final int? myRank;
  final num? myScore;
  final DateTime? endsAt;

  LeagueGroupResponse({
    this.groupId,
    required this.tier,
    this.promotionCutoff = 0,
    this.relegationCutoff = 0,
    required this.members,
    this.myRank,
    this.myScore,
    this.endsAt,
  });

  factory LeagueGroupResponse.fromJson(
    Map<String, dynamic> json, {
    int? currentUserId,
    String? currentUsername,
  }) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    LeagueTier tier = LeagueTier.bronze;
    if (data['tier'] != null) {
      final tStr = data['tier'].toString().toLowerCase();
      tier = LeagueTier.values.firstWhere(
        (t) => t.name.toLowerCase() == tStr,
        orElse: () => LeagueTier.bronze,
      );
    }

    final promo = data['promotion_cutoff'] != null
        ? int.tryParse(data['promotion_cutoff'].toString()) ?? 0
        : (data['promotion_count'] != null
              ? int.tryParse(data['promotion_count'].toString()) ?? 0
              : (data['promoted_count'] != null
                    ? int.tryParse(data['promoted_count'].toString()) ?? 0
                    : 0));

    final releg = data['relegation_cutoff'] != null
        ? int.tryParse(data['relegation_cutoff'].toString()) ?? 0
        : (data['relegation_count'] != null
              ? int.tryParse(data['relegation_count'].toString()) ?? 0
              : (data['relegated_count'] != null
                    ? int.tryParse(data['relegated_count'].toString()) ?? 0
                    : 0));

    final rawList =
        data['members'] ?? data['standings'] ?? data['leaderboard'] ?? [];
    final List<LeagueGroupMember> membersList = [];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map) {
          membersList.add(
            LeagueGroupMember.fromJson(
              Map<String, dynamic>.from(item),
              currentUserId: currentUserId,
              currentUsername: currentUsername,
            ),
          );
        }
      }
    }

    membersList.sort((a, b) => a.rank.compareTo(b.rank));

    final myRank = data['my_rank'] != null
        ? int.tryParse(data['my_rank'].toString())
        : membersList
              .cast<LeagueGroupMember?>()
              .firstWhere((m) => m?.isMe == true, orElse: () => null)
              ?.rank;

    final myScore = data['my_score'] != null
        ? num.tryParse(data['my_score'].toString())
        : membersList
              .cast<LeagueGroupMember?>()
              .firstWhere((m) => m?.isMe == true, orElse: () => null)
              ?.score;

    DateTime? endsAt;
    if (data['ends_at'] != null) {
      try {
        endsAt = DateTime.parse(data['ends_at'].toString()).toUtc();
      } catch (_) {}
    }

    return LeagueGroupResponse(
      groupId: data['group_id'] ?? data['id'],
      tier: tier,
      promotionCutoff: promo,
      relegationCutoff: releg,
      members: membersList,
      myRank: myRank,
      myScore: myScore,
      endsAt: endsAt,
    );
  }
}

/// Response data model for POST /league/register.
class LeagueRegisterResponse {
  final bool isSuccess;
  final bool isRegistered;
  final int? newBalance;
  final String message;
  final bool alreadyRegistered;

  LeagueRegisterResponse({
    required this.isSuccess,
    required this.isRegistered,
    this.newBalance,
    required this.message,
    this.alreadyRegistered = false,
  });

  factory LeagueRegisterResponse.fromJson(
    Map<String, dynamic> json, {
    int? statusCode,
  }) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final msg = (json['message'] ?? data['message'] ?? '').toString();
    final isAlready =
        statusCode == 409 ||
        msg.toLowerCase().contains('already registered') ||
        data['already_registered'] == true;

    int? balance;
    if (data['wallet_balance'] != null) {
      balance = int.tryParse(data['wallet_balance'].toString());
    } else if (data['new_balance'] != null) {
      balance = int.tryParse(data['new_balance'].toString());
    } else if (data['balance'] != null) {
      balance = int.tryParse(data['balance'].toString());
    } else if (json['wallet_balance'] != null) {
      balance = int.tryParse(json['wallet_balance'].toString());
    }

    final success =
        json['success'] == true ||
        data['success'] == true ||
        statusCode == 200 ||
        statusCode == 201 ||
        isAlready;

    return LeagueRegisterResponse(
      isSuccess: success,
      isRegistered: true,
      newBalance: balance,
      message: msg.isNotEmpty
          ? msg
          : (success ? 'Registered successfully' : 'Registration failed'),
      alreadyRegistered: isAlready,
    );
  }
}
