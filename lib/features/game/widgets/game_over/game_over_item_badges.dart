import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/core/constants/app_constants.dart';
import '../../../../app/core/utils/enums.dart';
import '../../../../services/storage_service.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../../auth/controllers/game_session_controller.dart';
import '../../controllers/game_controller.dart';

/// Item collection badges (apples, pears, coins) and session records.
class GameOverItemBadges extends StatelessWidget {
  final GameController controller;

  const GameOverItemBadges({super.key, required this.controller});

  String _formatSurvivalTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    if (m > 0) {
      return '${m}m ${s}s';
    }
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final storage = Get.find<StorageService>();
    final sessionController = Get.isRegistered<GameSessionController>()
        ? Get.find<GameSessionController>()
        : null;
    final isLoggedIn = auth.isLoggedIn.value && auth.currentUser.value != null;
    final sessionBest =
        sessionController?.bestFor(controller.gameMode.value.name) ??
        storage.getSessionBestScore(controller.gameMode.value.name);

    final isClassic = controller.gameMode.value == GameMode.classic;
    final isInfection = controller.gameMode.value == GameMode.infection;
    final isBlindMemory = controller.gameMode.value == GameMode.blindMemory;
    final isNewRecord = controller.isNewHighscore.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 4. Item stats
        if (isBlindMemory) ...[
          Text(
            'blind_memory_loss_msg'.tr,
            style: TextStyle(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.45),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: Color(0xFF00E5FF),
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatSurvivalTime(controller.elapsedTime.value),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: kFoodColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: kFoodColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🍎', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      '${controller.applesCount.value} ${'apples'.tr}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ] else if (isInfection) ...[
          Text(
            'infection_loss_msg'.tr,
            style: TextStyle(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.45),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: kFoodColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: kFoodColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🍎', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Text(
                  '${controller.applesCount.value} ${'apples_consumed'.tr}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ] else if (isClassic) ...[
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: kFoodColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: kFoodColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🍎', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      '${controller.applesCount.value} Apples',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: kGoldColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: kGoldColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🍐', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      '${controller.pearsCount.value} Pears (+${controller.pearScore.value} pts)',
                      style: const TextStyle(
                        color: kGoldColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ] else if (controller.gameMode.value == GameMode.casual) ...[
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: kFoodColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: kFoodColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🍎', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      '${controller.applesCount.value} ${'apples'.tr}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Obx(() {
                final coins =
                    controller.snakeGame.optimisticCasualCoins.value;
                if (coins <= 0) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(
                        '+$coins ${'coins_count_label'.trParams({'count': ''}).trim()}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 14),
        ] else ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🍎', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                '${controller.applesCount.value} / $kAppleTarget apples',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],

        // 5. Session Record Badge or Session Best for Guests / Offline
        if (!isLoggedIn) ...[
          if (isNewRecord) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9100), Color(0xFFFF3D00)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'new_session_record_badge'.tr,
                    style: GoogleFonts.vazirmatn(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ] else if (sessionBest > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.amber,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${'session_best_score'.tr}: $sessionBest',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ],
    );
  }
}
