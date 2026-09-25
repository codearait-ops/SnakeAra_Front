import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/constants/app_constants.dart';
import '../../../../app/core/utils/enums.dart';
import '../../controllers/game_controller.dart';

/// Displays the primary score or time survived stat with theme glow and shadows.
class GameOverStatsCard extends StatelessWidget {
  final GameController controller;
  final Color themeColor;

  const GameOverStatsCard({
    super.key,
    required this.controller,
    required this.themeColor,
  });

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
    if (controller.gameMode.value == GameMode.level) {
      return const SizedBox.shrink();
    }

    final isInfection = controller.gameMode.value == GameMode.infection;
    final isBlindMemory = controller.gameMode.value == GameMode.blindMemory;
    final isNewRecord = controller.isNewHighscore.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isInfection ? 'time_survived'.tr : 'score'.tr,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white38,
            letterSpacing: 2.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isInfection
              ? _formatSurvivalTime(controller.elapsedTime.value)
              : '${controller.score.value}',
          style: TextStyle(
            fontSize: isInfection ? 40 : 48,
            fontWeight: FontWeight.w900,
            color: isBlindMemory
                ? const Color(0xFFD500F9)
                : (isInfection
                      ? const Color(0xFFFF1744)
                      : (isNewRecord ? kGoldColor : Colors.white)),
            letterSpacing: 2,
            shadows: isBlindMemory || isInfection || isNewRecord
                ? [
                    Shadow(
                      color: themeColor.withValues(alpha: 0.8),
                      blurRadius: 20,
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
