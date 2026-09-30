import 'package:get/get.dart';
import '../../../features/cosmetics/controllers/cosmetics_controller.dart';
import '../../../features/cosmetics/repositories/cosmetics_repository.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/auth/controllers/game_session_controller.dart';
import '../../../features/daily_mission/controllers/daily_mission_controller.dart';
import '../../../features/wallet/controllers/wallet_controller.dart';
import '../../../features/levels/controllers/level_controller.dart';
import '../../../features/settings/controllers/settings_controller.dart';
import '../../../services/ad_service.dart';
import '../../../services/api_service.dart';
import '../../../services/game_event_logger.dart';
import '../../../services/league_api_service.dart';
import '../../../services/app_update_service.dart';

import '../../../features/cosmetics/services/theme_cache_service.dart';
import '../../../features/menu/controllers/menu_controller.dart';

/// Global initial bindings for GetX dependency injection.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Base / API Services
    Get.put<AdService>(AdService(), permanent: true);
    Get.put<ApiService>(ApiService(), permanent: true);
    Get.put<LeagueApiService>(LeagueApiService(), permanent: true);
    Get.put<ThemeCacheService>(ThemeCacheService(), permanent: true);
    Get.put<CosmeticsRepository>(CosmeticsRepository(), permanent: true);
    Get.put<AppUpdateService>(AppUpdateService(), permanent: true);

    // 2. State Controllers
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<GameSessionController>(GameSessionController(), permanent: true);
    Get.put<DailyMissionController>(DailyMissionController(), permanent: true);
    Get.put<WalletController>(WalletController(), permanent: true);
    Get.put<SettingsController>(SettingsController(), permanent: true);
    Get.put<LevelController>(LevelController(), permanent: true);
    Get.put<CosmeticsController>(CosmeticsController(), permanent: true);
    Get.put<MenuController>(MenuController(), permanent: true);

    // 3. Dependent Services & Trackers
    Get.put<GameEventLogger>(GameEventLogger(), permanent: true);
  }
}
