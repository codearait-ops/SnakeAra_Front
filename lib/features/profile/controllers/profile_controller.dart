import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snake_game/services/api_service.dart';
import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/utils/enums.dart';
import '../../../services/league_api_service.dart';
import '../../../services/storage_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/controllers/game_session_controller.dart';
import '../../game/models/game_mode_config.dart';
import '../../hall_of_fame/models/hall_of_fame_models.dart';
import '../../league/models/league_models.dart';
import '../models/universal_player_profile.dart';
import '../models/profile_full_model.dart';

/// GetX controller for redesigned compact, dark-mode Profile screen.
class ProfileController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final AuthController authController = Get.find<AuthController>();

  // Cached Universal Player Profile from backend
  final Rx<UniversalPlayerProfile?> userProfile = Rx<UniversalPlayerProfile?>(
    null,
  );

  // Cached Full Player Profile (single-call)
  final Rx<ProfileMeFullResponse?> fullProfile = Rx<ProfileMeFullResponse?>(null);
  final Rx<LeagueMedalsSummary?> leagueMedals = Rx<LeagueMedalsSummary?>(null);
  final RxInt missionsCompletedTotal = 0.obs;
  final RxString errorMessage = ''.obs;

  // High score map by mode ID
  final RxMap<String, int> modeScores = <String, int>{}.obs;

  // Play count map by mode ID for Donut Chart
  final RxMap<String, int> modePlayCounts = <String, int>{}.obs;

  // Selected game mode for interactive chart and cards highlighting
  final RxString selectedSpecialMode = ''.obs;

  // Player XP & Level observables
  final RxInt playerXp = 0.obs;
  final RxInt playerLevel = 1.obs;
  final RxInt xpForNextLevel = 0.obs;
  final RxDouble levelProgress = 0.0.obs;
  final RxInt currentLevelXp = 0.obs;
  final RxInt currentLevelSpan = 0.obs;

  // Level mode progress
  final RxInt unlockedLevel = 1.obs;

  // Weekly League History & Medals
  final RxList<LeagueHistoryEntry> leagueHistory = <LeagueHistoryEntry>[].obs;
  final RxList<PlayerMedal> playerMedals = <PlayerMedal>[].obs;
  final RxBool isLoadingLeagueHistory = false.obs;

  // Global League Hall of Fame (All past seasons & overall champions)
  final RxList<HallOfFameEntry> hallOfFameSeasons = <HallOfFameEntry>[].obs;
  final RxBool isLoadingHallOfFame = false.obs;

  // Tab state (0: My Profile & Records, 1: League Hall of Fame)
  final RxInt selectedTabIndex = 0.obs;

  // Weekly League Mode Champions (best player in each mode for current week)
  final RxList<ModeBadge> weeklyModeChampions = <ModeBadge>[].obs;

  // Overall profile loading state
  final RxBool isLoadingProfile = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
    // Lazy-load Hall of Fame history only once when user switches to Tab 1
    ever(selectedTabIndex, (index) {
      if (index == 1 &&
          hallOfFameSeasons.isEmpty &&
          !isLoadingHallOfFame.value) {
        fetchLeagueHistory();
      }
    });
  }

  /// Initial load: fetch full profile in a single call (GET /profile/me/full)
  Future<void> fetchInitialData({bool forceRefresh = false}) async {
    if (!forceRefresh && fullProfile.value != null) {
      return;
    }
    isLoadingProfile.value = true;
    errorMessage.value = '';
    try {
      if (authController.isLoggedIn.value) {
        await fetchProfileMeFull(forceRefresh: forceRefresh);
      } else {
        loadProfileData();
      }
    } catch (e) {
      debugPrint('[ProfileController] Error fetching initial profile data: $e');
      errorMessage.value = e.toString();
      loadProfileData();
    } finally {
      isLoadingProfile.value = false;
    }
  }

  /// Single-call full profile fetch (GET /profile/me/full).
  Future<void> fetchProfileMeFull({bool forceRefresh = false}) async {
    final token = authController.currentUser.value?.token;
    if (token == null || token.isEmpty) {
      loadProfileData();
      return;
    }

    if (!forceRefresh && fullProfile.value != null) {
      return;
    }

    try {
      final api = Get.find<ApiService>();
      final res = await api.getProfileMeFull(token: token);

      if (res.isSuccess && res.data != null) {
        final data = res.data!;
        fullProfile.value = data;

        // 1. Update authenticated user
        authController.currentUser.value = data.user;

        // 2. XP & Level directly from authoritative server user
        final user = data.user;
        playerXp.value = user.xpTotal;
        playerLevel.value = user.level;
        xpForNextLevel.value = user.nextLevelXp ?? 0;

        _updateLevelProgress(user.nextLevelXp);

        // 3. Map Mode records
        final Map<String, int> scores = {};
        final Map<String, int> playCounts = {};

        for (final rec in data.modeRecords) {
          final cfg = GameModeConfig.findByModeString(rec.gameMode);
          final canonicalId = cfg?.id ?? rec.gameMode;

          scores[canonicalId] = rec.bestValue;
          scores[rec.gameMode] = rec.bestValue;
          playCounts[canonicalId] = rec.playCount;
          playCounts[rec.gameMode] = rec.playCount;

          if (cfg != null) {
            scores[cfg.mode.name] = rec.bestValue;
            playCounts[cfg.mode.name] = rec.playCount;
          }
        }

        // Always include level progress
        final lastLevel = _storage.getLastUnlockedLevel();
        scores['level'] = lastLevel;
        unlockedLevel.value = lastLevel;

        modeScores.assignAll(scores);
        modePlayCounts.assignAll(playCounts);

        // 4. League Medals & Missions
        leagueMedals.value = data.leagueMedals;
        missionsCompletedTotal.value = data.missionsCompletedTotal;

        final medals = <PlayerMedal>[];
        for (int i = 0; i < data.leagueMedals.gold; i++) {
          medals.add(PlayerMedal(season: 0, medalType: 'gold'));
        }
        for (int i = 0; i < data.leagueMedals.silver; i++) {
          medals.add(PlayerMedal(season: 0, medalType: 'silver'));
        }
        for (int i = 0; i < data.leagueMedals.bronze; i++) {
          medals.add(PlayerMedal(season: 0, medalType: 'bronze'));
        }
        playerMedals.assignAll(medals);

        // Load daily challenges fallback if needed
        loadProfileData();
      } else {
        errorMessage.value = res.message ?? 'Failed to load profile';
        loadProfileData();
      }
    } catch (e) {
      debugPrint('[ProfileController] Error in fetchProfileMeFull: $e');
      errorMessage.value = e.toString();
      loadProfileData();
    }
  }

  /// Full refresh of profile data
  Future<void> refreshProfile() async {
    await fetchInitialData(forceRefresh: true);
    if (selectedTabIndex.value == 1) {
      await fetchLeagueHistory(forceRefresh: true);
    }
  }

  /// Helper to get a score for a specific game mode ID / enum
  int getModeScore(String modeId, [GameMode? mode]) {
    return _getScoreFromMap(modeScores, modeId, mode);
  }

  /// Helper to get a play count for a specific game mode ID / enum
  int getModePlayCount(String modeId, [GameMode? mode]) {
    return _getScoreFromMap(modePlayCounts, modeId, mode);
  }

  /// Helper to get a score/count from a map using direct, normalized, and alias lookups
  int _getScoreFromMap(Map<String, int> map, String modeId, [GameMode? mode]) {
    if (map.containsKey(modeId)) {
      return map[modeId] ?? 0;
    }

    String normalize(String s) {
      final n = s.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
      if (n == 'laser' || n == 'lasercore') return 'lasercore';
      if (n == 'blindmemory' || n == 'blind' || n == 'memory')
        return 'blindmemory';
      if (n == 'crab' || n == 'crabchase') return 'crab';
      if (n == 'casual' || n == 'adventure') return 'casual';
      return n;
    }

    final targetNormalized = normalize(modeId);
    final targetApiName = mode != null
        ? normalize(mode.apiName)
        : targetNormalized;

    for (final entry in map.entries) {
      final entryNormalized = normalize(entry.key);
      if (entryNormalized == targetNormalized ||
          entryNormalized == targetApiName) {
        return entry.value;
      }
    }
    return 0;
  }

  /// Fallback session best score for guest / offline mode
  int _getSessionFallbackScore(String modeKey) {
    if (Get.isRegistered<GameSessionController>()) {
      final sessionController = Get.find<GameSessionController>();
      final score = sessionController.bestFor(modeKey);
      if (score > 0) return score;
      final normalized = modeKey.toLowerCase().replaceAll('_', '');
      for (final entry in sessionController.sessionBestByMode.entries) {
        if (entry.key.toLowerCase().replaceAll('_', '') == normalized) {
          return entry.value;
        }
      }
    }
    return _storage.getSessionBestScore(modeKey);
  }

  /// Fetch universal player profile with authoritative best_scores from backend
  Future<void> fetchUniversalProfile() async {
    final user = authController.currentUser.value;
    final userId = int.tryParse(user?.id ?? '') ?? 0;
    if (userId > 0) {
      try {
        final api = Get.find<ApiService>();
        final response = await api.getPlayerProfile(userId);
        if (response.isSuccess && response.data != null) {
          userProfile.value = response.data;
          final medals = response.data!.dailyChallengeMedals;
          final missions = medals['completed_count'] ??
              medals['missions_completed_total'] ??
              medals['completed_missions'];
          if (missions != null && missionsCompletedTotal.value == 0) {
            final parsed = missions is num
                ? missions.toInt()
                : (int.tryParse(missions.toString()) ?? 0);
            if (parsed > 0) {
              missionsCompletedTotal.value = parsed;
            }
          }
          loadProfileData();
        }
      } catch (e) {
        debugPrint('[ProfileController] Error fetching universal profile: $e');
      }
    }
  }

  /// Refresh and load all highscores, XP stats, daily challenges, and achievements.
  void loadProfileData() {
    // 1. Player XP & Level directly from authoritative server user
    final user = authController.currentUser.value;
    if (user != null) {
      playerXp.value = user.xpTotal;
      playerLevel.value = user.level;
      xpForNextLevel.value = user.nextLevelXp ?? 0;
    } else {
      playerXp.value = _storage.getPlayerXp();
      playerLevel.value = _storage.getPlayerLevel();
      xpForNextLevel.value = _storage.getXpForNextLevel();
    }

    final nextXp = xpForNextLevel.value;
    _updateLevelProgress(nextXp > 0 ? nextXp : null);

    // 2. Load mode high scores & play counts (fallback if fullProfile not present)
    if (fullProfile.value != null &&
        fullProfile.value!.modeRecords.isNotEmpty) {
      // modeScores and modePlayCounts are already authoritatively loaded from fullProfile (mode_records)
    } else {
      final Map<String, int> scores = {};
      final Map<String, int> playCounts = {};
      final backendBestScores = userProfile.value?.bestScores;
      final backendPlayCounts = userProfile.value?.playCounts;

      for (final modeConfig in availableGameModes) {
        if (modeConfig.mode == GameMode.level) {
          scores[modeConfig.id] = _storage.getLastUnlockedLevel();
        } else {
          int s = 0;
          if (authController.isLoggedIn.value &&
              backendBestScores != null &&
              backendBestScores.isNotEmpty) {
            // Authoritative backend best score for authenticated users
            s = _getScoreFromMap(
              backendBestScores,
              modeConfig.id,
              modeConfig.mode,
            );
          } else {
            // Guest / offline session fallback
            s = _getSessionFallbackScore(modeConfig.mode.name);
            if (s == 0) {
              s = _getSessionFallbackScore(modeConfig.id);
            }
          }
          scores[modeConfig.id] = s;

          int count = 0;
          if (backendPlayCounts != null && backendPlayCounts.isNotEmpty) {
            // Authoritative backend play counts
            count = _getScoreFromMap(
              backendPlayCounts,
              modeConfig.id,
              modeConfig.mode,
            );
          } else {
            count =
                _storage.prefs.getInt('play_count_${modeConfig.id}') ??
                (s > 0 ? 1 : 0);
          }
          playCounts[modeConfig.id] = count;
        }
      }
      if (!mapEquals(modeScores, scores)) {
        modeScores.assignAll(scores);
      }
      if (!mapEquals(modePlayCounts, playCounts)) {
        modePlayCounts.assignAll(playCounts);
      }
    }
    unlockedLevel.value = _storage.getLastUnlockedLevel();

  }

  /// Fetch weekly league history and medals from backend
  Future<void> fetchLeagueHistory({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        hallOfFameSeasons.isNotEmpty &&
        leagueHistory.isNotEmpty) {
      return;
    }

    isLoadingLeagueHistory.value = true;
    isLoadingHallOfFame.value = true;
    try {
      final leagueApi = Get.find<LeagueApiService>();

      // Fetch global Hall of Fame past seasons
      final hofRes = await leagueApi.getHallOfFame();
      if (hofRes.isSuccess && hofRes.data != null) {
        hallOfFameSeasons.value = hofRes.data!;
      }

      final token = authController.currentUser.value?.token;
      if (token != null && token.isNotEmpty) {
        final res = await leagueApi.getMyLeagueHistory(token);
        if (res.isSuccess && res.data != null) {
          leagueHistory.value = res.data!;
        }
      }
    } catch (e) {
      debugPrint('Error fetching league history: $e');
    } finally {
      isLoadingLeagueHistory.value = false;
      isLoadingHallOfFame.value = false;
    }
  }

  void _updateLevelProgress(int? nextXp) {
    final info = calculateLevelProgress(
      xp: playerXp.value,
      level: playerLevel.value,
      nextLevelXp: (nextXp != null && nextXp > 0) ? nextXp : null,
    );
    currentLevelXp.value = info.currentLevelXp;
    currentLevelSpan.value = info.levelSpan;
    levelProgress.value = info.progress;
  }
}
