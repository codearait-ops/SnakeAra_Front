import 'package:get/get.dart';
import '../../../app/core/utils/enums.dart';
import '../../../services/api_service.dart';
import '../../game/models/game_mode_config.dart';
import '../models/game_mode_leaderboard_entry.dart';
import '../models/league_leaderboard_entry.dart';

class LeaderboardController extends GetxController {
  final String initialMode;
  LeaderboardController({this.initialMode = 'classic'});

  final ApiService _api = Get.find<ApiService>();

  // Modes Tab State
  late final RxString selectedModeId = initialMode.obs;
  final RxList<GameModeLeaderboardEntry> modesEntries = <GameModeLeaderboardEntry>[].obs;
  final RxBool isLoadingModes = true.obs;
  final RxString modesErrorMessage = ''.obs;

  // League Tab State
  final RxList<LeagueLeaderboardEntry> leagueEntries = <LeagueLeaderboardEntry>[].obs;
  final RxBool isLoadingLeague = false.obs;
  final RxString leagueErrorMessage = ''.obs;

  List<GameModeConfig> get leaderboardGameModes =>
      availableGameModes.where((m) => m.mode != GameMode.level).toList();

  @override
  void onInit() {
    super.onInit();
    fetchModesLeaderboard(selectedModeId.value);
  }

  void selectMode(String modeId) {
    selectedModeId.value = modeId;
    fetchModesLeaderboard(modeId);
  }

  Future<void> fetchModesLeaderboard(String modeId) async {
    isLoadingModes.value = true;
    modesErrorMessage.value = '';
    modesEntries.clear();
    
    final config = availableGameModes.firstWhere(
      (m) => m.id == modeId || m.mode.name == modeId || m.mode.apiName == modeId, 
      orElse: () => availableGameModes.first,
    );
    
    final response = await _api.getModesLeaderboard(config.mode.apiName);
    
    isLoadingModes.value = false;
    if (response.isSuccess && response.data != null) {
      modesEntries.assignAll(response.data!);
    } else {
      modesErrorMessage.value = response.message ?? 'Failed to load data';
    }
  }

  Future<void> fetchLeagueLeaderboard() async {
    isLoadingLeague.value = true;
    leagueErrorMessage.value = '';

    final response = await _api.getLeagueLeaderboard();

    isLoadingLeague.value = false;
    if (response.isSuccess && response.data != null) {
      leagueEntries.assignAll(response.data!);
    } else {
      leagueErrorMessage.value = response.message ?? 'Failed to load data';
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchModesLeaderboard(selectedModeId.value),
      fetchLeagueLeaderboard(),
    ]);
  }
}
