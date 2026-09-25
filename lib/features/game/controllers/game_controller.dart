import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snake_game/features/game/components/snake_game.dart';
import 'package:snake_game/features/game/models/casual_mode_models.dart';
import '../../../app/core/utils/enums.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../settings/controllers/settings_controller.dart';
import '../models/game_mode_config.dart';

/// GetX controller that wraps the [SnakeGame] and provides reactive state
/// for Flutter overlay widgets (HUD, pause, game over, level complete).
class GameController extends GetxController {
  final SnakeGame snakeGame = SnakeGame();

  // --- Reactive state proxied from SnakeGame ---
  Rx<GameMode> get gameMode => snakeGame.gameMode;
  Rx<GameStatus> get gameStatus => snakeGame.gameStatus;
  RxInt get score => snakeGame.score;
  RxBool get isNewHighscore => snakeGame.isNewHighscore;
  RxInt get earnedXp => snakeGame.earnedXp;
  Rx<LeagueScoreResult?> get leagueResult => snakeGame.leagueResult;
  RxInt get applesCount => snakeGame.applesCount;
  RxInt get appleTarget => snakeGame.appleTargetRx;
  RxInt get pearsCount => snakeGame.pearsCount;
  RxInt get pearScore => snakeGame.pearScore;
  RxInt get timeRemaining => snakeGame.timeRemaining;
  RxInt get elapsedTime => snakeGame.elapsedTime;
  RxInt get currentLevel => snakeGame.currentLevelRx;
  int get levelNumber => currentLevel.value;
  RxBool get showLevelComplete => snakeGame.showLevelComplete;
  Rx<GameOverReason?> get gameOverReason => snakeGame.gameOverReason;
  RxInt get casualLives => snakeGame.casualLives;

  // --- Visual effects ---
  RxDouble get shakeOffsetX => snakeGame.shakeOffsetX;
  RxDouble get shakeOffsetY => snakeGame.shakeOffsetY;
  RxBool get showEatEffect => snakeGame.showEatEffect;

  // --- Mode Intro Dialog State ---
  final RxBool isIntroShowing = false.obs;
  late String currentModeKey;
  String activeIntroKey = '';

  GameModeConfig get currentModeConfig {
    if (gameMode.value == GameMode.level && snakeGame.isBossLevelRx.value) {
      final bossIndex = (snakeGame.currentLevelRx.value ~/ 10).clamp(1, 5);
      return GameModeConfig.forBoss(bossIndex);
    }
    if (activeIntroKey.startsWith('boss_') || currentModeKey.startsWith('boss_')) {
      final key = activeIntroKey.startsWith('boss_') ? activeIntroKey : currentModeKey;
      final bossIndex = int.tryParse(key.replaceFirst('boss_', '')) ?? 1;
      return GameModeConfig.forBoss(bossIndex);
    }
    return availableGameModes.firstWhere(
      (c) => c.id == currentModeKey || c.mode == gameMode.value,
      orElse: () => availableGameModes.first,
    );
  }

  // --- Casual Mode Proxies ---
  Rx<PowerUpType?> get casualActivePowerUp => snakeGame.casualActivePowerUp;
  RxDouble get casualPowerUpTimeRemaining =>
      snakeGame.casualPowerUpTimeRemaining;

  @override
  void onInit() {
    super.onInit();

    snakeGame.onBossIntroRequested = showBossIntroIfNeeded;

    final args = Get.arguments;
    if (args is Map) {
      snakeGame.isDailyMission =
          args['isDailyMission'] == true || args['isDailyChallenge'] == true;
      if (args['dailyMissionId'] != null) {
        snakeGame.dailyMissionId = args['dailyMissionId'] as int;
      } else if (args['dailyChallengeId'] != null) {
        snakeGame.dailyMissionId = args['dailyChallengeId'] as int;
      }
      if (args['attemptNumber'] != null) {
        snakeGame.dailyMissionAttempt = args['attemptNumber'] as int;
      }
      if (args['dailyMissionType'] != null) {
        snakeGame.dailyMissionType = args['dailyMissionType'].toString();
      }
      if (args['dailyMissionTarget'] != null) {
        snakeGame.dailyMissionTarget = (args['dailyMissionTarget'] as num)
            .toInt();
      }
      if (args['dailyMissionReward'] != null) {
        snakeGame.dailyMissionReward = (args['dailyMissionReward'] as num)
            .toInt();
      }
      if (args['isAdRetry'] != null) {
        snakeGame.isAdRetry = args['isAdRetry'] as bool;
      }

      snakeGame.isLeagueAttempt = args['isLeagueAttempt'] == true;
      if (args['attemptsRemaining'] != null) {
        snakeGame.leagueAttemptsRemaining.value =
            (args['attemptsRemaining'] as num).toInt();
        snakeGame.canPlayLeagueAttempt.value =
            snakeGame.leagueAttemptsRemaining.value > 0;
      }
      if (args['seed'] != null && args['seed'] is int) {
        snakeGame.gameSeed = args['seed'];
      }
    }

    final mode = args is Map ? args['mode']?.toString() : null;
    debugPrint(
      '================= 🎮 [GameController.onInit] =================',
    );
    debugPrint(
      'mode: $mode | isDailyChallenge: ${snakeGame.isDailyChallenge} | dailyMissionId: ${snakeGame.dailyMissionId} | attempt: ${snakeGame.dailyMissionAttempt}',
    );
    debugPrint(
      'type: ${snakeGame.dailyMissionType} | target: ${snakeGame.dailyMissionTarget} | reward: ${snakeGame.dailyMissionReward} | seed: ${snakeGame.gameSeed}',
    );

    int level = 1;
    if (args is Map && args['level'] is int) {
      level = args['level'];
    } else if (args is int) {
      level = args;
    }

    final bool isLevelMode = (mode == 'level' || args is int || (args is Map && args['level'] != null));
    final bool isBossLevel = isLevelMode && (level % 10 == 0);

    currentModeKey = (mode == 'crab_chase' || mode == 'crab')
        ? 'crabChase'
        : (mode == 'blind_memory'
              ? 'blindMemory'
              : (mode == 'laser_core'
                    ? 'laser'
                    : (mode == 'casual'
                          ? 'casual'
                          : (isBossLevel
                              ? 'boss_${(level ~/ 10).clamp(1, 5)}'
                              : (mode ?? (args is int ? 'level' : 'classic'))))));

    activeIntroKey = currentModeKey;

    final storage = Get.isRegistered<StorageService>()
        ? Get.find<StorageService>()
        : null;
    final bool shouldShowIntro = isLevelMode
        ? (isBossLevel
            ? (storage?.shouldShowModeIntro(activeIntroKey) ?? true)
            : false)
        : (storage?.shouldShowModeIntro(activeIntroKey) ?? true);
    if (shouldShowIntro) {
      isIntroShowing.value = true;
      snakeGame.isIntroWaiting = true;
      snakeGame.pauseEngine();
    } else {
      isIntroShowing.value = false;
      snakeGame.isIntroWaiting = false;
    }

    if (mode == 'infection') {
      snakeGame.initInfection();
    } else if (mode == 'casual') {
      snakeGame.initCasual();
    } else if (mode == 'blindMemory' || mode == 'blind_memory') {
      snakeGame.initBlindMemory();
    } else if (mode == 'laser' || mode == 'laser_core') {
      snakeGame.initLaser();
    } else if (mode == 'meltdown') {
      snakeGame.initMeltdown();
    } else if (mode == 'crab_chase' || mode == 'crabChase' || mode == 'crab') {
      snakeGame.initCrabChase();
    } else if (mode == 'classic') {
      snakeGame.initClassic();
    } else if (mode == 'level' || args is int || (args is Map && args['level'] != null)) {
      snakeGame.initLevel(level);
    } else {
      snakeGame.initClassic();
    }

    if (shouldShowIntro) {
      snakeGame.pauseEngine();
    }

    // Increment play count in storage for Donut Chart tracking
    if (storage != null) {
      storage.incrementPlayCount(currentModeKey);
    }
  }

  /// Triggers boss intro dialog when advancing or entering a boss level.
  void showBossIntroIfNeeded(int level) {
    final bossIndex = (level ~/ 10).clamp(1, 5);
    final key = 'boss_$bossIndex';
    activeIntroKey = key;
    final storage = Get.isRegistered<StorageService>()
        ? Get.find<StorageService>()
        : null;
    final bool shouldShow = storage?.shouldShowModeIntro(key) ?? true;
    if (shouldShow) {
      isIntroShowing.value = true;
      snakeGame.isIntroWaiting = true;
      snakeGame.pauseEngine();
    } else {
      isIntroShowing.value = false;
      snakeGame.isIntroWaiting = false;
    }
  }

  /// Dismiss the mode intro dialog and begin/resume gameplay.
  void startGameAfterIntro({required bool dontShowAgain}) =>
      dismissIntro(dontShowAgain: dontShowAgain);

  /// Dismiss the mode intro dialog and begin/resume gameplay.
  void dismissIntro({required bool dontShowAgain}) {
    if (dontShowAgain && Get.isRegistered<StorageService>()) {
      final keyToHide = activeIntroKey.isNotEmpty ? activeIntroKey : currentModeKey;
      Get.find<StorageService>().setHideModeIntro(keyToHide, true);
    }
    debugPrint(
      '[GameController] 🚀 dismissIntro: key=$activeIntroKey, dontShowAgain=$dontShowAgain',
    );
    isIntroShowing.value = false;
    snakeGame.isIntroWaiting = false;
    snakeGame.resumeGame();
  }

  /// Queue a direction change to the game.
  void changeDirection(Direction dir) {
    snakeGame.queueDirection(dir);
  }

  /// Toggle pause/resume.
  void togglePause() => snakeGame.togglePause();

  /// Cycle audio states (Both -> SFX only -> Muted -> Both).
  void cycleAudioMode() {
    if (Get.isRegistered<SettingsController>()) {
      final settings = Get.find<SettingsController>();
      settings.cycleAudioMode(
        onMusicEnabled: () {
          snakeGame.playModeBgm();
        },
      );
    }
  }

  /// Restart the game session.
  void restartGame() => snakeGame.restartLevel();

  /// Go to the next level.
  void nextLevel() => snakeGame.nextLevel();

  /// Go back to the menu.
  void goToMenu() => snakeGame.goToMenu();

  @override
  void onClose() {
    snakeGame.onRemove();
    super.onClose();
  }
}
