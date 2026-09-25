import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Enum representing the 6 competitive League Tiers.
enum LeagueTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  master;

  String get id => name;
  String get apiName => name;

  String get displayNameFa {
    switch (this) {
      case LeagueTier.bronze:
        return 'برنز';
      case LeagueTier.silver:
        return 'نقره';
      case LeagueTier.gold:
        return 'طلا';
      case LeagueTier.platinum:
        return 'پلاتینیوم';
      case LeagueTier.diamond:
        return 'الماس';
      case LeagueTier.master:
        return 'مستر';
    }
  }

  String get displayNameEn {
    switch (this) {
      case LeagueTier.bronze:
        return 'Bronze';
      case LeagueTier.silver:
        return 'Silver';
      case LeagueTier.gold:
        return 'Gold';
      case LeagueTier.platinum:
        return 'Platinum';
      case LeagueTier.diamond:
        return 'Diamond';
      case LeagueTier.master:
        return 'Master';
    }
  }

  String get displayNameTr {
    switch (this) {
      case LeagueTier.bronze:
        return 'tier_bronze'.tr;
      case LeagueTier.silver:
        return 'tier_silver'.tr;
      case LeagueTier.gold:
        return 'tier_gold'.tr;
      case LeagueTier.platinum:
        return 'tier_platinum'.tr;
      case LeagueTier.diamond:
        return 'tier_diamond'.tr;
      case LeagueTier.master:
        return 'tier_master'.tr;
    }
  }

  String get leagueTitleFa {
    switch (this) {
      case LeagueTier.bronze:
        return 'لیگ برنز';
      case LeagueTier.silver:
        return 'لیگ نقره‌ای';
      case LeagueTier.gold:
        return 'لیگ طلایی';
      case LeagueTier.platinum:
        return 'لیگ پلاتینیوم';
      case LeagueTier.diamond:
        return 'لیگ الماس';
      case LeagueTier.master:
        return 'لیگ مستر';
    }
  }

  String get leagueTitleEn {
    switch (this) {
      case LeagueTier.bronze:
        return 'Bronze League';
      case LeagueTier.silver:
        return 'Silver League';
      case LeagueTier.gold:
        return 'Gold League';
      case LeagueTier.platinum:
        return 'Platinum League';
      case LeagueTier.diamond:
        return 'Diamond League';
      case LeagueTier.master:
        return 'Master League';
    }
  }

  String get leagueTitleTr {
    switch (this) {
      case LeagueTier.bronze:
        return 'league_bronze'.tr;
      case LeagueTier.silver:
        return 'league_silver'.tr;
      case LeagueTier.gold:
        return 'league_gold'.tr;
      case LeagueTier.platinum:
        return 'league_platinum'.tr;
      case LeagueTier.diamond:
        return 'league_diamond'.tr;
      case LeagueTier.master:
        return 'league_master'.tr;
    }
  }

  Color get color {
    switch (this) {
      case LeagueTier.bronze:
        return const Color(0xFFCD7F32);
      case LeagueTier.silver:
        return const Color(0xFFC0C0C0);
      case LeagueTier.gold:
        return const Color(0xFFFFD700);
      case LeagueTier.platinum:
        return const Color(0xFF00E5FF);
      case LeagueTier.diamond:
        return const Color(0xFFB388FF);
      case LeagueTier.master:
        return const Color(0xFFFF1744);
    }
  }

  IconData get icon {
    switch (this) {
      case LeagueTier.bronze:
      case LeagueTier.silver:
      case LeagueTier.gold:
        return Icons.shield_rounded;
      case LeagueTier.platinum:
      case LeagueTier.diamond:
        return Icons.military_tech_rounded;
      case LeagueTier.master:
        return Icons.workspace_premium_rounded;
    }
  }

  String get assetPath {
    switch (this) {
      case LeagueTier.bronze:
        return 'assets/image/ranks/Bronze.png';
      case LeagueTier.silver:
        return 'assets/image/ranks/Silver.png';
      case LeagueTier.gold:
        return 'assets/image/ranks/Gold.png';
      case LeagueTier.platinum:
        return 'assets/image/ranks/Platinum.png';
      case LeagueTier.diamond:
        return 'assets/image/ranks/Diamond.png';
      case LeagueTier.master:
        return 'assets/image/ranks/Master.png';
    }
  }

  LeagueTier get nextTier {
    final nextIdx = index + 1;
    if (nextIdx < LeagueTier.values.length) {
      return LeagueTier.values[nextIdx];
    }
    return this;
  }

  LeagueTier get previousTier {
    final prevIdx = index - 1;
    if (prevIdx >= 0) {
      return LeagueTier.values[prevIdx];
    }
    return this;
  }

  static LeagueTier fromString(String? val) {
    if (val == null) return LeagueTier.bronze;
    final lower = val.toLowerCase().trim();
    for (final t in LeagueTier.values) {
      if (t.name == lower) return t;
    }
    return LeagueTier.bronze;
  }
}

/// Represents a member in a 50-player League group.
class LeagueGroupMember {
  final int userId;
  final String username;
  final String avatarId;
  final int rank;
  final double totalScore;
  final int attemptsUsed;
  final bool isCurrentUser;

  LeagueGroupMember({
    required this.userId,
    required this.username,
    required this.avatarId,
    required this.rank,
    required this.totalScore,
    this.attemptsUsed = 0,
    this.isCurrentUser = false,
  });

  /// True if in promotion zone (Top 20% => ranks 1-10 in 50-member group)
  bool isPromotionZone(int totalGroupMembers) {
    final top20Count = (totalGroupMembers * 0.20).ceil().clamp(1, 50);
    return rank <= top20Count;
  }

  /// True if in demotion zone (Bottom 15% => ranks 43-50 in 50-member group)
  bool isDemotionZone(int totalGroupMembers) {
    final bottom15Threshold = totalGroupMembers - (totalGroupMembers * 0.15).floor();
    return rank > bottom15Threshold && rank > 10;
  }

  factory LeagueGroupMember.fromJson(Map<String, dynamic> json, {int? currentUserId}) {
    final rawUserId = json['user_id'] ?? json['id'] ?? 0;
    final uId = rawUserId is num ? rawUserId.toInt() : (int.tryParse(rawUserId.toString()) ?? 0);

    final rawRank = json['rank'] ?? 0;
    final rank = rawRank is num ? rawRank.toInt() : (int.tryParse(rawRank.toString()) ?? 0);

    final rawScore = json['total_score'] ?? json['score'] ?? json['final_score'] ?? 0.0;
    final score = rawScore is num ? rawScore.toDouble() : (double.tryParse(rawScore.toString()) ?? 0.0);

    final rawAttempts = json['attempts_used'] ?? 0;
    final attempts = rawAttempts is num ? rawAttempts.toInt() : (int.tryParse(rawAttempts.toString()) ?? 0);

    return LeagueGroupMember(
      userId: uId,
      username: json['username']?.toString() ?? 'Player',
      avatarId: json['avatar_id']?.toString() ?? 'avatar_1',
      rank: rank,
      totalScore: score,
      attemptsUsed: attempts,
      isCurrentUser: currentUserId != null && uId == currentUserId,
    );
  }
}

/// Represents the active League Cycle and user status.
class LeagueCycleStatus {
  final int seasonNumber;
  final LeagueTier currentTier;
  final int groupId;
  final int entryCostCoins; // 150 coins
  final bool isEntered;
  final Map<String, int> freeAttemptsRemaining; // Mode -> remaining attempts
  final int maxFreeAttempts; // 8
  final int extraAttemptsUsed;
  final int extraAttemptCostCoins; // 15 coins
  final DateTime? cycleEndsAt;
  final List<LeagueGroupMember> groupMembers;

  static const List<String> supportedModes = [
    'classic',
    'laser_core',
    'infection',
    'blind_memory',
    'meltdown',
    'crab',
  ];

  static Map<String, int> defaultFreeAttempts({int defaultValue = 8}) => {
    'classic': defaultValue,
    'laser_core': defaultValue,
    'infection': defaultValue,
    'blind_memory': defaultValue,
    'meltdown': defaultValue,
    'crab': defaultValue,
  };

  LeagueCycleStatus({
    required this.seasonNumber,
    required this.currentTier,
    required this.groupId,
    this.entryCostCoins = 150,
    required this.isEntered,
    Map<String, int>? freeAttemptsRemaining,
    this.maxFreeAttempts = 8,
    this.extraAttemptsUsed = 0,
    this.extraAttemptCostCoins = 15,
    this.cycleEndsAt,
    this.groupMembers = const [],
  }) : freeAttemptsRemaining = freeAttemptsRemaining ?? defaultFreeAttempts();

  int getFreeAttempts(String mode) => freeAttemptsRemaining[mode] ?? 0;

  bool canPlayFreeAttemptForMode(String mode) =>
      isEntered && (freeAttemptsRemaining[mode] ?? 0) > 0;

  bool get canPlayFreeAttempt =>
      isEntered && freeAttemptsRemaining.values.any((v) => v > 0);

  factory LeagueCycleStatus.fromJson(Map<String, dynamic> json, {int? currentUserId}) {
    final rawSeason = json['season_number'] ?? json['season'] ?? 1;
    final seasonNumber = rawSeason is num ? rawSeason.toInt() : (int.tryParse(rawSeason.toString()) ?? 1);

    final rawGroup = json['group_id'] ?? 1;
    final groupId = rawGroup is num ? rawGroup.toInt() : (int.tryParse(rawGroup.toString()) ?? 1);

    final defaultMap = defaultFreeAttempts();
    final rawFree = json['free_attempts_remaining'] ?? json['free_attempts'];
    final Map<String, int> freeAttempts = Map.from(defaultMap);

    if (rawFree is Map) {
      rawFree.forEach((key, value) {
        final k = key.toString();
        if (value is num) {
          freeAttempts[k] = value.toInt();
        } else if (value != null) {
          freeAttempts[k] = int.tryParse(value.toString()) ?? 8;
        }
      });
    } else if (rawFree is num) {
      final v = rawFree.toInt();
      for (final k in supportedModes) {
        freeAttempts[k] = v;
      }
    } else if (rawFree != null) {
      final parsed = int.tryParse(rawFree.toString());
      if (parsed != null) {
        for (final k in supportedModes) {
          freeAttempts[k] = parsed;
        }
      }
    }

    final membersJson = (json['group_members'] ?? json['members'] ?? []) as List;
    final members = membersJson
        .map((e) => LeagueGroupMember.fromJson(e, currentUserId: currentUserId))
        .toList();

    return LeagueCycleStatus(
      seasonNumber: seasonNumber,
      currentTier: LeagueTier.fromString(json['tier']?.toString()),
      groupId: groupId,
      entryCostCoins: json['entry_cost'] ?? 150,
      isEntered: json['is_entered'] == true ||
          json['is_entered'] == 1 ||
          json['is_entered'] == 'true' ||
          json['has_entered'] == true ||
          json['user_entered'] == true,
      freeAttemptsRemaining: freeAttempts,
      maxFreeAttempts: json['max_free_attempts'] is num
          ? (json['max_free_attempts'] as num).toInt()
          : 8,
      extraAttemptsUsed: json['extra_attempts_used'] ?? 0,
      extraAttemptCostCoins: json['extra_attempt_cost'] ?? 15,
      cycleEndsAt: json['cycle_ends_at'] != null ? DateTime.tryParse(json['cycle_ends_at'].toString()) : null,
      groupMembers: members,
    );
  }
}
