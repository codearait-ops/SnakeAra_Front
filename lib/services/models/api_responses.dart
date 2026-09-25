import '../../features/profile/models/xp_reward_model.dart';

/// Response payload from starting a game session.
class StartSessionResponse {
  final bool isSuccess;
  final String? sessionId;
  final DateTime? expiresAt;
  final String? error;
  final int? seed;
  final int? speedLevel;
  final Map<String, dynamic>? modeConfig;
  final int? attemptsRemaining;
  final bool? canPlay;
  final bool isSessionExpired;

  StartSessionResponse({
    required this.isSuccess,
    this.sessionId,
    this.expiresAt,
    this.error,
    this.seed,
    this.speedLevel,
    this.modeConfig,
    this.attemptsRemaining,
    this.canPlay,
    this.isSessionExpired = false,
  });
}

/// Score submission result for weekend league participation.
class LeagueScoreResult {
  final bool isEligible;
  final int seasonNumber;
  final double finalScore;
  final int? rank;
  final int daysRemaining;
  final double? modeLeaguePoints;
  final int? modeBestValue;
  final bool isNewModeRecord;
  final double diversityMultiplier;

  LeagueScoreResult({
    required this.isEligible,
    required this.seasonNumber,
    required this.finalScore,
    this.rank,
    this.daysRemaining = 0,
    this.modeLeaguePoints,
    this.modeBestValue,
    this.isNewModeRecord = false,
    this.diversityMultiplier = 1.0,
  });

  factory LeagueScoreResult.fromJson(Map<String, dynamic> json) {
    return LeagueScoreResult(
      isEligible: json['is_eligible'] == true,
      seasonNumber:
          (json['season_number'] as num?)?.toInt() ??
          (json['season'] as num?)?.toInt() ??
          1,
      finalScore:
          (json['final_score'] as num?)?.toDouble() ??
          (json['total_score'] as num?)?.toDouble() ??
          0.0,
      rank:
          (json['rank'] as num?)?.toInt() ?? (json['my_rank'] as num?)?.toInt(),
      daysRemaining: (json['days_remaining'] as num?)?.toInt() ?? 0,
      modeLeaguePoints:
          (json['mode_league_points'] as num?)?.toDouble() ??
          (json['mode_score'] as num?)?.toDouble() ??
          (json['normalized_score'] as num?)?.toDouble(),
      modeBestValue:
          (json['mode_best_value'] as num?)?.toInt() ??
          (json['best_value'] as num?)?.toInt(),
      isNewModeRecord:
          json['is_new_mode_record'] == true || json['is_new_record'] == true,
      diversityMultiplier:
          (json['diversity_multiplier'] as num?)?.toDouble() ??
          (json['diversity_mul'] as num?)?.toDouble() ??
          1.0,
    );
  }
}

/// Unified response from submitting a final game score.
class SubmitScoreResponse {
  final bool isSuccess;
  final bool isRejected; // 422
  final bool isSessionExpired; // 404, 410, 401, 403
  final bool isNetworkError;
  final String? message;
  final bool isNewHighscore;
  final bool leagueRankImproved;
  final XpReward? xp;
  final LeagueScoreResult? league;
  final int? levelId;

  // Daily Challenge fields
  final int? attemptNumber;
  final int? attemptsUsed;
  final bool? canRetry;
  final int? bestValue;
  final int? rank;

  // Coin & Balance fields for Casual Missions & Level Rewards
  final bool? coinAwarded;
  final int? coinsAwarded;
  final int? newBalance;

  // League Attempts fields
  final int? attemptsRemaining;
  final int? seasonNumber;
  final String? rejectionReason;

  SubmitScoreResponse({
    this.isSuccess = false,
    this.isRejected = false,
    this.isSessionExpired = false,
    this.isNetworkError = false,
    this.message,
    this.isNewHighscore = false,
    this.leagueRankImproved = false,
    this.xp,
    this.league,
    this.levelId,
    this.attemptNumber,
    this.attemptsUsed,
    this.canRetry,
    this.bestValue,
    this.rank,
    this.coinAwarded,
    this.coinsAwarded,
    this.newBalance,
    this.attemptsRemaining,
    this.seasonNumber,
    this.rejectionReason,
  });
}

/// Generic API response wrapper.
class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse.success(this.data, {this.message, this.statusCode = 200})
    : isSuccess = true;
  ApiResponse.error(this.message, {this.statusCode})
    : isSuccess = false,
      data = null;

  /// Convenience getter / alias for message
  String? get errorMessage => message;
}
