import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/game_event_logger.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../../wallet/controllers/wallet_controller.dart';
import '../../controllers/game_controller.dart';
import '../level_up_dialog.dart';

/// Phase 2 Offline Retry Banner shown when a score submission failed and is pending.
class GameOverRetryBanner extends StatelessWidget {
  final GameController controller;

  const GameOverRetryBanner({super.key, required this.controller});

  Future<void> _handleRetryScore(GameController controller) async {
    if (!Get.isRegistered<GameEventLogger>()) return;
    final logger = Get.find<GameEventLogger>();
    final auth = Get.find<AuthController>();

    final response = await logger.retryPendingScore();
    if (response == null) return;

    if (response.isSuccess) {
      if (response.xp != null) {
        controller.earnedXp.value = response.xp!.xpAwarded;
        auth.updateXpAndLevel(response.xp!);
        if (response.xp!.leveledUp) {
          LevelUpDialog.show(response.xp!);
        }
      }
      if (response.league != null) {
        controller.snakeGame.leagueResult.value = response.league;
      }
      if (response.attemptsRemaining != null) {
        controller.snakeGame.leagueAttemptsRemaining.value =
            response.attemptsRemaining!;
        controller.snakeGame.canPlayLeagueAttempt.value =
            response.canRetry ?? (response.attemptsRemaining! > 0);
      }
      if (response.isNewHighscore) {
        controller.isNewHighscore.value = true;
      }
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
      Get.snackbar(
        'success'.tr,
        response.message ?? 'score_submitted_success'.tr,
        backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.cloud_done_rounded, color: Colors.white),
      );
    } else if (response.isNetworkError) {
      Get.snackbar(
        'error'.tr,
        response.message ?? 'err_score_update_failed'.tr,
        backgroundColor: const Color(0xFFFF1744).withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.cloud_off_rounded, color: Colors.white),
      );
    } else {
      Get.snackbar(
        'error'.tr,
        response.message ?? 'err_score_update_failed'.tr,
        backgroundColor: const Color(0xFFFF1744).withValues(alpha: 0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<GameEventLogger>()) {
      return const SizedBox.shrink();
    }

    final logger = Get.find<GameEventLogger>();

    return Obx(() {
      if (!logger.hasPendingSubmission.value) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Colors.amber,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'score_retry_banner_title'.tr,
                    style: GoogleFonts.vazirmatn(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'score_retry_banner_desc'.tr,
                    style: GoogleFonts.vazirmatn(
                      color: Colors.white70,
                      fontSize: 10.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: logger.isRetryingSubmission.value
                  ? null
                  : () => _handleRetryScore(controller),
              icon: logger.isRetryingSubmission.value
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 15),
              label: Text(
                'score_retry_btn'.tr,
                style: GoogleFonts.vazirmatn(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
