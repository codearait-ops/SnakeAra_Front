import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snake_game/app/core/utils/enums.dart';
import 'package:snake_game/features/auth/controllers/auth_controller.dart';
import 'package:snake_game/features/auth/controllers/game_session_controller.dart';
import 'package:snake_game/features/daily_mission/controllers/daily_mission_controller.dart';
import 'package:snake_game/features/levels/controllers/level_controller.dart';
import 'package:snake_game/features/wallet/controllers/wallet_controller.dart';
import 'package:snake_game/features/leaderboard/models/league_leaderboard_entry.dart';
import 'package:snake_game/features/game/widgets/level_up_dialog.dart';
import 'package:snake_game/services/api_service.dart';
import 'package:snake_game/services/game_event_logger.dart';
import 'package:snake_game/services/storage_service.dart';

/// Coordinates game-over and level-complete score submission, wallet synchronization,
/// XP progression, and backend session finalization.
class GameSessionCoordinator {
  /// Handles the level complete submission, XP reward, coins sync, and unlock marking.
  Future<void> handleLevelComplete({
    required int currentLevel,
    required int applesEaten,
    required RxInt earnedXp,
    required RxBool levelCoinAwarded,
    required RxInt levelCoinsAwarded,
  }) async {
    final levelController = Get.find<LevelController>();
    final bool isReplay = levelController.isLevelCompleted(currentLevel);
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🏆 [SnakeGame] _levelComplete called!');
    debugPrint('   - currentLevel: $currentLevel');
    debugPrint('   - isReplay: $isReplay');
    debugPrint(
      '   - isLoggedIn: ${Get.find<AuthController>().isLoggedIn.value}',
    );
    debugPrint('   - sessionId: ${Get.find<GameEventLogger>().sessionId}');
    debugPrint('═══════════════════════════════════════════════════════════');
    levelController.markLevelCompleted(currentLevel);

    earnedXp.value = 0;
    levelCoinAwarded.value = false;
    levelCoinsAwarded.value = 0;

    // Replay of an already cleared level
    if (isReplay) {
      debugPrint(
        '[SnakeGame] ⚠️ Level $currentLevel replayed: submitting replay to server...',
      );
      final auth = Get.find<AuthController>();
      if (auth.isLoggedIn.value && auth.currentUser.value != null) {
        final logger = Get.find<GameEventLogger>();
        final effectiveSessionId =
            logger.sessionId ??
            'replay_${DateTime.now().millisecondsSinceEpoch}';
        final api = Get.find<ApiService>();
        api
            .submitLevelComplete(
              sessionId: effectiveSessionId,
              levelId: currentLevel,
              applesEaten: applesEaten,
              token: auth.currentUser.value!.token,
              userId: auth.currentUser.value!.id,
              isReplay: true,
            )
            .then((response) {
              debugPrint(
                '[SnakeGame] 🏆 Replay response: coinsAwarded=${response.coinsAwarded}, newBalance=${response.newBalance}',
              );
              final coins = response.coinsAwarded ?? 0;
              if (coins > 0) {
                levelCoinAwarded.value = true;
                levelCoinsAwarded.value = coins;
                if (Get.isRegistered<WalletController>()) {
                  Get.find<WalletController>().receiveCoins(
                    coins,
                    animate: true,
                    newServerBalance: response.newBalance,
                  );
                }
              } else if (response.newBalance != null &&
                  Get.isRegistered<WalletController>()) {
                Get.find<WalletController>().balance.value =
                    response.newBalance!;
              }
            })
            .catchError((e, st) {
              debugPrint(
                '❌ [SnakeGame] submitLevelComplete (replay) error: $e\n$st',
              );
            });
      }
      return;
    }

    // First-time Level completed (Win) -> Award XP & Coins
    final auth = Get.find<AuthController>();
    final api = Get.find<ApiService>();
    if (auth.isLoggedIn.value && auth.currentUser.value != null) {
      final logger = Get.find<GameEventLogger>();
      final effectiveSessionId =
          logger.sessionId ??
          'level_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint(
        '[SnakeGame] 🚀 Submitting level complete: level=$currentLevel, sessionId=$effectiveSessionId',
      );
      api
          .submitLevelComplete(
            sessionId: effectiveSessionId,
            levelId: currentLevel,
            applesEaten: applesEaten,
            token: auth.currentUser.value!.token,
            userId: auth.currentUser.value!.id,
            isReplay: false,
          )
          .then((response) {
            debugPrint(
              '[SnakeGame] 🏆 submitLevelComplete response: isSuccess=${response.isSuccess}, coinsAwarded=${response.coinsAwarded}, coinAwarded=${response.coinAwarded}, newBalance=${response.newBalance}',
            );
            if (response.isSuccess) {
              if (response.xp != null) {
                earnedXp.value = response.xp!.xpAwarded;
                auth.updateXpAndLevel(response.xp!);
                if (response.xp!.leveledUp) {
                  LevelUpDialog.show(response.xp!);
                }
              }

              // Level Mode Coin Reward verification from server (robust against missing boolean)
              final coins = response.coinsAwarded ?? 0;
              final isCoinAwarded =
                  response.coinAwarded == true || coins > 0;
              if (isCoinAwarded && coins > 0) {
                levelCoinAwarded.value = true;
                levelCoinsAwarded.value = coins;

                // Authoritative wallet balance sync via centralized receiveCoins funnel
                if (Get.isRegistered<WalletController>()) {
                  final wallet = Get.find<WalletController>();
                  wallet.receiveCoins(
                    coins,
                    animate: true,
                    newServerBalance: response.newBalance,
                  );
                }
              } else {
                // Server did not award coins
                levelCoinAwarded.value = false;
                levelCoinsAwarded.value = 0;
                if (response.newBalance != null &&
                    Get.isRegistered<WalletController>()) {
                  Get.find<WalletController>().balance.value =
                      response.newBalance!;
                }
              }
            } else if (response.isRejected) {
              Get.snackbar('error'.tr, 'err_validation'.tr);
            } else if (response.isSessionExpired) {
              Get.snackbar('error'.tr, 'session_expired_title'.tr);
            }
          })
          .catchError((e, st) {
            debugPrint(
              '❌ [SnakeGame] submitLevelComplete (win) error: $e\n$st',
            );
          });
    } else {
      // Guest player (not logged in) completing a new level
      earnedXp.value = 0;
      if (!isReplay) {
        const guestCoins = 10;
        levelCoinAwarded.value = true;
        levelCoinsAwarded.value = guestCoins;
        if (Get.isRegistered<WalletController>()) {
          Get.find<WalletController>().receiveCoins(
            guestCoins,
            animate: true,
          );
        }
      }
    }
  }

  /// Handles game-over event logging, score finalization, backend submission, and rewards.
  Future<void> handleGameOver({
    required GameOverReason reason,
    required GameMode gameMode,
    required int score,
    required int applesEaten,
    required int elapsedTimeSec,
    required bool isDailyMission,
    int? dailyMissionId,
    required String dailyMissionType,
    required bool isLeagueAttempt,
    Future<bool>? sessionStartFuture,
    required RxBool isNewHighscore,
    required RxInt earnedXp,
    required Rx<LeagueScoreResult?> leagueResult,
    required RxInt leagueAttemptsRemaining,
    required RxBool canPlayLeagueAttempt,
    required RxInt optimisticCasualCoins,
  }) async {
    final storage = Get.find<StorageService>();

    if (gameMode != GameMode.level) {
      Get.find<GameEventLogger>().logEvent('game_over', {
        'reason': reason.apiReason,
        'final_score': score,
        'apples_eaten': applesEaten,
        'time_survived_sec': elapsedTimeSec,
      });
    }

    // --- LEVEL MODE: No score, no records, XP only on win ---
    if (gameMode == GameMode.level) {
      isNewHighscore.value = false;
      earnedXp.value = 0;
      return;
    }

    // --- OTHER MODES (Classic, Infection, BlindMemory) ---

    // Daily Challenge unified API now handles submission automatically via logger

    // --- Award XP to Registered Players via server response ---
    final auth = Get.find<AuthController>();
    earnedXp.value = 0;

    final supportedModes = [
      GameMode.classic,
      GameMode.infection,
      GameMode.blindMemory,
      GameMode.laser,
      GameMode.meltdown,
      GameMode.crabChase,
      GameMode.casual,
    ];

    if (supportedModes.contains(gameMode)) {
      int submitValue = (gameMode == GameMode.infection)
          ? elapsedTimeSec
          : score;

      // Update in-memory (RAM only) session best score
      bool isNewSessionBest = false;
      if (Get.isRegistered<GameSessionController>()) {
        isNewSessionBest = Get.find<GameSessionController>().updateIfBetter(
          gameMode.name,
          submitValue,
        );
      } else {
        isNewSessionBest = storage.updateSessionBestScore(
          gameMode.name,
          submitValue,
        );
      }

      if (!auth.isLoggedIn.value && isNewSessionBest) {
        isNewHighscore.value = true;
      }

      // Daily Mission Submission
      if (isDailyMission && Get.isRegistered<DailyMissionController>()) {
        final missionController = Get.find<DailyMissionController>();
        final mType =
            missionController.currentMission.value?.type ?? dailyMissionType;
        final int rawStat = (mType == 'survive_time')
            ? elapsedTimeSec
            : (mType == 'eat_count' ? applesEaten : submitValue);
        final effectiveId = (dailyMissionId != null && dailyMissionId! > 0)
            ? dailyMissionId
            : missionController.currentMission.value?.id;

        debugPrint(
          '[SnakeGame] 🎯 Daily Mission GameOver Submit -> effectiveId: $effectiveId | rawStat: $rawStat | type: $mType',
        );

        missionController.submitMission(rawStat, missionId: effectiveId).then((
          res,
        ) {
          if (res != null && res.isCompleted) {
            Get.snackbar(
              'mission_completed_reward_title'.tr,
              'mission_completed_reward_desc'.trParams({
                'count': '${res.rewardCoins}',
              }),
              backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.95),
              colorText: Colors.black,
              snackPosition: SnackPosition.TOP,
              margin: const EdgeInsets.all(16),
              icon: const Icon(
                Icons.monetization_on_rounded,
                color: Colors.black,
              ),
            );
          }
        });
      }

      // Path A: Submit score to online backend (or dedicated league endpoint if isLeagueAttempt)
      // Note: Daily Mission uses dedicated /daily-mission/submit endpoint above.
      final logger = Get.find<GameEventLogger>();
      if (!isDailyMission &&
          auth.isLoggedIn.value &&
          auth.currentUser.value != null) {
        () async {
          // If session is still being initiated, await it to prevent skipping submission
          if (logger.sessionId == null && sessionStartFuture != null) {
            debugPrint(
              '[SnakeGame] ⏳ Waiting for session initialization before score submission...',
            );
            await sessionStartFuture;
          }

          if (logger.sessionId != null) {
            debugPrint(
              '🏆 [SnakeGame] Submitting score: value=$submitValue, isLeagueAttempt=$isLeagueAttempt, session=${logger.sessionId}',
            );
            final response = await logger.submitFinalScore(
              submitValue,
              isLeague: isLeagueAttempt,
            );
            if (response.isSuccess) {
              if (response.xp != null) {
                earnedXp.value = response.xp!.xpAwarded;
                auth.updateXpAndLevel(response.xp!);
                if (response.xp!.leveledUp) {
                  LevelUpDialog.show(response.xp!);
                }
              }
              if (response.league != null) {
                leagueResult.value = response.league;
              }
              if (response.attemptsRemaining != null) {
                leagueAttemptsRemaining.value = response.attemptsRemaining!;
                canPlayLeagueAttempt.value =
                    response.canRetry ?? (response.attemptsRemaining! > 0);
              }
              if (response.isNewHighscore) {
                Get.snackbar(
                  'new_record'.tr,
                  response.message ?? 'msg_score_updated'.tr,
                  backgroundColor: const Color(
                    0xFF4CAF50,
                  ).withValues(alpha: 0.9),
                  colorText: const Color(0xFFFFFFFF),
                  snackPosition: SnackPosition.TOP,
                  margin: const EdgeInsets.all(16),
                  icon: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                  ),
                );
              }
              if (response.leagueRankImproved) {
                Get.snackbar(
                  'league_title'.tr,
                  'rank_improved'.tr,
                  backgroundColor: Colors.amber.withValues(alpha: 0.9),
                  colorText: Colors.black,
                  snackPosition: SnackPosition.TOP,
                  margin: const EdgeInsets.all(16),
                  icon: const Icon(
                    Icons.trending_up_rounded,
                    color: Colors.black,
                  ),
                );
              }

              // Authoritative wallet balance sync from backend response via receiveCoins funnel
              if (Get.isRegistered<WalletController>()) {
                final wallet = Get.find<WalletController>();
                final coinsWon = response.coinsAwarded ?? 0;
                if (coinsWon > 0) {
                  wallet.receiveCoins(
                    coinsWon,
                    animate: true,
                    newServerBalance: response.newBalance,
                  );
                } else if (response.newBalance != null) {
                  wallet.balance.value = response.newBalance!;
                } else {
                  wallet.fetchWalletBalance();
                }
              }

              // Casual Mode: check server-confirmed coins against optimistic preview
              if (gameMode == GameMode.casual) {
                final confirmedCoins = response.coinsAwarded;
                if (confirmedCoins != null) {
                  if (confirmedCoins != optimisticCasualCoins.value) {
                    // Discrepancy between optimistic preview and server verification
                    optimisticCasualCoins.value = confirmedCoins;
                    Get.snackbar(
                      'notice'.tr,
                      'wallet_balance_updated'.tr,
                      backgroundColor: const Color(
                        0xFF00E5FF,
                      ).withValues(alpha: 0.9),
                      colorText: Colors.black,
                      snackPosition: SnackPosition.TOP,
                      margin: const EdgeInsets.all(16),
                      icon: const Icon(Icons.sync_rounded, color: Colors.black),
                    );
                  }
                }
              }
            } else if (response.isRejected) {
              if (response.message != null &&
                  response.message!.isNotEmpty &&
                  response.message != 'Invalid score payload') {
                Get.snackbar(
                  'league_ended_title'.tr,
                  response.message!,
                  backgroundColor: const Color(
                    0xFFFF9100,
                  ).withValues(alpha: 0.95),
                  colorText: Colors.black,
                  snackPosition: SnackPosition.TOP,
                  margin: const EdgeInsets.all(16),
                  icon: const Icon(Icons.info_outline, color: Colors.black),
                );
              }
            } else if (response.isNetworkError || response.isSessionExpired) {
              Get.snackbar(
                'error'.tr,
                response.message ?? 'err_score_update_failed'.tr,
                backgroundColor: const Color(0xFFFF1744).withValues(alpha: 0.9),
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
                margin: const EdgeInsets.all(16),
              );
            }
          }
        }();
      }
    }
  }
}
