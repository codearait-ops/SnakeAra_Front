import 'package:flutter/material.dart';

/// Data models for the Daily Mission system.
class DailyMissionModel {
  final int id;
  final String gameMode;
  final String
  type; // 'eat_count', 'survive_time', 'score_threshold', 'combo_apples'
  final int targetValue;
  final int attemptNumber; // 1 or 2
  final String
  status; // 'pending', 'completed_first_try', 'completed_second_try', 'failed'
  final int? rawStatValue;
  final int rewardCoins;
  final String title;
  final String titleFa;
  final String titleEn;
  final String descriptionFa;
  final String descriptionEn;
  final bool? canPlayServer;
  final bool? canRetryWithAdServer;
  final bool? isCompletedServer;
  final DateTime? closesAt;
  final int? secondsRemaining;
  final int? seed;

  DailyMissionModel({
    required this.id,
    required this.gameMode,
    required this.type,
    required this.targetValue,
    this.attemptNumber = 1,
    this.status = 'pending',
    this.rawStatValue,
    this.rewardCoins = 50,
    this.title = '',
    this.titleFa = '',
    this.titleEn = '',
    this.descriptionFa = '',
    this.descriptionEn = '',
    this.closesAt,
    this.secondsRemaining,
    this.seed,
    this.canPlayServer,
    this.canRetryWithAdServer,
    this.isCompletedServer,
  });

  bool get isCompleted =>
      isCompletedServer == true ||
      status == 'completed_first_try' ||
      status == 'completed_second_try' ||
      status == 'completed' ||
      status.contains('completed');

  bool get isFailed =>
      !isCompleted &&
      ((status == 'failed' && attemptNumber >= 2) ||
          status == 'failed_final' ||
          (canPlayServer == false && canRetryWithAdServer == false));

  bool get canUnlockSecondAttempt =>
      canRetryWithAdServer ??
      (!isCompleted && attemptNumber == 1 && status == 'failed');

  bool get canPlay {
    if (isCompleted || isFailed) return false;
    if (canPlayServer != null && canPlayServer == false) return false;
    if (canUnlockSecondAttempt) return false; // Must unlock 2nd attempt via ad!
    if (status == 'failed') return false;
    return true;
  }

  String localizedTitle(String langCode) {
    final isAbsorbTitle = title.toLowerCase().contains('absorb') ||
        titleEn.toLowerCase().contains('absorb') ||
        titleFa.contains('جذب گوی') ||
        titleFa.contains('گوی‌های انرژی');

    if (isAbsorbTitle ||
        (gameMode.toLowerCase().contains('laser') &&
            (title.isEmpty || isAbsorbTitle))) {
      return langCode == 'fa' ? 'جاخالی از لیزرها' : 'Dodge the Lasers';
    }

    if (langCode == 'fa' && titleFa.isNotEmpty) {
      return titleFa;
    }
    if (titleEn.isNotEmpty) {
      return titleEn;
    }
    return title.isNotEmpty
        ? title
        : (langCode == 'fa' ? 'چالش روزانه' : 'Daily Challenge');
  }

  String localizedDescription(String langCode) {
    if (langCode == 'fa' && descriptionFa.isNotEmpty) {
      if (descriptionFa.contains('گوی') || descriptionFa.contains('انرژی')) {
        if (type == 'eat_count') return '$targetValue سیب در این چالش بخور و از لیزرها جاخالی بده';
        if (type == 'survive_time') return '$targetValue ثانیه زنده بمان و از پرتوها فرار کن';
      }
      return descriptionFa;
    }
    if (descriptionEn.isNotEmpty) {
      if (descriptionEn.toLowerCase().contains('orb') ||
          descriptionEn.toLowerCase().contains('energy')) {
        if (type == 'eat_count') return 'Eat $targetValue apples while dodging laser beams';
        if (type == 'survive_time') return 'Survive for $targetValue seconds dodging lasers';
      }
      return descriptionEn;
    }
    // Fallback automatic description
    if (langCode == 'fa') {
      if (gameMode.toLowerCase().contains('laser')) {
        if (type == 'eat_count') return '$targetValue سیب بخور و از پرتوهای لیزر جاخالی بده';
        if (type == 'survive_time') return '$targetValue ثانیه میان پرتوهای لیزر زنده بمان';
        return '$targetValue امتیاز در هسته لیزری کسب کن';
      }
      if (type == 'eat_count') return '$targetValue سیب در این چالش بخور';
      if (type == 'survive_time') return '$targetValue ثانیه زنده بمان';
      return '$targetValue امتیاز کسب کن';
    } else {
      if (gameMode.toLowerCase().contains('laser')) {
        if (type == 'eat_count') return 'Eat $targetValue apples while dodging laser beams';
        if (type == 'survive_time') return 'Survive for $targetValue seconds dodging lasers';
        return 'Score $targetValue points in Laser Core';
      }
      if (type == 'eat_count')
        return 'Eat $targetValue apples in this challenge';
      if (type == 'survive_time') return 'Survive for $targetValue seconds';
      return 'Score $targetValue points';
    }
  }

  factory DailyMissionModel.fromJson(Map<String, dynamic> json) {
    debugPrint('[DailyMissionModel] 🔍 Parsing fromJson: $json');
    final rawId =
        json['daily_mission_id'] ??
        json['id'] ??
        json['mission_id'] ??
        json['dailyMissionId'] ??
        (json['mission'] is Map
            ? (json['mission']['daily_mission_id'] ?? json['mission']['id'])
            : null) ??
        (json['data'] is Map
            ? (json['data']['daily_mission_id'] ?? json['data']['id'])
            : null);
    final id = rawId is num
        ? rawId.toInt()
        : (int.tryParse(rawId?.toString() ?? '0') ?? 0);
    debugPrint('[DailyMissionModel] 🆔 Parsed ID: $id (rawId: $rawId)');

    final rawTarget = json['target_value'] ?? json['targetValue'] ?? 50;
    final targetValue = rawTarget is num
        ? rawTarget.toInt()
        : (int.tryParse(rawTarget.toString()) ?? 50);

    final rawAttempt = json['attempt_number'] ??
        json['attemptNumber'] ??
        json['attempts_count'] ??
        json['attempts_used'] ??
        json['user_attempt'] ??
        json['attempt'] ??
        1;
    final attemptNumber = rawAttempt is num
        ? rawAttempt.toInt()
        : (int.tryParse(rawAttempt.toString()) ?? 1);

    final rawReward = json['reward_coins'] ??
        json['rewardCoins'] ??
        json['base_coin_reward'] ??
        50;
    final rewardCoins = rawReward is num
        ? rawReward.toInt()
        : (int.tryParse(rawReward.toString()) ?? 50);

    final title = json['title']?.toString() ?? '';
    final titleFa =
        json['title_fa']?.toString() ?? json['titleFa']?.toString() ?? title;
    final titleEn =
        json['title_en']?.toString() ?? json['titleEn']?.toString() ?? title;

    DateTime? parsedClosesAt;
    if (json['closes_at'] != null) {
      parsedClosesAt = DateTime.tryParse(json['closes_at'].toString());
    } else if (json['closesAt'] != null) {
      parsedClosesAt = DateTime.tryParse(json['closesAt'].toString());
    } else if (json['expires_at'] != null) {
      parsedClosesAt = DateTime.tryParse(json['expires_at'].toString());
    }

    int? rawSecs;
    if (json['seconds_remaining'] is num) {
      rawSecs = (json['seconds_remaining'] as num).toInt();
    } else if (json['remaining_seconds'] is num) {
      rawSecs = (json['remaining_seconds'] as num).toInt();
    } else if (json['time_remaining'] is num) {
      rawSecs = (json['time_remaining'] as num).toInt();
    }

    final isCompletedParsed = json['is_completed'] == true ||
        json['isCompleted'] == true ||
        json['completed'] == true;

    final rawStatus = json['mission_status']?.toString() ??
        json['user_status']?.toString() ??
        (json['status'] != null &&
                json['status'] != 'success' &&
                json['status'] != 'ok'
            ? json['status'].toString()
            : null) ??
        json['state']?.toString() ??
        (isCompletedParsed ? 'completed' : 'pending');

    final parsedCanPlay = json['can_play'] is bool
        ? json['can_play'] as bool
        : (json['canPlay'] is bool
            ? json['canPlay'] as bool
            : (json['allowed_to_play'] is bool
                ? json['allowed_to_play'] as bool
                : null));

    final parsedCanRetry = json['can_retry_with_ad'] is bool
        ? json['can_retry_with_ad'] as bool
        : (json['canRetryWithAd'] is bool
            ? json['canRetryWithAd'] as bool
            : (json['can_unlock_second_attempt'] is bool
                ? json['can_unlock_second_attempt'] as bool
                : null));

    return DailyMissionModel(
      id: id,
      gameMode:
          json['game_mode']?.toString() ??
          json['gameMode']?.toString() ??
          'classic',
      type:
          json['type']?.toString() ??
          json['mission_type']?.toString() ??
          'eat_count',
      targetValue: targetValue,
      attemptNumber: attemptNumber,
      status: rawStatus,
      rawStatValue: json['raw_stat_value'] is num
          ? (json['raw_stat_value'] as num).toInt()
          : int.tryParse(json['raw_stat_value']?.toString() ?? ''),
      rewardCoins: rewardCoins,
      title: title,
      titleFa: titleFa,
      titleEn: titleEn,
      descriptionFa:
          json['description_fa']?.toString() ??
          json['descriptionFa']?.toString() ??
          json['description']?.toString() ??
          '',
      descriptionEn:
          json['description_en']?.toString() ??
          json['descriptionEn']?.toString() ??
          '',
      closesAt: parsedClosesAt,
      secondsRemaining: rawSecs,
      seed: json['seed'] is num
          ? (json['seed'] as num).toInt()
          : int.tryParse(json['seed']?.toString() ?? ''),
      canPlayServer: parsedCanPlay,
      canRetryWithAdServer: parsedCanRetry,
      isCompletedServer: isCompletedParsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'game_mode': gameMode,
      'type': type,
      'target_value': targetValue,
      'attempt_number': attemptNumber,
      'status': status,
      'raw_stat_value': rawStatValue,
      'reward_coins': rewardCoins,
      'title': title,
      'title_fa': titleFa,
      'title_en': titleEn,
      'description_fa': descriptionFa,
      'description_en': descriptionEn,
      'closes_at': closesAt?.toIso8601String(),
      'seconds_remaining': secondsRemaining,
      'seed': seed,
      'can_play': canPlayServer,
      'can_retry_with_ad': canRetryWithAdServer,
      'is_completed': isCompletedServer ?? isCompleted,
    };
  }

  DailyMissionModel copyWith({
    int? id,
    String? gameMode,
    String? type,
    int? targetValue,
    int? attemptNumber,
    String? status,
    int? rawStatValue,
    int? rewardCoins,
    String? title,
    String? titleFa,
    String? titleEn,
    String? descriptionFa,
    String? descriptionEn,
    DateTime? closesAt,
    int? secondsRemaining,
    int? seed,
    bool? canPlayServer,
    bool? canRetryWithAdServer,
    bool? isCompletedServer,
  }) {
    return DailyMissionModel(
      id: id ?? this.id,
      gameMode: gameMode ?? this.gameMode,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      status: status ?? this.status,
      rawStatValue: rawStatValue ?? this.rawStatValue,
      rewardCoins: rewardCoins ?? this.rewardCoins,
      title: title ?? this.title,
      titleFa: titleFa ?? this.titleFa,
      titleEn: titleEn ?? this.titleEn,
      descriptionFa: descriptionFa ?? this.descriptionFa,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      closesAt: closesAt ?? this.closesAt,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      seed: seed ?? this.seed,
      canPlayServer: canPlayServer ?? this.canPlayServer,
      canRetryWithAdServer: canRetryWithAdServer ?? this.canRetryWithAdServer,
      isCompletedServer: isCompletedServer ?? this.isCompletedServer,
    );
  }
}

/// Response returned from POST /api/daily-mission/submit
class DailyMissionSubmitResponse {
  final bool isSuccess;
  final bool isCompleted;
  final String status;
  final int rewardCoins;
  final int attemptNumber;
  final bool canRetryWithAd;
  final String? message;

  DailyMissionSubmitResponse({
    required this.isSuccess,
    required this.isCompleted,
    required this.status,
    required this.rewardCoins,
    this.attemptNumber = 1,
    this.canRetryWithAd = false,
    this.message,
  });

  factory DailyMissionSubmitResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString() ?? 'failed';
    final isCompleted =
        json['completed'] == true ||
        json['is_completed'] == true ||
        status.contains('completed');

    final rawReward =
        json['coins_earned'] ?? json['reward_coins'] ?? json['rewardCoins'] ?? json['coins_awarded'];
    int rewardCoins = 0;
    if (rawReward is num) {
      rewardCoins = rawReward.toInt();
    } else if (rawReward is Map) {
      final total = rawReward['total'] ?? rawReward['amount'] ?? rawReward['coins'];
      if (total is num) {
        rewardCoins = total.toInt();
      } else if (total != null) {
        rewardCoins = int.tryParse(total.toString()) ?? 0;
      }
    } else if (rawReward != null) {
      rewardCoins = int.tryParse(rawReward.toString()) ?? 0;
    }

    final rawAttempt = json['attempt_number'] ?? json['attemptNumber'] ?? 1;
    final attemptNumber = rawAttempt is num
        ? rawAttempt.toInt()
        : (int.tryParse(rawAttempt.toString()) ?? 1);

    final canRetryWithAd = json['can_retry_with_ad'] == true ||
        json['canRetryWithAd'] == true;

    return DailyMissionSubmitResponse(
      isSuccess: json['success'] == true ||
          json['is_success'] == true ||
          status != 'error',
      isCompleted: isCompleted,
      status: status,
      rewardCoins: rewardCoins,
      attemptNumber: attemptNumber,
      canRetryWithAd: canRetryWithAd,
      message: json['message']?.toString(),
    );
  }
}
