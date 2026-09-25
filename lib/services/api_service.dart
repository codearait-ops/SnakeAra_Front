import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import '../app/core/constants/app_constants.dart';
import '../app/core/utils/hmac_utils.dart';
import '../features/auth/models/user_model.dart';
import '../features/daily_mission/models/daily_mission_model.dart';
import '../features/wallet/models/wallet_models.dart';
import '../features/leaderboard/models/online_leaderboard_entry.dart';
import '../features/leaderboard/models/game_mode_leaderboard_entry.dart';
import '../features/leaderboard/models/league_leaderboard_entry.dart';
import '../features/profile/models/universal_player_profile.dart';
import '../features/profile/models/xp_reward_model.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/menu/models/home_dashboard_model.dart';
import '../features/profile/models/profile_full_model.dart';
import '../features/cosmetics/models/cosmetics_models.dart';
import 'models/api_responses.dart';
import 'api/api_error_parser.dart';
import 'api/auth_api.dart';
import 'api/dashboard_api.dart';
import 'api/leaderboard_api.dart';
import 'api/missions_api.dart';
import 'api/shop_api.dart';
import 'api/wallet_api.dart';

export 'models/api_responses.dart';

/// Central API Service acting as a Facade over modular domain API delegates.
///
/// Direct callers (15+ across the codebase) continue to use `Get.find<ApiService>().xyz()`
/// with 100% backward-compatible method signatures, while domain logic lives in
/// `AuthApi`, `WalletApi`, `ShopApi`, `LeaderboardApi`, `MissionsApi`, and `DashboardApi`.
class ApiService extends GetxService {
  String baseUrl = kBaseUrl;
  late final Dio _dio;

  late final AuthApi _authApi;
  late final WalletApi _walletApi;
  late final ShopApi _shopApi;
  late final LeaderboardApi _leaderboardApi;
  late final MissionsApi _missionsApi;
  late final DashboardApi _dashboardApi;

  Dio get dio => _dio;
  AuthApi get authApi => _authApi;
  WalletApi get walletApi => _walletApi;
  ShopApi get shopApi => _shopApi;
  LeaderboardApi get leaderboardApi => _leaderboardApi;
  MissionsApi get missionsApi => _missionsApi;
  DashboardApi get dashboardApi => _dashboardApi;

  /// Safely parses coins which might be num, Map (e.g. {total: 0, breakdown: []}), or String
  static int? parseCoins(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toInt();
    if (raw is Map) {
      final total = raw['total'] ?? raw['amount'] ?? raw['coins'];
      if (total is num) return total.toInt();
      if (total != null) return int.tryParse(total.toString());
      return null;
    }
    return int.tryParse(raw.toString());
  }

  /// Safely parses wallet balance which might be num, Map, or String
  static int? parseBalance(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toInt();
    if (raw is Map) {
      final balance = raw['balance'] ?? raw['total'] ?? raw['wallet_balance'];
      if (balance is num) return balance.toInt();
      if (balance != null) return int.tryParse(balance.toString());
      return null;
    }
    return int.tryParse(raw.toString());
  }

  /// Safely parses an integer from any dynamic numeric or string value
  static int? parseInt(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) {
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            final path = error.requestOptions.path;
            final authHeader = error.requestOptions.headers['Authorization']?.toString();
            final hasBearerToken = authHeader != null &&
                authHeader.trim().startsWith('Bearer ') &&
                authHeader.trim() != 'Bearer' &&
                authHeader.trim() != 'Bearer null' &&
                authHeader.trim() != 'Bearer undefined';

            // Only auto-expire session if the request actually sent an Authorization Bearer token
            // and it's not an authentication attempt endpoint (login/register).
            if (hasBearerToken && !path.contains('/login') && !path.contains('/register')) {
              if (Get.isRegistered<AuthController>()) {
                final auth = Get.find<AuthController>();
                if (auth.isLoggedIn.value) {
                  debugPrint(
                    '[ApiService] ⚠️ Received 401 Unauthorized on $path with active token. Auto-expiring user session.',
                  );
                  auth.handleSessionExpired(showNotice: true);
                }
              }
            }
          }
          return handler.next(error);
        },
      ),
    );

    _authApi = AuthApi(_dio);
    _walletApi = WalletApi(_dio);
    _shopApi = ShopApi(_dio);
    _leaderboardApi = LeaderboardApi(_dio);
    _missionsApi = MissionsApi(_dio);
    _dashboardApi = DashboardApi(_dio);
  }

  // ===========================================================================
  // AUTH DELEGATES
  // ===========================================================================

  /// Register a new user account with preset avatar
  Future<ApiResponse<UserModel>> register({
    required String username,
    required String password,
    required String avatarId,
    String? email,
  }) => _authApi.register(
    username: username,
    password: password,
    avatarId: avatarId,
    email: email,
  );

  /// Login with existing username & password
  Future<ApiResponse<UserModel>> login({
    required String username,
    required String password,
  }) => _authApi.login(
    username: username,
    password: password,
  );

  /// Login with Google
  Future<ApiResponse<UserModel>> loginWithGoogle({
    required String idToken,
  }) => _authApi.loginWithGoogle(
    idToken: idToken,
  );

  /// Forgot Password
  Future<ApiResponse<void>> forgotPassword({required String email}) =>
      _authApi.forgotPassword(email: email);

  /// Fetch User Profile (GET /profile)
  Future<ApiResponse<UserModel>> fetchUserProfile({
    required String token,
  }) => _authApi.fetchUserProfile(token: token);

  /// Update User Profile (Username, Avatar, Password, Email, Bio)
  Future<ApiResponse<UserModel>> updateProfile({
    required String token,
    String? username,
    String? avatarId,
    File? avatar,
    String? currentPassword,
    String? newPassword,
    String? email,
    String? bio,
  }) => _authApi.updateProfile(
    token: token,
    username: username,
    avatarId: avatarId,
    avatar: avatar,
    currentPassword: currentPassword,
    newPassword: newPassword,
    email: email,
    bio: bio,
  );

  /// Change Password
  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
    required String token,
  }) => _authApi.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
    newPasswordConfirmation: newPasswordConfirmation,
    token: token,
  );

  // ===========================================================================
  // DASHBOARD & STATS DELEGATES
  // ===========================================================================

  /// Get My Stats
  Future<ApiResponse<List<Map<String, dynamic>>>> getMyStats(
    String token,
  ) => _dashboardApi.getMyStats(token);

  /// Fetch aggregated Home dashboard data (GET /home/dashboard)
  Future<ApiResponse<HomeDashboardResponse>> getHomeDashboard({
    String? token,
  }) => _dashboardApi.getHomeDashboard(token: token);

  /// Fetch full user profile & stats in a single call (GET /profile/me/full)
  Future<ApiResponse<ProfileMeFullResponse>> getProfileMeFull({
    required String token,
  }) => _dashboardApi.getProfileMeFull(token: token);

  // ===========================================================================
  // LEADERBOARD DELEGATES
  // ===========================================================================

  /// Fetch Online Leaderboard for Classic Mode League
  Future<ApiResponse<List<OnlineLeaderboardEntry>>> getOnlineLeaderboard() =>
      _leaderboardApi.getOnlineLeaderboard();

  /// Fetch Online Leaderboard for a specific Game Mode
  Future<ApiResponse<List<OnlineLeaderboardEntry>>> getOnlineLeaderboardByMode(
    String modeId,
  ) => _leaderboardApi.getOnlineLeaderboardByMode(modeId);

  /// Fetch Leaderboard for Game Modes
  Future<ApiResponse<List<GameModeLeaderboardEntry>>> getModesLeaderboard(
    String mode,
  ) => _leaderboardApi.getModesLeaderboard(mode);

  /// Fetch Weekly League Leaderboard
  Future<ApiResponse<List<LeagueLeaderboardEntry>>> getLeagueLeaderboard({
    int page = 1,
  }) => _leaderboardApi.getLeagueLeaderboard(page: page);

  /// Fetch Universal Player Profile
  Future<ApiResponse<UniversalPlayerProfile>> getPlayerProfile(
    int userId,
  ) => _leaderboardApi.getPlayerProfile(userId);

  // ===========================================================================
  // NEW SESSION & EVENT-BASED SCORE METHODS (RETAINED UNTOUCHED)
  // ===========================================================================

  /// Start a new game session on the server
  Future<StartSessionResponse> startGameSession(
    String gameMode,
    String token, {
    int? dailyChallengeId,
    bool? isAdRetry,
  }) async {
    try {
      final payload = <String, dynamic>{'game_mode': gameMode};
      if (dailyChallengeId != null) {
        payload['daily_challenge_id'] = dailyChallengeId;
      }
      if (isAdRetry != null) {
        payload['is_ad_retry'] = isAdRetry;
      }

      final response = await _dio.post(
        '/game/start',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        return StartSessionResponse(
          isSuccess: true,
          sessionId: data['session_id'],
          seed: data['seed'],
          speedLevel: data['speed_level'] ?? 1,
          modeConfig: data['config'] ?? {},
          attemptsRemaining: data['attempts_remaining'],
          canPlay: data['can_play'],
        );
      }
      return StartSessionResponse(
        isSuccess: false,
        error: data?['error'] ?? 'Failed to start game session',
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) {
        return StartSessionResponse(
          isSuccess: false,
          isSessionExpired: true,
          error: 'Session expired',
        );
      }
      return StartSessionResponse(isSuccess: false, error: _parseDioError(e));
    } catch (e) {
      return StartSessionResponse(isSuccess: false, error: e.toString());
    }
  }

  /// Periodic anti-cheat heartbeat
  Future<SubmitScoreResponse> sendHeartbeat(
    String sessionId,
    String token, {
    int currentScore = 0,
    int? durationSeconds,
  }) async {
    try {
      final payload = <String, dynamic>{
        'session_id': sessionId,
        'current_score': currentScore,
      };
      if (durationSeconds != null) {
        payload['duration_seconds'] = durationSeconds;
      }

      final response = await _dio.post(
        '/game/heartbeat',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        return SubmitScoreResponse(isSuccess: true);
      }
      return SubmitScoreResponse(
        isNetworkError: true,
        message: data?['error'] ?? 'Heartbeat failed',
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) {
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

  /// Submit score with batch event log verification
  Future<SubmitScoreResponse> submitScore({
    required String sessionId,
    int? finalScore,
    int? value,
    required List<Map<String, dynamic>> events,
    required String token,
    String? userId,
    String? gameMode,
    int? durationSeconds,
    int? apples,
    int? goldenApples,
    int? obstaclesPassed,
    String? hmacSignature,
    String? verificationToken,
  }) async {
    try {
      final effectiveScore = finalScore ?? value ?? 0;
      final effectiveHmac = hmacSignature ??
          (userId != null && gameMode != null
              ? HmacUtils.generateScoreSignature(
                  gameMode: gameMode,
                  value: effectiveScore,
                  userId: userId,
                )
              : null);

      debugPrint('--- [ApiService] submitScore REQUEST ---');
      debugPrint('Endpoint: ${_dio.options.baseUrl}/score/submit');
      debugPrint('Session ID: $sessionId, Mode: $gameMode, Value: $effectiveScore');
      debugPrint('Events Count: ${events.length}');
      debugPrint('HMAC Signature: $effectiveHmac');

      final payload = <String, dynamic>{
        'session_id': sessionId,
        'value': effectiveScore,
        'final_score': effectiveScore,
        if (userId != null) 'user_id': userId,
        'events': events,
        if (gameMode != null) 'game_mode': gameMode,
        if (effectiveHmac != null) 'hmac_signature': effectiveHmac,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        if (apples != null) 'apples': apples,
        if (goldenApples != null) 'golden_apples': goldenApples,
        if (obstaclesPassed != null) 'obstacles_passed': obstaclesPassed,
        if (verificationToken != null)
          'verification_token': verificationToken,
      };

      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final response = await _dio.post(
        '/score/submit',
        data: payload,
        options: options,
      );

      debugPrint('--- [ApiService] submitScore RESPONSE ---');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Data: ${response.data}');

      final data = response.data;
      if ((response.statusCode == 200 || response.statusCode == 201) && data != null) {
        XpReward? xpData;
        if (data['xp'] != null && data['xp'] is Map<String, dynamic>) {
          xpData = XpReward.fromJson(data['xp'] as Map<String, dynamic>);
        }

        int? coinsAwarded;
        if (data['coins_earned'] != null ||
            data['coins_awarded'] != null ||
            data['reward_coins'] != null ||
            data['coins'] != null) {
          coinsAwarded =
              parseCoins(data['coins_earned']) ??
              parseCoins(data['coins_awarded']) ??
              parseCoins(data['reward_coins']) ??
              parseCoins(data['coins']);
        }

        int? newBalance;
        if (data['wallet_balance'] != null ||
            data['new_balance'] != null ||
            data['balance'] != null ||
            data['user_balance'] != null) {
          newBalance =
              parseBalance(data['wallet_balance']) ??
              parseBalance(data['new_balance']) ??
              parseBalance(data['balance']) ??
              parseBalance(data['user_balance']);
        }

        LeagueScoreResult? leagueResult;
        if (data['league'] != null && data['league'] is Map<String, dynamic>) {
          final lMap = data['league'] as Map<String, dynamic>;
          leagueResult = LeagueScoreResult.fromJson(lMap);
        }

        return SubmitScoreResponse(
          isSuccess: true,
          rank: parseInt(data['rank']),
          isNewHighscore: data['is_new_highscore'] ?? false,
          message: data['message'] ?? 'Score submitted successfully',
          xp: xpData,
          coinsAwarded: coinsAwarded,
          newBalance: newBalance,
          league: leagueResult,
          attemptsRemaining: parseInt(data['attempts_remaining']),
          canRetry: data['can_retry'],
          attemptNumber: parseInt(data['attempt_number']),
          attemptsUsed: parseInt(data['attempts_used']),
          seasonNumber: parseInt(data['season_number']),
          bestValue: parseInt(data['best_value']),
        );
      }

      if (response.statusCode == 403 && data != null) {
        return SubmitScoreResponse(
          isRejected: true,
          rejectionReason: data['reason'] ?? 'anti_cheat_rejected',
          message: data['message'] ?? 'Score rejected by server',
        );
      }

      return SubmitScoreResponse(
        isNetworkError: true,
        message: data?['error'] ?? 'Score submission failed',
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 403 && e.response?.data != null) {
        final data = e.response!.data;
        return SubmitScoreResponse(
          isRejected: true,
          rejectionReason: data['reason'] ?? 'anti_cheat_rejected',
          message: data['message'] ?? 'Score rejected by server',
        );
      }
      if (status == 401) {
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

  /// Submit Level Complete
  Future<SubmitScoreResponse> submitLevelComplete({
    String? sessionId,
    int? levelId,
    int? applesEaten,
    required String token,
    String? userId,
    bool isReplay = false,
    int? levelNumber,
    int? stars,
    int? score,
    int? durationSeconds,
    List<Map<String, dynamic>>? events,
    String? verificationToken,
    String? hmacSignature,
  }) async {
    try {
      final effSessionId =
          sessionId ?? 'level_${DateTime.now().millisecondsSinceEpoch}';
      final effLevelId = levelId ?? levelNumber ?? 1;
      final effApples = applesEaten ?? score ?? 0;

      debugPrint(
        '🚀 [ApiService] POST /level/complete: levelId=$effLevelId, apples=$effApples, isReplay=$isReplay, sessionId=$effSessionId',
      );

      final effectiveHmac =
          hmacSignature ??
          (userId != null
              ? HmacUtils.generateScoreSignature(
                  gameMode: 'level',
                  value: effApples,
                  userId: userId,
                )
              : null);

      final payload = <String, dynamic>{
        'session_id': effSessionId,
        'level_id': effLevelId,
        'apples_eaten': effApples,
        'is_replay': isReplay,
        if (levelNumber != null) 'level_number': levelNumber,
        if (stars != null) 'stars': stars,
        if (score != null) 'score': score,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        if (events != null) 'events': events,
        if (verificationToken != null)
          'verification_token': verificationToken,
        if (effectiveHmac != null) 'hmac_signature': effectiveHmac,
      };

      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final response = await _dio.post(
        '/level/complete',
        data: payload,
        options: options,
      );

      final data = response.data;
      debugPrint(
        '📡 [ApiService] /level/complete HTTP ${response.statusCode} response data: $data',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        XpReward? xpReward;
        if (data is Map && data['xp'] != null) {
          if (data['xp'] is Map<String, dynamic>) {
            xpReward = XpReward.fromJson(data['xp'] as Map<String, dynamic>);
          } else if (data['xp'] is Map) {
            xpReward = XpReward.fromJson(Map<String, dynamic>.from(data['xp']));
          }
        }

        final coinAwarded = data['coin_awarded'] == true;
        int? coinsAwarded;
        if (data['coins_awarded'] != null) {
          coinsAwarded = parseCoins(data['coins_awarded']);
        } else if (data['coins_earned'] != null) {
          coinsAwarded = parseCoins(data['coins_earned']);
        } else if (data['reward_coins'] != null) {
          coinsAwarded = parseCoins(data['reward_coins']);
        } else if (data['coins'] != null) {
          coinsAwarded = parseCoins(data['coins']);
        } else if (coinAwarded) {
          coinsAwarded = 10;
        }

        int? newBalance;
        if (data['new_balance'] != null) {
          newBalance = parseBalance(data['new_balance']);
        } else if (data['wallet_balance'] != null) {
          newBalance = parseBalance(data['wallet_balance']);
        } else if (data['balance'] != null) {
          newBalance = parseBalance(data['balance']);
        } else if (data['user_balance'] != null) {
          newBalance = parseBalance(data['user_balance']);
        }

        return SubmitScoreResponse(
          isSuccess: true,
          coinAwarded: coinAwarded,
          coinsAwarded: coinsAwarded,
          newBalance: newBalance,
          xp: xpReward,
          isNewHighscore: data['is_new_highscore'] ?? false,
          message: data['message'] ?? 'Level completed successfully',
        );
      }

      if (response.statusCode == 403 && data != null) {
        return SubmitScoreResponse(
          isRejected: true,
          rejectionReason: data['reason'] ?? 'anti_cheat_rejected',
          message: data['message'] ?? 'Score rejected by server',
        );
      }

      return SubmitScoreResponse(
        isNetworkError: true,
        message: data?['error'] ?? 'Level completion submission failed',
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 403 || status == 422) {
        final data = e.response?.data;
        return SubmitScoreResponse(
          isRejected: true,
          rejectionReason: data is Map ? data['reason'] : null,
          message:
              data is Map ? data['message']?.toString() : 'Validation failed',
        );
      }
      if (status == 419 || status == 440 || status == 401) {
        return SubmitScoreResponse(
          isSessionExpired: true,
          message: 'Session expired',
        );
      }
      return SubmitScoreResponse(isNetworkError: true, message: e.message);
    } catch (e, st) {
      debugPrint('❌ [ApiService] /level/complete unexpected error: $e\n$st');
      return SubmitScoreResponse(isNetworkError: true, message: e.toString());
    }
  }

  // ===========================================================================
  // DAILY MISSION DELEGATES
  // ===========================================================================

  /// Fetch today's active daily mission
  Future<ApiResponse<DailyMissionModel>> getDailyMission({
    String? token,
  }) => _missionsApi.getDailyMission(token: token);

  /// Submit raw stat value for daily mission with HMAC signature
  Future<ApiResponse<DailyMissionSubmitResponse>> submitDailyMission({
    required int missionId,
    required int rawStatValue,
    required String userId,
    required String token,
    String? secretKey,
  }) => _missionsApi.submitDailyMission(
    missionId: missionId,
    rawStatValue: rawStatValue,
    userId: userId,
    token: token,
    secretKey: secretKey,
  );

  /// Unlock second attempt for daily mission via rewarded ad callback
  Future<ApiResponse<DailyMissionModel>> unlockSecondAttemptDailyMission({
    required int missionId,
    required String token,
  }) => _missionsApi.unlockSecondAttemptDailyMission(
    missionId: missionId,
    token: token,
  );

  // ===========================================================================
  // WALLET & ADS DELEGATES
  // ===========================================================================

  /// Fetch full wallet data including coin balance and ad reward cooldown/limits
  Future<ApiResponse<WalletData>> getWallet({required String token}) =>
      _walletApi.getWallet(token: token);

  /// Server-side verification for rewarded ad viewing (POST /api/ads/verify-reward)
  Future<ApiResponse<Map<String, dynamic>>> verifyAdReward({
    required String placement,
    required String token,
    String? rewardToken,
  }) => _walletApi.verifyAdReward(
    placement: placement,
    token: token,
    rewardToken: rewardToken,
  );

  /// Fetch user coin balance
  Future<ApiResponse<int>> getWalletBalance({required String token}) =>
      _walletApi.getWalletBalance(token: token);

  /// Fetch user coin transaction history (paginated)
  Future<ApiResponse<List<CoinTransactionModel>>> getCoinTransactions({
    required String token,
    int page = 1,
    int perPage = 15,
  }) => _walletApi.getCoinTransactions(
    token: token,
    page: page,
    perPage: perPage,
  );

  /// Claim welcome bonus for new users (POST /wallet/claim-welcome-bonus)
  Future<ApiResponse<WelcomeBonusResponse>> claimWelcomeBonus({
    required String token,
  }) => _walletApi.claimWelcomeBonus(token: token);

  // ===========================================================================
  // SHOP & COSMETICS DELEGATES
  // ===========================================================================

  /// Fetch items available in the shop with user_balance
  Future<ApiResponse<ShopCatalogResponse>> getShopCatalog({
    String? token,
  }) => _shopApi.getShopCatalog(token: token);

  /// Fetch full cosmetics catalog from GET /shop
  Future<ApiResponse<CosmeticsCatalogResponse>> getShopCosmetics({
    String? token,
  }) => _shopApi.getShopCosmetics(token: token);

  /// Purchase a shop item (skin, theme, avatar) via POST /shop/purchase
  Future<ApiResponse<ShopPurchaseResponse>> purchaseShopItem({
    required dynamic itemId,
    String? itemType,
    required String token,
  }) => _shopApi.purchaseShopItem(
    itemId: itemId,
    itemType: itemType,
    token: token,
  );

  /// Purchase a cosmetic theme or avatar via POST /shop/purchase
  Future<ApiResponse<ShopPurchaseResponse>> purchaseCosmeticsItem({
    required dynamic itemId,
    required String itemType,
    required String token,
  }) => _shopApi.purchaseCosmeticsItem(
    itemId: itemId,
    itemType: itemType,
    token: token,
  );

  // ===========================================================================
  // ERROR PARSER (INTERNAL & BACKWARD-COMPATIBLE)
  // ===========================================================================

  String _parseDioError(DioException e, {String? fallback}) =>
      ApiErrorParser.parseDioError(e, fallback: fallback);
}
