import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/constants/app_constants.dart';
import '../../../../app/core/utils/enums.dart';
import '../../controllers/game_controller.dart';

/// Header banner and game-over reason icon/text for GameOverOverlay.
class GameOverHeader extends StatelessWidget {
  final GameController controller;

  const GameOverHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final mode = controller.gameMode.value;
    final isBlindMemory = mode == GameMode.blindMemory;
    final isInfection = mode == GameMode.infection;
    final isNewRecord = controller.isNewHighscore.value;
    final reason = controller.gameOverReason.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Banner header
        if (isBlindMemory)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🧠', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Text(
                  'MEMORY OVER',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF00E5FF),
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          )
        else if (isInfection)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFF1744).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF1744).withValues(alpha: 0.4),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🧬', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Text(
                  'YOU SURVIVED',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF1744),
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          )
        else if (isNewRecord)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFD54F),
                  Color(0xFFFFB300),
                  Color(0xFFFF8F00),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kGoldColor.withValues(alpha: 0.5),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.black,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'new_record'.tr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: kGameOverRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kGameOverRed.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.dangerous, color: kGameOverRed, size: 18),
                const SizedBox(width: 8),
                Text(
                  'game_over'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kGameOverRed,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // 2. Game over reason
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_reasonIcon(reason), color: Colors.white54, size: 15),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _reasonText(reason),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12.5,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _reasonText(GameOverReason? reason) {
    switch (reason) {
      case GameOverReason.infectionReachedHead:
        return 'parasite_consumed'.tr;
      case GameOverReason.wallCollision:
        return 'hit_wall'.tr;
      case GameOverReason.selfCollision:
        return 'bit_yourself'.tr;
      case GameOverReason.obstacleCollision:
        return 'hit_obstacle'.tr;
      case GameOverReason.laserHeadHit:
        return 'hit_laser'.tr;
      case GameOverReason.bulletCollision:
        return 'hit_bullet'.tr;
      case GameOverReason.crabCollision:
        return 'hit_crab'.tr;
      case GameOverReason.timerExpired:
        return 'time_ran_out'.tr;
      case GameOverReason.unknown:
      case null:
        return 'game_over'.tr;
    }
  }

  IconData _reasonIcon(GameOverReason? reason) {
    switch (reason) {
      case GameOverReason.infectionReachedHead:
        return Icons.coronavirus_rounded;
      case GameOverReason.wallCollision:
        return Icons.border_style;
      case GameOverReason.selfCollision:
        return Icons.replay_30;
      case GameOverReason.obstacleCollision:
        return Icons.block;
      case GameOverReason.laserHeadHit:
        return Icons.bolt_rounded;
      case GameOverReason.bulletCollision:
        return Icons.adjust_rounded;
      case GameOverReason.crabCollision:
        return Icons.pest_control_rounded;
      case GameOverReason.timerExpired:
        return Icons.timer_off;
      case GameOverReason.unknown:
        return Icons.help_outline;
      case null:
        return Icons.info_outline;
    }
  }
}
