import 'package:get/get.dart';
import '../../features/menu/controllers/menu_controller.dart';
import '../../features/menu/views/menu_view.dart';
import '../../features/levels/controllers/level_controller.dart';
import '../../features/levels/views/level_selection_view.dart';
import '../../features/game/controllers/game_controller.dart';
import '../../features/game/views/game_view.dart';
import '../../features/leaderboard/controllers/leaderboard_controller.dart';
import '../../features/leaderboard/views/leaderboard_view.dart';
import '../../features/settings/controllers/settings_controller.dart';
import '../../features/settings/views/settings_view.dart';
import '../../features/profile/controllers/profile_controller.dart';
import '../../features/profile/views/profile_view.dart';
import '../../features/menu/views/mode_details_view.dart';
import '../../features/league/views/league_hub_view.dart';
import '../../features/league/views/league_group_view.dart';
import '../../features/league/views/my_league_history_view.dart';
import '../../features/league/views/league_attempt_selector_view.dart';
import '../../features/league/bindings/league_binding.dart';
import '../../features/hall_of_fame/controllers/hall_of_fame_controller.dart';
import '../../features/hall_of_fame/views/hall_of_fame_view.dart';
import '../../features/hall_of_fame/views/season_detail_view.dart';
import '../../features/wallet/controllers/wallet_controller.dart';
import '../../features/wallet/views/coin_history_view.dart';
import '../../features/cosmetics/controllers/cosmetics_controller.dart';
import '../../features/shop/views/skin_shop_view.dart';
import '../../features/daily_mission/views/daily_mission_view.dart';
import '../../features/splash/bindings/splash_binding.dart';
import '../../features/splash/views/splash_view.dart';

/// Named routes for the Snake game.
class AppRoutes {
  static const String splash = '/splash';
  static const String menu = '/menu';
  static const String game = '/game';
  static const String levelSelect = '/level-select';
  static const String leaderboard = '/leaderboard';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String modeDetails = '/mode-details';
  static const String league = '/league';
  static const String leagueGroup = '/league/group';
  static const String leagueAttemptSelector = '/league/attempt-selector';
  static const String hallOfFame = '/hall-of-fame';
  static const String seasonDetail = '/season-detail';
  static const String myLeagueHistory = '/my-league-history';
  static const String walletHistory = '/wallet/history';
  static const String shop = '/shop';
  static const String dailyMission = '/daily-mission';

  static List<GetPage> routes = [
    GetPage(
      name: splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: menu,
      page: () => const MenuView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<MenuController>(() => MenuController());
      }),
    ),
    GetPage(
      name: game,
      page: () => const GameView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<GameController>(() => GameController());
      }),
    ),
    GetPage(
      name: levelSelect,
      page: () => const LevelSelectionView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<LevelController>(() => LevelController());
      }),
    ),
    GetPage(
      name: leaderboard,
      page: () => const LeaderboardView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<LeaderboardController>(() => LeaderboardController());
      }),
    ),
    GetPage(
      name: settings,
      page: () => const SettingsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SettingsController>(() => SettingsController());
      }),
    ),
    GetPage(
      name: profile,
      page: () => const ProfileView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ProfileController>(() => ProfileController());
      }),
    ),
    GetPage(
      name: modeDetails,
      page: () => const ModeDetailsView(),
    ),
    GetPage(
      name: league,
      page: () => const LeagueHubView(),
      binding: LeagueBinding(),
    ),
    GetPage(
      name: hallOfFame,
      page: () => const HallOfFameView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HallOfFameController>(() => HallOfFameController());
      }),
    ),
    GetPage(
      name: seasonDetail,
      page: () => const SeasonDetailView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HallOfFameController>(() => HallOfFameController());
      }),
    ),
    GetPage(
      name: myLeagueHistory,
      page: () => const MyLeagueHistoryView(),
      binding: LeagueBinding(),
    ),
    GetPage(
      name: walletHistory,
      page: () => const CoinHistoryView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<WalletController>(() => WalletController());
      }),
    ),
    GetPage(
      name: shop,
      page: () => const SkinShopView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<CosmeticsController>(() => CosmeticsController());
        Get.lazyPut<WalletController>(() => WalletController());
      }),
    ),
    GetPage(
      name: leagueGroup,
      page: () => const LeagueGroupView(isEmbedded: false),
      binding: LeagueBinding(),
    ),
    GetPage(
      name: leagueAttemptSelector,
      page: () => const LeagueAttemptSelectorView(),
      binding: LeagueBinding(),
    ),
    GetPage(
      name: dailyMission,
      page: () => const DailyMissionView(),
    ),
  ];
}
