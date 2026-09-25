import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:snake_game/features/profile/models/xp_reward_model.dart';
import '../app/core/constants/app_constants.dart';
import '../app/core/utils/hmac_utils.dart';
import '../features/league/models/league_models.dart';
import '../features/league/models/league_tier_models.dart';
import '../features/league/models/league_dashboard_model.dart';
import '../features/hall_of_fame/models/hall_of_fame_models.dart';
import '../features/league/models/weekend_league_models.dart';
import '../features/league/models/league_player_summary_model.dart';
import 'api_service.dart';

class LeagueApiService extends GetxService {
  String baseUrl = kBaseUrl;
  Dio get _dio => Get.find<ApiService>().dio;

  @override
  void onInit() {
    super.onInit();
  }

  String _parseError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out';
    }

    if (e.response != null && e.response!.data != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }

    return e.message ?? 'Unknown error';
  }

  // ===========================================================================
  // WEEKEND LEAGUE SYSTEM (FRONTEND SPEC V1)
  // ===========================================================================

  /// Fetch season phase, timers, cost, and registration status (GET /league/status)
  Future<ApiResponse<LeagueSeasonStatus>> getLeagueStatus({
    String? token,
  }) async {
    final hasToken = token != null && token.isNotEmpty;
    debugPrint(
      '🌐 [LeagueApiService] GET /league/status (auth: ${hasToken ? 'Bearer ***' : 'none'})',
    );
    try {
      final options = hasToken
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;
      final response = await _dio.get('/league/status', options: options);
      debugPrint(
        '🌐 [LeagueApiService] GET /league/status => ${response.statusCode} | ${response.data}',
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] is Map<String, dynamic>
            ? response.data['data'] as Map<String, dynamic>
            : (response.data is Map<String, dynamic>
                  ? response.data as Map<String, dynamic>
                  : Map<String, dynamic>.from(response.data as Map));
        return ApiResponse.success(LeagueSeasonStatus.fromJson(data));
      }
      return ApiResponse.error(
        response.data?['message']?.toString() ?? 'Failed to load league status',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      debugPrint(
        '❌ [LeagueApiService] DioException in GET /league/status: ${e.message} | ${e.response?.data}',
      );
      return ApiResponse.error(
        _parseError(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e, stack) {
      debugPrint(
        '💥 [LeagueApiService] Exception in GET /league/status: $e\n$stack',
      );
      return ApiResponse.error(e.toString());
    }
  }

  /// Register current player for the upcoming weekend league (POST /league/register)
  Future<ApiResponse<LeagueRegisterResponse>> registerForLeague({
    required String token,
  }) async {
    debugPrint('🌐 [LeagueApiService] POST /league/register');
    try {
      final response = await _dio.post(
        '/league/register',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      debugPrint(
        '🌐 [LeagueApiService] POST /league/register => ${response.statusCode} | ${response.data}',
      );
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : (response.data is Map
                ? Map<String, dynamic>.from(response.data as Map)
                : <String, dynamic>{});
      final parsed = LeagueRegisterResponse.fromJson(
        data,
        statusCode: response.statusCode,
      );
      return ApiResponse.success(parsed, statusCode: response.statusCode);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      debugPrint(
        '⚠️ [LeagueApiService] DioException in POST /league/register: status=$status | ${e.response?.data}',
      );
      // Handle 409 or "already registered" response idempotently as success
      if (status == 409 ||
          (e.response?.data is Map &&
              (e.response?.data['message']?.toString().toLowerCase().contains(
                        'already',
                      ) ==
                      true ||
                  e.response?.data['already_registered'] == true))) {
        debugPrint(
          'ℹ️ [LeagueApiService] Interpreted 409/already_registered as idempotent success',
        );
        final data = e.response?.data is Map
            ? Map<String, dynamic>.from(e.response!.data as Map)
            : <String, dynamic>{};
        final parsed = LeagueRegisterResponse.fromJson(data, statusCode: 409);
        return ApiResponse.success(parsed, statusCode: 200);
      }
      return ApiResponse.error(_parseError(e), statusCode: status);
    } catch (e, stack) {
      debugPrint(
        '💥 [LeagueApiService] Exception in POST /league/register: $e\n$stack',
      );
      return ApiResponse.error(e.toString());
    }
  }

  /// Toggle auto-enrollment for future weekend leagues (POST /league/auto-enroll/toggle)
  Future<ApiResponse<bool>> toggleAutoEnroll({
    required String token,
    required bool enabled,
  }) async {
    debugPrint(
      '🌐 [LeagueApiService] POST /league/auto-enroll/toggle (enabled: $enabled)',
    );
    try {
      final response = await _dio.post(
        '/league/auto-enroll/toggle',
        data: {'enabled': enabled, 'auto_enroll': enabled},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      debugPrint(
        '🌐 [LeagueApiService] POST /league/auto-enroll/toggle => ${response.statusCode} | ${response.data}',
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        bool newStatus = enabled;
        if (data is Map) {
          if (data['auto_enroll'] != null) {
            newStatus = data['auto_enroll'] == true;
          } else if (data['enabled'] != null) {
            newStatus = data['enabled'] == true;
          } else if (data['data'] is Map &&
              data['data']['auto_enroll'] != null) {
            newStatus = data['data']['auto_enroll'] == true;
          }
        }
        return ApiResponse.success(newStatus, statusCode: response.statusCode);
      }
      return ApiResponse.error(
        response.data?['message']?.toString() ?? 'Failed to toggle auto-enroll',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      debugPrint(
        '❌ [LeagueApiService] DioException in toggleAutoEnroll: ${e.message} | ${e.response?.data}',
      );
      return ApiResponse.error(
        _parseError(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e, stack) {
      debugPrint(
        '💥 [LeagueApiService] Exception in toggleAutoEnroll: $e\n$stack',
      );
      return ApiResponse.error(e.toString());
    }
  }

  /// Fetch live leaderboard and promotion/relegation cutoffs for current user's group (GET /league/group)
  Future<ApiResponse<LeagueGroupResponse>> getLeagueGroup({
    required String token,
    int? currentUserId,
    String? currentUsername,
  }) async {
    debugPrint(
      '🌐 [LeagueApiService] GET /league/group (userId: $currentUserId, username: $currentUsername)',
    );
    try {
      final response = await _dio.get(
        '/league/group',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      debugPrint(
        '🌐 [LeagueApiService] GET /league/group => ${response.statusCode} | (members: ${(response.data is Map && response.data['data'] is Map) ? (response.data['data']['members'] as List?)?.length : 'N/A'})',
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] is Map<String, dynamic>
            ? response.data['data'] as Map<String, dynamic>
            : (response.data is Map<String, dynamic>
                  ? response.data as Map<String, dynamic>
                  : Map<String, dynamic>.from(response.data as Map));
        final parsed = LeagueGroupResponse.fromJson(
          data,
          currentUserId: currentUserId,
          currentUsername: currentUsername,
        );
        return ApiResponse.success(parsed, statusCode: response.statusCode);
      }
      return ApiResponse.error(
        response.data?['message']?.toString() ?? 'Failed to load league group',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      debugPrint(
        '❌ [LeagueApiService] DioException in GET /league/group: ${e.message} | ${e.response?.data}',
      );
      return ApiResponse.error(
        _parseError(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e, stack) {
      debugPrint(
        '💥 [LeagueApiService] Exception in GET /league/group: $e\n$stack',
      );
      return ApiResponse.error(e.toString());
    }
  }


  /// Fetch player summary in a league/season (GET /league/season/{seasonId}/player/{userId} or GET /league/player/{userId}/summary)
  Future<ApiResponse<LeaguePlayerSummary>> getLeaguePlayerSummary({
    required int userId,
    int? seasonId,
    String? token,
  }) async {
    final path = (seasonId != null && seasonId > 0)
        ? '/league/season/$seasonId/player/$userId'
        : '/league/player/$userId/summary';
    debugPrint('🌐 [LeagueApiService] GET $path');
    try {
      final options = (token != null && token.isNotEmpty)
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;
      final response = await _dio.get(path, options: options);
      debugPrint('🌐 [LeagueApiService] GET $path => ${response.statusCode} | ${response.data}');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : (response.data is Map
                ? Map<String, dynamic>.from(response.data as Map)
                : <String, dynamic>{});
        return ApiResponse.success(
          LeaguePlayerSummary.fromJson(data),
          statusCode: response.statusCode,
        );
      }
      return ApiResponse.error(
        response.data?['message']?.toString() ?? 'Failed to load league player summary',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      debugPrint('❌ [LeagueApiService] DioException in GET $path: ${e.message} | ${e.response?.data}');
      return ApiResponse.error(
        _parseError(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e, stack) {
      debugPrint('💥 [LeagueApiService] Exception in GET $path: $e\n$stack');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<List<HallOfFameEntry>>> getHallOfFame() async {
    try {
      print('--- [DEBUG] getHallOfFame Request ---');
      print('URL: $baseUrl/hall-of-fame');

      final response = await _dio.get('/hall-of-fame');

      print('--- [DEBUG] getHallOfFame Response ---');
      print('Status Code: ${response.statusCode}');
      print('Data: ${response.data}');

      if (response.statusCode == 200 && response.data['data'] != null) {
        final list = (response.data['data'] as List)
            .map((e) => HallOfFameEntry.fromJson(e))
            .toList();
        return ApiResponse.success(list);
      }
      return ApiResponse.error('Failed to load hall of fame');
    } on DioException catch (e) {
      print('--- [DEBUG] getHallOfFame DioException ---');
      print('Message: ${e.message}');
      print('Response status: ${e.response?.statusCode}');
      return ApiResponse.error(_parseError(e));
    } catch (e) {
      print('--- [DEBUG] getHallOfFame Exception ---');
      print('Error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<SeasonDetail>> getSeasonDetail(int seasonNumber) async {
    try {
      print('--- [DEBUG] getSeasonDetail Request ---');
      print('URL: $baseUrl/league/season/$seasonNumber/detail');

      final response = await _dio.get('/league/season/$seasonNumber/detail');

      print('--- [DEBUG] getSeasonDetail Response ---');
      print('Status Code: ${response.statusCode}');
      print('Data: ${response.data}');

      if (response.statusCode == 200 && response.data['data'] != null) {
        return ApiResponse.success(
          SeasonDetail.fromJson(response.data['data']),
        );
      }
      return ApiResponse.error('Failed to load season detail');
    } on DioException catch (e) {
      print('--- [DEBUG] getSeasonDetail DioException ---');
      print('Message: ${e.message}');
      print('Response status: ${e.response?.statusCode}');
      return ApiResponse.error(_parseError(e));
    } catch (e) {
      print('--- [DEBUG] getSeasonDetail Exception ---');
      print('Error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<List<PlayerMedal>>> getPlayerMedals(
    String playerId,
  ) async {
    try {
      print('--- [DEBUG] getPlayerMedals Request ---');
      print('URL: $baseUrl/league/player/$playerId/medals');

      final response = await _dio.get('/league/player/$playerId/medals');

      print('--- [DEBUG] getPlayerMedals Response ---');
      print('Status Code: ${response.statusCode}');
      print('Data: ${response.data}');

      if (response.statusCode == 200 && response.data['data'] != null) {
        final list = (response.data['data'] as List)
            .map((e) => PlayerMedal.fromJson(e))
            .toList();
        return ApiResponse.success(list);
      }
      return ApiResponse.error('Failed to load player medals');
    } on DioException catch (e) {
      print('--- [DEBUG] getPlayerMedals DioException ---');
      print('Message: ${e.message}');
      print('Response status: ${e.response?.statusCode}');
      return ApiResponse.error(_parseError(e));
    } catch (e) {
      print('--- [DEBUG] getPlayerMedals Exception ---');
      print('Error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  /// Fetch user's weekly league history (GET /league/history)
  Future<ApiResponse<List<LeagueHistoryEntry>>> getMyLeagueHistory(
    String token,
  ) async {
    try {
      debugPrint('🌐 [LeagueApiService] GET /league/history');
      final response = await _dio.get(
        '/league/history',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      debugPrint(
        '🌐 [LeagueApiService] GET /league/history => ${response.statusCode} | ${response.data}',
      );

      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data;
        List<dynamic> listData = [];
        if (rawData is List) {
          listData = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          listData = rawData['data'] as List;
        } else if (rawData is Map && rawData['history'] is List) {
          listData = rawData['history'] as List;
        }
        final list = listData
            .whereType<Map>()
            .map((e) => LeagueHistoryEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return ApiResponse.success(list, statusCode: response.statusCode);
      }
      return ApiResponse.error(
        response.data?['message']?.toString() ?? 'Failed to load league history',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      debugPrint(
        '❌ [LeagueApiService] DioException in GET /league/history: ${e.message} | ${e.response?.data}',
      );
      return ApiResponse.error(
        _parseError(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e, stack) {
      debugPrint(
        '💥 [LeagueApiService] Exception in GET /league/history: $e\n$stack',
      );
      return ApiResponse.error(e.toString());
    }
  }

  // ===========================================================================
  // TIER & 50-MEMBER GROUP & ATTEMPT METHODS
  // ===========================================================================

  /// Fetch active League Cycle status and 50-member group standings
  Future<ApiResponse<LeagueCycleStatus>> getLeagueCycleStatus({
    required String token,
    int? currentUserId,
  }) async {
    try {
      final response = await _dio.get(
        '/league/cycle-status',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        final cycleJson = data['cycle'] ?? data['data'] ?? data;
        return ApiResponse.success(
          LeagueCycleStatus.fromJson(cycleJson, currentUserId: currentUserId),
        );
      }
      return ApiResponse.error(
        data?['message'] ?? 'Failed to load league cycle status',
      );
    } on DioException catch (e) {
      return ApiResponse.error(_parseError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }



  /// Fetch league attempts status for a specific mode (GET /api/league/attempts/{mode})
  Future<ApiResponse<Map<String, dynamic>>> getLeagueAttempts({
    required String mode,
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        '/league/attempts/$mode',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        final resData = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data);
        return ApiResponse.success(resData);
      }
      return ApiResponse.error(data?['message'] ?? 'Failed to load attempts');
    } on DioException catch (e) {
      return ApiResponse.error(_parseError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Unlock an extra league attempt (POST /api/league/extra-attempt)
  /// [gameMode]: 'classic', 'laser_core', 'infection', 'blind_memory', 'meltdown'
  /// [type]: 'ad' or 'coins'
  Future<ApiResponse<bool>> unlockExtraAttempt({
    required String token,
    required String gameMode,
    String type = 'ad',
  }) async {
    try {
      final response = await _dio.post(
        '/league/extra-attempt',
        data: {'game_mode': gameMode, 'type': type},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        return ApiResponse.success(
          data['success'] == true || data['status'] == 'success',
        );
      }
      return ApiResponse.error(
        data?['message'] ?? 'Failed to unlock extra attempt',
      );
    } on DioException catch (e) {
      return ApiResponse.error(_parseError(e));
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Unlock extra attempt via ad
  Future<ApiResponse<bool>> unlockExtraAttemptViaAd({
    required String token,
    required String gameMode,
  }) => unlockExtraAttempt(token: token, gameMode: gameMode, type: 'ad');

  /// Unlock extra attempt via coins (15 coins)
  Future<ApiResponse<bool>> unlockExtraAttemptViaCoins({
    required String token,
    required String gameMode,
  }) => unlockExtraAttempt(token: token, gameMode: gameMode, type: 'coins');

  // ===========================================================================
  // DEDICATED LEAGUE SCORE SUBMISSION (POST /api/league/score/submit)
  // ===========================================================================

  /// Submit League Score (Dedicated League endpoint: POST /league/score/submit)
  /// Completely separated from casual score submissions.
  Future<SubmitScoreResponse> submitLeagueScore({
    required String sessionId,
    required String gameMode,
    required int value,
    required List<Map<String, dynamic>> events,
    required String token,
    String? userId,
    String? hmacSignature,
  }) async {
    try {
      final signature = hmacSignature ??
          (userId != null && userId.isNotEmpty
              ? HmacUtils.generateScoreSignature(
                  gameMode: gameMode,
                  value: value,
                  userId: userId,
                )
              : null);

      print('--- [LeagueApiService] submitLeagueScore REQUEST ---');
      print('Endpoint: /league/score/submit');
      print('Session ID: $sessionId, Mode: $gameMode, Value: $value');
      print('Events Count: ${events.length}');
      print('HMAC Signature: $signature');

      final payloadData = <String, dynamic>{
        'session_id': sessionId,
        'game_mode': gameMode,
        'value': value,
        'events': events,
      };
      if (signature != null) {
        payloadData['hmac_signature'] = signature;
      }

      final response = await _dio.post(
        '/league/score/submit',
        data: payloadData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('--- [LeagueApiService] submitLeagueScore RESPONSE ---');
      print('Status Code: ${response.statusCode}');
      print('Data: ${response.data}');

      final data = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final isNewHighscore =
            data['is_new_highscore'] == true || data['is_new_record'] == true;
        final leagueRankImproved = data['league_rank_improved'] == true;

        XpReward? xpReward;
        if (data is Map && data['xp'] != null) {
          if (data['xp'] is Map<String, dynamic>) {
            xpReward = XpReward.fromJson(data['xp']);
          } else if (data['xp'] is Map) {
            xpReward = XpReward.fromJson(Map<String, dynamic>.from(data['xp']));
          }
        }

        LeagueScoreResult? leagueResult;
        if (data is Map && data['league'] != null) {
          if (data['league'] is Map<String, dynamic>) {
            leagueResult = LeagueScoreResult.fromJson(data['league']);
          } else if (data['league'] is Map) {
            leagueResult = LeagueScoreResult.fromJson(
              Map<String, dynamic>.from(data['league']),
            );
          }
        } else if (data is Map &&
            (data['final_score'] != null || data['rank'] != null)) {
          leagueResult = LeagueScoreResult.fromJson(
            Map<String, dynamic>.from(data),
          );
        }

        int? coinsAwarded;
        if (data is Map) {
          if (data['coins_earned'] != null) {
            coinsAwarded = ApiService.parseCoins(data['coins_earned']);
          } else if (data['coins_awarded'] != null) {
            coinsAwarded = ApiService.parseCoins(data['coins_awarded']);
          } else if (data['reward_coins'] != null) {
            coinsAwarded = ApiService.parseCoins(data['reward_coins']);
          } else if (data['coins'] != null) {
            coinsAwarded = ApiService.parseCoins(data['coins']);
          }
        }

        int? newBalance;
        if (data is Map) {
          if (data['wallet_balance'] != null) {
            newBalance = ApiService.parseBalance(data['wallet_balance']);
          } else if (data['new_balance'] != null) {
            newBalance = ApiService.parseBalance(data['new_balance']);
          } else if (data['balance'] != null) {
            newBalance = ApiService.parseBalance(data['balance']);
          } else if (data['user_balance'] != null) {
            newBalance = ApiService.parseBalance(data['user_balance']);
          }
        }

        bool? coinAwarded;
        if (data is Map && data['coin_awarded'] != null) {
          coinAwarded = data['coin_awarded'] == true;
        }

        int? attemptsRemaining;
        bool? canRetry;
        if (data is Map && data['attempts'] is Map) {
          final att = data['attempts'];
          attemptsRemaining = ApiService.parseInt(att['attempts_remaining']);
          canRetry = att['can_play'] == true ||
              (attemptsRemaining != null && attemptsRemaining > 0);
        }

        return SubmitScoreResponse(
          isSuccess: true,
          message: data['message'] ?? 'League score submitted successfully',
          isNewHighscore: isNewHighscore,
          leagueRankImproved: leagueRankImproved,
          xp: xpReward,
          league: leagueResult,
          rank: ApiService.parseInt(data['rank'] ?? data['my_rank']),
          coinAwarded: coinAwarded,
          coinsAwarded: coinsAwarded,
          newBalance: newBalance,
          attemptsRemaining: attemptsRemaining,
          canRetry: canRetry,
        );
      }
      return SubmitScoreResponse(
        isNetworkError: true,
        message: 'Unexpected status code: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print(
        '--- [LeagueApiService] submitLeagueScore DioException: ${e.message} ---',
      );
      print('Status Code: ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
      final status = e.response?.statusCode;
      if (status == 422) {
        final serverMessage = e.response?.data is Map
            ? e.response?.data['message']?.toString()
            : null;
        return SubmitScoreResponse(
          isRejected: true,
          message: serverMessage ?? 'Invalid score payload',
        );
      } else if (status == 404 ||
          status == 410 ||
          status == 401 ||
          status == 403) {
        return SubmitScoreResponse(
          isSessionExpired: true,
          message: 'Session expired',
        );
      }
      return SubmitScoreResponse(isNetworkError: true, message: e.message);
    } catch (e) {
      return SubmitScoreResponse(isNetworkError: true, message: e.toString());
    }
  }

  /// Fetch aggregated League dashboard data (GET /league/dashboard)
  Future<ApiResponse<LeagueDashboardResponse>> getLeagueDashboard({
    String? token,
  }) async {
    try {
      print('--- [DEBUG] getLeagueDashboard Request ---');
      print(
        'URL: $baseUrl/league/dashboard | Token: ${token != null && token.isNotEmpty ? 'Bearer ***' : 'none'}',
      );

      final options = token != null && token.isNotEmpty
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;

      final response = await _dio.get('/league/dashboard', options: options);

      print('--- [DEBUG] getLeagueDashboard Response ---');
      print('Status Code: ${response.statusCode}');
      print('Data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
        final res = LeagueDashboardResponse.fromJson(data);
        return ApiResponse.success(res, statusCode: response.statusCode);
      }
      return ApiResponse.error(
        response.data?['message'] ?? 'Failed to load league dashboard',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      print('--- [DEBUG] getLeagueDashboard DioException ---');
      print('Message: ${e.message}');
      return ApiResponse.error(
        _parseError(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Fetch aggregated Hall of Fame bundle with optional tier parameter (GET /hall-of-fame/bundle)
  Future<ApiResponse<HallOfFameBundleResponse>> getHallOfFameBundle({
    String? tier,
  }) async {
    try {
      print('--- [DEBUG] getHallOfFameBundle Request ---');
      print('URL: $baseUrl/hall-of-fame/bundle?tier=$tier');

      final queryParams = <String, dynamic>{};
      if (tier != null && tier.isNotEmpty && tier.toLowerCase() != 'all') {
        queryParams['tier'] = tier;
      }

      final response = await _dio.get(
        '/hall-of-fame/bundle',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('--- [DEBUG] getHallOfFameBundle Response ---');
      print('Status Code: ${response.statusCode}');
      print('Data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
        final res = HallOfFameBundleResponse.fromJson(data);
        return ApiResponse.success(res, statusCode: response.statusCode);
      }
      return ApiResponse.error(
        response.data?['message'] ?? 'Failed to load Hall of Fame bundle',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      print('--- [DEBUG] getHallOfFameBundle DioException ---');
      print('Message: ${e.message}');
      return ApiResponse.error(
        _parseError(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
