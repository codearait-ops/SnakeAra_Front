import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';

/// Top overlay HUD widget displaying active Casual Mission, progress bar,
/// active power-up timer badge, and mission cooldown countdown.
class CasualMissionHud extends StatelessWidget {
  final GameController controller;

  const CasualMissionHud({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final missionManager = controller.snakeGame.casualMissionManager;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFA855F7).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA855F7).withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Obx(() {
        final mission = missionManager.activeMissionRx.value;
        final isCoolingDown = missionManager.cooldownRemainingRx.value > 0;
        final cooldown = missionManager.cooldownRemainingRx.value.ceil();

        if (mission != null) {
          return Row(
            children: [
              // Mission Icon with subtle background circle
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFA855F7).withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  mission.type.iconEmoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),

              // Mission Description and Progress bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            mission.descriptionTr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${mission.currentProgress} / ${mission.target}',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            color: Color(0xFFA855F7),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: mission.progressRatio,
                        minHeight: 6,
                        backgroundColor: const Color(0xFF1E293B),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          mission.isCompleted
                              ? const Color(0xFF00E676)
                              : const Color(0xFFA855F7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Reward badge (+10 Coins)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 3),
                    Text(
                      '+${mission.rewardCoins}',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        } else if (isCoolingDown) {
          return Row(
            children: [
              const Text('⏳', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'next_mission_in'.trParams({'sec': '$cooldown'}),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${cooldown}s',
                  style: const TextStyle(
                    color: Color(0xFFA855F7),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      }),
    );
  }
}

/// Floating badge displayed as an overlay when a power-up is active in Casual mode.
/// Designed to float smoothly without affecting game board layout or scaling.
class CasualActivePowerUpBadge extends StatelessWidget {
  final GameController controller;

  const CasualActivePowerUpBadge({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activePowerUp = controller.casualActivePowerUp.value;
      final remainingTime = controller.casualPowerUpTimeRemaining.value;

      if (activePowerUp == null || remainingTime <= 0) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: activePowerUp.color.withValues(alpha: 0.8),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: activePowerUp.color.withValues(alpha: 0.35),
              blurRadius: 14,
              spreadRadius: 1.5,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              activePowerUp.emoji,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(width: 6),
            Text(
              activePowerUp.displayNameTr,
              style: TextStyle(
                color: activePowerUp.color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: activePowerUp.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${remainingTime.toStringAsFixed(1)}s',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
    });
  }
}
