import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../services/api_service.dart';
import '../../../services/league_api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../league/models/league_player_summary_model.dart';
import '../models/universal_player_profile.dart';

class PlayerProfileController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  LeagueApiService get _leagueApi =>
      Get.isRegistered<LeagueApiService>()
          ? Get.find<LeagueApiService>()
          : Get.put(LeagueApiService());

  final Rx<UniversalPlayerProfile?> profile = Rx<UniversalPlayerProfile?>(null);
  final Rx<LeaguePlayerSummary?> leagueSummary = Rx<LeaguePlayerSummary?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isLeagueView = false.obs;

  Future<void> fetchProfile(
    int userId, {
    int? seasonId,
    bool isLeagueContext = false,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';

    String? token;
    try {
      if (Get.isRegistered<AuthController>()) {
        token = Get.find<AuthController>().currentUser.value?.token;
      }
    } catch (_) {}

    if (isLeagueContext) {
      debugPrint(
        '>>> [API REQUEST] getLeaguePlayerSummary for userId: $userId, seasonId: $seasonId',
      );
      final res = await _leagueApi.getLeaguePlayerSummary(
        userId: userId,
        seasonId: seasonId,
        token: token,
      );
      if (res.isSuccess && res.data != null) {
        leagueSummary.value = res.data;
        isLeagueView.value = true;
        isLoading.value = false;
        return;
      }
      debugPrint(
        '⚠️ [API WARNING] getLeaguePlayerSummary failed (${res.message}). Falling back to getPlayerProfile',
      );
    }

    // Default or Fallback: fetch universal profile
    final response = await _api.getPlayerProfile(userId);
    isLoading.value = false;
    if (response.isSuccess && response.data != null) {
      profile.value = response.data;
      isLeagueView.value = false;
    } else {
      errorMessage.value = response.message ?? 'Failed to load profile';
    }
  }
}
