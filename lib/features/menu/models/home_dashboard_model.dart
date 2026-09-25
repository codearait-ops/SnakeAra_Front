import '../../auth/models/user_model.dart';
import '../../cosmetics/models/cosmetics_models.dart';
import '../../daily_mission/models/daily_mission_model.dart';
import '../../league/models/league_models.dart';
import '../../league/models/league_tier_models.dart';
import '../../wallet/models/wallet_models.dart';

/// Summary of weekly league state returned in Home Dashboard.
class HomeLeagueSummary {
  final int seasonNumber;
  final String tier;
  final int? rank;
  final double finalScore;
  final bool hasActiveRank;
  final bool isEntered;

  HomeLeagueSummary({
    this.seasonNumber = 1,
    this.tier = 'bronze',
    this.rank,
    this.finalScore = 0.0,
    this.hasActiveRank = false,
    this.isEntered = false,
  });

  factory HomeLeagueSummary.fromJson(Map<String, dynamic> json) {
    final rawSeason = json['season_number'] ?? json['season'];
    final seasonNumber = rawSeason is num
        ? rawSeason.toInt()
        : (int.tryParse(rawSeason?.toString() ?? '') ?? 1);

    final rawRank = json['rank'];
    final rank = rawRank is num
        ? rawRank.toInt()
        : int.tryParse(rawRank?.toString() ?? '');

    final rawScore = json['final_score'] ?? json['score'];
    final finalScore = rawScore is num
        ? rawScore.toDouble()
        : (double.tryParse(rawScore?.toString() ?? '') ?? 0.0);

    return HomeLeagueSummary(
      seasonNumber: seasonNumber,
      tier: json['tier']?.toString() ?? 'bronze',
      rank: rank,
      finalScore: finalScore,
      hasActiveRank: json['has_active_rank'] == true,
      isEntered: json['is_entered'] == true,
    );
  }

  /// The parsed [LeagueTier] enum.
  LeagueTier get leagueTier => LeagueTier.fromString(tier);

  /// Convert to [MyRankResponse] to preserve full UI compatibility with existing widgets.
  MyRankResponse toMyRankResponse() {
    return MyRankResponse(
      rank: rank,
      seasonNumber: seasonNumber,
      finalScore: finalScore,
      isInLeague: isEntered,
      breakdown: const [],
    );
  }
}

/// Level progress data returned in Home Dashboard (GET /home/dashboard).
class LevelProgressData {
  final int lastUnlockedLevel;
  final List<int> completedLevels;
  final int totalCompleted;

  LevelProgressData({
    required this.lastUnlockedLevel,
    required this.completedLevels,
    this.totalCompleted = 0,
  });

  factory LevelProgressData.fromJson(Map<String, dynamic> json) {
    final rawUnlocked = json['last_unlocked_level'];
    final lastUnlocked = rawUnlocked is num
        ? rawUnlocked.toInt()
        : (int.tryParse(rawUnlocked?.toString() ?? '') ?? 1);

    final rawCompleted = json['completed_levels'];
    final List<int> completed = [];
    if (rawCompleted is List) {
      for (final item in rawCompleted) {
        if (item is num) {
          completed.add(item.toInt());
        } else if (item != null) {
          final parsed = int.tryParse(item.toString());
          if (parsed != null) completed.add(parsed);
        }
      }
    }

    final rawTotal = json['total_completed'];
    final total = rawTotal is num
        ? rawTotal.toInt()
        : (int.tryParse(rawTotal?.toString() ?? '') ?? completed.length);

    return LevelProgressData(
      lastUnlockedLevel: lastUnlocked,
      completedLevels: completed,
      totalCompleted: total,
    );
  }
}

/// Aggregated response for the Home screen (GET /home/dashboard).
class HomeDashboardResponse {
  final UserModel? user;
  final WalletData? wallet;
  final DailyMissionModel? dailyMission;
  final HomeLeagueSummary? leagueSummary;
  final LevelProgressData? levelProgress;
  final List<CosmeticTheme> availableThemes;
  final List<CosmeticAvatar> availableAvatars;
  final List<CosmeticSnakeSkin> availableSkins;

  HomeDashboardResponse({
    this.user,
    this.wallet,
    this.dailyMission,
    this.leagueSummary,
    this.levelProgress,
    this.availableThemes = const [],
    this.availableAvatars = const [],
    this.availableSkins = const [],
  });

  factory HomeDashboardResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    UserModel? user;
    if (data['user'] != null && data['user'] is Map) {
      user = UserModel.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    }

    WalletData? wallet;
    if (data['wallet'] != null && data['wallet'] is Map) {
      wallet = WalletData.fromJson(
        Map<String, dynamic>.from(data['wallet'] as Map),
      );
    }

    DailyMissionModel? dailyMission;
    if (data['daily_mission'] != null && data['daily_mission'] is Map) {
      dailyMission = DailyMissionModel.fromJson(
        Map<String, dynamic>.from(data['daily_mission'] as Map),
      );
    }

    HomeLeagueSummary? leagueSummary;
    if (data['league_summary'] != null && data['league_summary'] is Map) {
      leagueSummary = HomeLeagueSummary.fromJson(
        Map<String, dynamic>.from(data['league_summary'] as Map),
      );
    }

    LevelProgressData? levelProgress;
    if (data['level_progress'] != null && data['level_progress'] is Map) {
      levelProgress = LevelProgressData.fromJson(
        Map<String, dynamic>.from(data['level_progress'] as Map),
      );
    }

    final rawThemes = data['available_themes'] ?? data['themes'];
    final List<CosmeticTheme> availableThemes = [];
    if (rawThemes is List) {
      for (final item in rawThemes) {
        if (item is Map) {
          availableThemes.add(
            CosmeticTheme.fromDashboardJson(
              item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    final rawAvatars = data['available_avatars'] ?? data['avatars'];
    final List<CosmeticAvatar> availableAvatars = [];
    if (rawAvatars is List) {
      for (final item in rawAvatars) {
        if (item is Map) {
          availableAvatars.add(
            CosmeticAvatar.fromDashboardJson(
              item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    // Parse available_skins from /home/dashboard
    final rawSkins = data['available_skins'] ?? data['skins'];
    final List<CosmeticSnakeSkin> availableSkins = [];
    if (rawSkins is List) {
      for (final item in rawSkins) {
        if (item is Map) {
          availableSkins.add(
            CosmeticSnakeSkin.fromDashboardJson(
              item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return HomeDashboardResponse(
      user: user,
      wallet: wallet,
      dailyMission: dailyMission,
      leagueSummary: leagueSummary,
      levelProgress: levelProgress,
      availableThemes: availableThemes,
      availableAvatars: availableAvatars,
      availableSkins: availableSkins,
    );
  }
}

