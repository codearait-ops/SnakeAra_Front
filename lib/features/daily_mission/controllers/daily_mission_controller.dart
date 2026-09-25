import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/ad_service.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../models/daily_mission_model.dart';

/// GetX controller managing daily mission state, attempts, rewarded ad unlock,
/// and HMAC-signed score submissions.
class DailyMissionController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final AdService _adService = Get.find<AdService>();
  final AuthController _auth = Get.find<AuthController>();

  final Rx<DailyMissionModel?> currentMission = Rx<DailyMissionModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<Duration> remainingTime = Duration.zero.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    
    // Reactively fetch mission only when login status transitions to true
    ever(_auth.isLoggedIn, (loggedIn) {
      if (loggedIn && currentMission.value == null && !isLoading.value) {
        debugPrint('[DailyMissionController] 🔑 isLoggedIn changed to $loggedIn -> fetching mission');
        fetchTodayMission();
      } else if (!loggedIn) {
        currentMission.value = null;
      }
    });

    if (_auth.isLoggedIn.value && currentMission.value == null) {
      fetchTodayMission();
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  /// Fetches today's active daily mission from server
  Future<void> fetchTodayMission({bool forceRefresh = false}) async {
    if (isLoading.value) return;
    if (!forceRefresh && currentMission.value != null) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      String? token = _auth.currentUser.value?.token;
      if (token == null || token.isEmpty) {
        if (Get.isRegistered<StorageService>()) {
          token = await Get.find<StorageService>().getUserToken();
        }
      }

      debugPrint(
        '================= 🎯 [DAILY MISSION FETCH] =================',
      );
      debugPrint(
        '👤 Logged in: ${_auth.isLoggedIn.value}, Token present: ${token != null && token.isNotEmpty}',
      );
      final response = await _api.getDailyMission(token: token);

      if (response.isSuccess && response.data != null) {
        final m = response.data!;
        currentMission.value = m;
        debugPrint(
          '📋 Mission ID: ${m.id} | Mode: ${m.gameMode} | Type: ${m.type} | Target: ${m.targetValue}',
        );
        debugPrint(
          '🎯 Status: ${m.status} | Attempt Number: ${m.attemptNumber} | Reward: ${m.rewardCoins} coins',
        );
        debugPrint(
          '⏰ closesAt: ${m.closesAt} | secondsRemaining: ${m.secondsRemaining}',
        );
        debugPrint(
          '🔓 canPlay: ${m.canPlay} | canUnlockSecondAttempt: ${m.canUnlockSecondAttempt} | isCompleted: ${m.isCompleted}',
        );
        _setupCountdownTimer(m.closesAt, secondsRemaining: m.secondsRemaining);
      } else {
        debugPrint('⚠️ Daily mission fetch failed: ${response.message}');
        currentMission.value = null;
        errorMessage.value = response.message ?? 'no_daily_honors'.tr;
        _timer?.cancel();
        remainingTime.value = Duration.zero;
      }
      debugPrint('===========================================================');
    } catch (e) {
      debugPrint('[DailyMissionController] ❌ fetchTodayMission error: $e');
      currentMission.value = null;
      errorMessage.value = e.toString();
      _timer?.cancel();
      remainingTime.value = Duration.zero;
    } finally {
      isLoading.value = false;
    }
  }

  /// Sets daily mission directly from aggregated Home Dashboard response
  void setMissionFromDashboard(DailyMissionModel mission) {
    currentMission.value = mission;
    errorMessage.value = '';
    isLoading.value = false;
    _setupCountdownTimer(mission.closesAt, secondsRemaining: mission.secondsRemaining);
  }

  void _setupCountdownTimer(DateTime? closesAt, {int? secondsRemaining}) {
    _timer?.cancel();
    final now = DateTime.now();

    if (secondsRemaining != null && secondsRemaining > 0) {
      remainingTime.value = Duration(seconds: secondsRemaining);
      debugPrint(
        '[DailyMissionTimer] ⏱️ Using secondsRemaining: $secondsRemaining s',
      );
    } else if (closesAt != null) {
      final target = closesAt.isUtc ? closesAt.toLocal() : closesAt;
      final diff = target.difference(now);
      if (diff.inSeconds > 0) {
        remainingTime.value = diff;
        debugPrint(
          '[DailyMissionTimer] ⏱️ ClosesAt: $target, Remaining: ${diff.inHours}h ${diff.inMinutes % 60}m',
        );
      } else {
        // Fallback: If closesAt has already passed or was start-of-day, count down until tonight midnight
        final midnight = DateTime(now.year, now.month, now.day + 1);
        final fallbackDiff = midnight.difference(now);
        remainingTime.value = fallbackDiff;
        debugPrint(
          '[DailyMissionTimer] ⏱️ closesAt was in past ($closesAt), falling back to midnight: ${fallbackDiff.inHours}h ${fallbackDiff.inMinutes % 60}m',
        );
      }
    } else {
      // Default: until midnight
      final midnight = DateTime(now.year, now.month, now.day + 1);
      final fallbackDiff = midnight.difference(now);
      remainingTime.value = fallbackDiff;
      debugPrint(
        '[DailyMissionTimer] ⏱️ Default midnight timer: ${fallbackDiff.inHours}h ${fallbackDiff.inMinutes % 60}m',
      );
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime.value.inSeconds > 0) {
        remainingTime.value -= const Duration(seconds: 1);
      } else {
        timer.cancel();
      }
    });
  }

  /// Submits the raw stat value to server with HMAC signature
  /// Submits the raw stat value to server with HMAC signature
  Future<DailyMissionSubmitResponse?> submitMission(
    int rawStatValue, {
    int? missionId,
  }) async {
    final mission = currentMission.value;
    final user = _auth.currentUser.value;
    final targetMissionId = (missionId != null && missionId > 0)
        ? missionId
        : (mission?.id ?? 0);

    String? userId = user?.id;
    String? token = user?.token;

    if ((userId == null || token == null || token.isEmpty) &&
        Get.isRegistered<StorageService>()) {
      final storage = Get.find<StorageService>();
      userId ??= storage.getSavedUserId();
      token ??= await storage.getUserToken();
    }

    if (userId == null ||
        userId.isEmpty ||
        token == null ||
        token.isEmpty ||
        targetMissionId <= 0) {
      debugPrint(
        '[DailyMissionController] ⚠️ Aborting submit: userId is $userId, token is ${token != null}, targetMissionId: $targetMissionId',
      );
      return null;
    }

    isLoading.value = true;
    try {
      final response = await _api.submitDailyMission(
        missionId: targetMissionId,
        rawStatValue: rawStatValue,
        userId: userId,
        token: token,
      );

      if (response.isSuccess && response.data != null) {
        final result = response.data!;
        // Update local mission state
        if (mission != null) {
          currentMission.value = mission.copyWith(
            status: result.status,
            attemptNumber: result.attemptNumber,
            rawStatValue: rawStatValue,
            isCompletedServer: result.isCompleted,
            canPlayServer: result.isCompleted
                ? false
                : (result.status != 'failed'),
            canRetryWithAdServer: result.canRetryWithAd,
          );
        }

        // Route coin reward to WalletController funnel if mission succeeded
        if (result.isCompleted && result.rewardCoins > 0) {
          if (Get.isRegistered<WalletController>()) {
            Get.find<WalletController>().receiveCoins(
              result.rewardCoins,
              animate: true,
            );
          }
        }

        fetchTodayMission();
        return result;
      } else {
        Get.snackbar(
          'error'.tr,
          response.message ?? 'error'.tr,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('[DailyMissionController] submit error: $e');
    } finally {
      isLoading.value = false;
    }
    return null;
  }

  /// Unlocks second attempt for today's mission by watching a rewarded ad
  Future<bool> unlockSecondAttemptViaAd(BuildContext context) async {
    final mission = currentMission.value;
    final user = _auth.currentUser.value;
    if (mission == null) return false;

    // Show rewarded video ad via AdService with server verification
    final adSuccess = await _adService.showRewardedAdAndVerify(
      context: context,
      placement: 'daily_mission_retry',
      token: user?.token ?? '',
    );

    if (!adSuccess) {
      return false;
    }

    if (user != null && user.token.isNotEmpty) {
      isLoading.value = true;
      final response = await _api.unlockSecondAttemptDailyMission(
        missionId: mission.id,
        token: user.token,
      );
      isLoading.value = false;

      if (response.isSuccess && response.data != null) {
        currentMission.value = response.data!;
        Get.snackbar(
          'second_chance_unlocked_title'.tr,
          'second_chance_unlocked_msg'.tr,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      }
    } else {
      // Local fallback for guest
      currentMission.value = mission.copyWith(
        attemptNumber: 2,
        status: 'pending',
      );
      Get.snackbar(
        'second_chance_unlocked_title'.tr,
        'second_chance_unlocked_msg'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    }
    return false;
  }

  /// Starts the game mode for the daily mission
  void startMissionGame() {
    final mission = currentMission.value;
    if (mission == null) return;

    _auth.requireAuth(() {
      debugPrint(
        '[DailyMissionController] 🚀 startMissionGame -> ID: ${mission.id} | Mode: ${mission.gameMode} | Type: ${mission.type} | Target: ${mission.targetValue} | CanPlay: ${mission.canPlay}',
      );

      if (!mission.canPlay) {
        Get.snackbar(
          'daily_mission_title'.tr,
          mission.isCompleted
              ? 'daily_mission_completed'.tr
              : 'daily_mission_no_attempts_left'.tr,
          backgroundColor: Colors.amber.shade800,
          colorText: Colors.white,
        );
        return;
      }

      Get.toNamed(
        '/game',
        arguments: {
          'mode': mission.gameMode,
          'seed': mission.seed ?? DateTime.now().millisecondsSinceEpoch,
          'isDailyMission': true,
          'dailyMissionId': mission.id,
          'attemptNumber': mission.attemptNumber,
          'dailyMissionType': mission.type,
          'dailyMissionTarget': mission.targetValue,
          'dailyMissionReward': mission.rewardCoins,
        },
      )?.then((_) => fetchTodayMission());
    }, contextMessage: 'login_prompt_daily_mission'.tr);
  }
}
