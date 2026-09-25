import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:snake_game/features/levels/controllers/level_controller.dart';
import '../../../app/core/utils/enums.dart';
import '../../../services/api_service.dart';
import '../../../services/sound_service.dart';
import '../../../services/storage_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../daily_mission/controllers/daily_mission_controller.dart';
import '../../cosmetics/controllers/cosmetics_controller.dart';
import '../../game/models/game_mode_config.dart';
import '../../league/models/league_models.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../models/home_dashboard_model.dart';

/// Controller for the main menu screen.
///
/// Manages Home Dashboard data (single-call), navigation to game modes,
/// level selection, settings, and leaderboard.
class MenuController extends GetxController {
  final Rx<MyRankResponse?> myLeagueRank = Rx<MyRankResponse?>(null);
  final Rx<HomeDashboardResponse?> dashboard = Rx<HomeDashboardResponse?>(null);
  final Rx<HomeLeagueSummary?> leagueSummary = Rx<HomeLeagueSummary?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHomeDashboard();
  }

  @override
  void onReady() {
    super.onReady();
    checkPendingCoins();
  }

  /// Checks for any pending coins earned in other views (e.g. gameplay) and triggers fly animation
  void checkPendingCoins() {
    if (Get.isRegistered<WalletController>()) {
      Get.find<WalletController>().checkAndTriggerPendingCoins();
    }
  }

  /// Resets user-specific dashboard data for guest mode
  void resetForGuest() {
    dashboard.value = null;
    leagueSummary.value = null;
    myLeagueRank.value = null;
  }

  /// Fetches aggregated Home dashboard from server in a single call (GET /home/dashboard).
  ///
  /// Replaces the previous 4 separate requests (daily-mission + league/my-rank + wallet + profile)
  /// and updates all registered sub-controllers automatically.
  Future<void> fetchHomeDashboard({bool forceRefresh = false}) async {
    if (isLoading.value) return;
    if (!forceRefresh && dashboard.value != null) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final auth = Get.find<AuthController>();
      String? token = auth.currentUser.value?.token;
      if (token == null || token.isEmpty) {
        if (Get.isRegistered<StorageService>()) {
          token = await Get.find<StorageService>().getUserToken();
        }
      }

      final api = Get.find<ApiService>();
      final res = await api.getHomeDashboard(token: token);

      if (res.isSuccess && res.data != null) {
        final data = res.data!;
        dashboard.value = data;
        leagueSummary.value = data.leagueSummary;

        // 1. Update League Summary / MyRank
        if (data.leagueSummary != null) {
          myLeagueRank.value = data.leagueSummary!.toMyRankResponse();
        } else {
          myLeagueRank.value = null;
        }

        // 2. Sync User Profile if authenticated
        if (data.user != null) {
          final currentUser = auth.currentUser.value;
          final effectiveToken =
              (currentUser != null && currentUser.token.isNotEmpty)
              ? currentUser.token
              : (token ?? '');
          auth.currentUser.value = data.user!.copyWith(token: effectiveToken);

          if (Get.isRegistered<StorageService>()) {
            Get.find<StorageService>().setPlayerXp(
              data.user!.xpTotal,
              level: data.user!.level,
              nextLevelXp: data.user!.nextLevelXp,
            );
          }
        }

        // 3. Sync Wallet Balance and Ad Reward metadata
        if (Get.isRegistered<WalletController>()) {
          final walletCtrl = Get.find<WalletController>();
          if (data.wallet != null) {
            walletCtrl.balance.value = data.wallet!.balance;
            walletCtrl.adRewardInfo.value = data.wallet!.adReward;
          } else if (data.user?.coinBalance != null) {
            walletCtrl.balance.value = data.user!.coinBalance!;
          } else if (!auth.isLoggedIn.value) {
            walletCtrl.reset();
          }
        }

        // 4. Sync Daily Mission
        if (data.dailyMission != null &&
            Get.isRegistered<DailyMissionController>()) {
          final missionCtrl = Get.find<DailyMissionController>();
          missionCtrl.setMissionFromDashboard(data.dailyMission!);
        }

        // 5. Sync Level Mode Progress
        if (data.levelProgress != null &&
            Get.isRegistered<LevelController>()) {
          Get.find<LevelController>().syncFromBackend(data.levelProgress!);
        }

        // 6. Sync Cosmetics (Themes, Avatars & Skins) from Dashboard
        if ((data.availableThemes.isNotEmpty || data.availableAvatars.isNotEmpty || data.availableSkins.isNotEmpty) &&
            Get.isRegistered<CosmeticsController>()) {
          Get.find<CosmeticsController>().mergeDashboardCosmetics(
            themes: data.availableThemes,
            avatars: data.availableAvatars,
            skins: data.availableSkins,
          );
        }
      } else {
        errorMessage.value = res.message ?? 'error_loading_data'.tr;
      }
    } catch (e) {
      debugPrint('[MenuController] Error fetching home dashboard: $e');
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Backward compatible wrapper for checking league rank status.
  Future<void> checkLeagueStatus() async {
    await fetchHomeDashboard();
  }

  /// Start Classic (Endless) Mode.
  void startClassicGame() {
    Get.find<SoundService>().playButtonTap();
    Get.toNamed('/game', arguments: {'mode': 'classic'});
  }

  /// Navigate to Level Selection screen.
  void startLevelGame() {
    openLevelSelect();
  }

  /// Open the level selection screen.
  void openLevelSelect() {
    Get.find<SoundService>().playButtonTap();
    Get.toNamed('/level-select');
  }

  /// Open the mode details view for a selected game mode.
  void openModeDetails(GameModeConfig config) {
    if (!config.isAvailable) return;
    Get.find<SoundService>().playButtonTap();
    Get.toNamed('/mode-details', arguments: config);
  }

  /// Launch any mode dynamically based on its configuration.
  void launchMode(GameModeConfig config) {
    if (!config.isAvailable) return;
    Get.find<SoundService>().playButtonTap();

    switch (config.mode) {
      case GameMode.classic:
        Get.toNamed('/game', arguments: {'mode': 'classic'});
        break;
      case GameMode.level:
        final levelController = Get.find<LevelController>();
        final targetLevel = levelController.lastUnlockedLevel.value.clamp(
          1,
          100,
        );
        levelController.selectLevel(targetLevel);
        Get.toNamed('/game', arguments: targetLevel);
        break;
      default:
        Get.toNamed('/game', arguments: {'mode': config.id});
        break;
    }
  }

  /// Navigate to the leaderboard screen.
  void openLeaderboard() {
    Get.find<SoundService>().playButtonTap();
    final auth = Get.find<AuthController>();
    auth.requireAuth(
      () => Get.toNamed('/leaderboard'),
      contextMessage: 'login_prompt_leaderboard'.tr,
    );
  }

  /// Navigate to League screen if user is logged in.
  void openLeague() {
    Get.find<SoundService>().playButtonTap();
    final auth = Get.find<AuthController>();
    auth.requireAuth(
      () => Get.toNamed('/league')?.then((_) => checkLeagueStatus()),
      contextMessage: 'login_prompt_league'.tr,
    );
  }

  /// Navigate to Daily Mission screen if user is logged in.
  void openDailyMission() {
    Get.find<SoundService>().playButtonTap();
    final auth = Get.find<AuthController>();
    auth.requireAuth(
      () => Get.toNamed('/daily-mission')?.then((_) => fetchHomeDashboard(forceRefresh: true)),
      contextMessage: 'login_prompt_daily_mission'.tr,
    );
  }

  /// Navigate to the settings screen.
  void openSettings() {
    Get.find<SoundService>().playButtonTap();
    Get.toNamed('/settings');
  }
}
