import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/core/constants/app_constants.dart';
import '../../../../app/core/utils/enums.dart';
import '../../../settings/controllers/settings_controller.dart';
import '../../controllers/game_controller.dart';
import '../overlays/round_icon_button.dart';

/// Floating glassmorphic top bar displaying game mode badge, timer, lives,
/// score, and action buttons (audio, home, pause).
class GameTopBar extends StatelessWidget {
  final GameController controller;

  const GameTopBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isRtl =
          Get.locale?.languageCode == 'fa' ||
          (Get.isRegistered<SettingsController>() &&
              Get.find<SettingsController>().currentLanguage.value == 'fa');

      final isClassic = controller.gameMode.value == GameMode.classic;
      final isInfection = controller.gameMode.value == GameMode.infection;
      final isBlindMemory = controller.gameMode.value == GameMode.blindMemory;
      final isLaser = controller.gameMode.value == GameMode.laser;
      final isMeltdown = controller.gameMode.value == GameMode.meltdown;
      final isCrabChase = controller.gameMode.value == GameMode.crabChase;
      final isCasual = controller.gameMode.value == GameMode.casual;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCasual
                ? const Color(0xFFA855F7).withValues(alpha: 0.35)
                : isMeltdown
                ? const Color(0xFFC6FF00).withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.2),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isCasual
                  ? const Color(0xFFA855F7).withValues(alpha: 0.15)
                  : isMeltdown
                  ? const Color(0xFFC6FF00).withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Row(
            children: [
              // Start: Mode / Level Badge & Timer (Bounded inside Expanded)
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModeBadge(
                          controller: controller,
                          isRtl: isRtl,
                          isClassic: isClassic,
                          isInfection: isInfection,
                          isBlindMemory: isBlindMemory,
                          isLaser: isLaser,
                          isMeltdown: isMeltdown,
                          isCrabChase: isCrabChase,
                          isCasual: isCasual,
                        ),
                        const SizedBox(width: 5),
                        _buildTimer(
                          controller: controller,
                          isClassic: isClassic,
                          isInfection: isInfection,
                          isBlindMemory: isBlindMemory,
                          isLaser: isLaser,
                          isMeltdown: isMeltdown,
                          isCrabChase: isCrabChase,
                          isCasual: isCasual,
                        ),
                        if (isCasual) ...[
                          const SizedBox(width: 6),
                          _buildCasualLives(controller),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Center: Score inside a stylish framed box (Guaranteed Center of Screen)
              _buildScoreBadge(
                controller: controller,
                isClassic: isClassic,
                isInfection: isInfection,
                isBlindMemory: isBlindMemory,
                isLaser: isLaser,
                isMeltdown: isMeltdown,
                isCrabChase: isCrabChase,
                isCasual: isCasual,
              ),
              const SizedBox(width: 4),

              // End: Action buttons (Bounded inside Expanded)
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAudioButton(controller),
                        const SizedBox(width: 4),
                        RoundIconButton(
                          icon: controller.snakeGame.isLeagueAttempt
                              ? Icons.emoji_events_rounded
                              : Icons.home_rounded,
                          onPressed: () => controller.goToMenu(),
                        ),
                        const SizedBox(width: 4),
                        RoundIconButton(
                          icon: controller.gameStatus.value == GameStatus.paused
                              ? Icons.play_arrow
                              : Icons.pause,
                          onPressed: () => controller.togglePause(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildScoreBadge({
    required GameController controller,
    required bool isClassic,
    required bool isInfection,
    required bool isBlindMemory,
    required bool isLaser,
    required bool isMeltdown,
    required bool isCrabChase,
    required bool isCasual,
  }) {
    if (controller.snakeGame.isDailyMission) {
      final mType = controller.snakeGame.dailyMissionType;
      final target = controller.snakeGame.dailyMissionTarget;

      if (mType == 'eat_count') {
        final current = controller.applesCount.value;
        final isGoalReached = current >= target;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color:
                (isGoalReached
                        ? const Color(0xFF00E676)
                        : const Color(0xFFFF9100))
                    .withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  (isGoalReached
                          ? const Color(0xFF00E676)
                          : const Color(0xFFFF9100))
                      .withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (isGoalReached
                            ? const Color(0xFF00E676)
                            : const Color(0xFFFF9100))
                        .withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🍎', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text(
                '$current / $target',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: isGoalReached ? const Color(0xFF00E676) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      } else if (mType == 'survive_time') {
        final current = controller.elapsedTime.value;
        final remaining = (target - current).clamp(0, target);
        final isGoalReached = current >= target;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color:
                (isGoalReached
                        ? const Color(0xFF00E676)
                        : const Color(0xFFFF9100))
                    .withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  (isGoalReached
                          ? const Color(0xFF00E676)
                          : const Color(0xFFFF9100))
                      .withValues(alpha: 0.6),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shield_outlined,
                color: isGoalReached
                    ? const Color(0xFF00E676)
                    : const Color(0xFFFF9100),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${remaining}s',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: isGoalReached ? const Color(0xFF00E676) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      } else if (mType == 'score_threshold') {
        final current = controller.score.value;
        final isGoalReached = current >= target;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color:
                (isGoalReached
                        ? const Color(0xFF00E676)
                        : const Color(0xFFFF9100))
                    .withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  (isGoalReached
                          ? const Color(0xFF00E676)
                          : const Color(0xFFFF9100))
                      .withValues(alpha: 0.6),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.stars_rounded,
                color: isGoalReached
                    ? const Color(0xFF00E676)
                    : const Color(0xFFFF9100),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '$current / $target',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: isGoalReached ? const Color(0xFF00E676) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }
    }

    final Color accentColor = isMeltdown
        ? const Color(0xFFC6FF00)
        : (isLaser
              ? const Color(0xFFFF9100)
              : (isBlindMemory
                    ? const Color(0xFFD500F9)
                    : (isCrabChase
                          ? const Color(0xFFFF5252)
                          : (isCasual
                                ? const Color(0xFFA855F7)
                                : (isClassic ? kGoldColor : kFoodColor)))));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 8,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isClassic ||
              isBlindMemory ||
              isLaser ||
              isMeltdown ||
              isCrabChase ||
              isCasual)
            Icon(Icons.stars_rounded, color: accentColor, size: 16)
          else
            const Text('🍎', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            isBlindMemory ||
                    isClassic ||
                    isLaser ||
                    isMeltdown ||
                    isCrabChase ||
                    isCasual
                ? '${controller.score.value}'
                : (isInfection
                      ? '${controller.applesCount.value}'
                      : '${controller.applesCount.value}/${controller.appleTarget.value}'),
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: isMeltdown
                  ? const Color(0xFFC6FF00)
                  : (isLaser
                        ? const Color(0xFFFF9100)
                        : (isBlindMemory
                              ? const Color(0xFFD500F9)
                              : (isCrabChase
                                    ? const Color(0xFFFF5252)
                                    : (isCasual
                                          ? const Color(0xFFA855F7)
                                          : (isClassic
                                                ? kGoldColor
                                                : Colors.white))))),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer({
    required GameController controller,
    required bool isClassic,
    required bool isInfection,
    required bool isBlindMemory,
    required bool isLaser,
    required bool isMeltdown,
    required bool isCrabChase,
    required bool isCasual,
  }) {
    if (controller.snakeGame.isDailyMission &&
        controller.snakeGame.dailyMissionType == 'survive_time') {
      final target = controller.snakeGame.dailyMissionTarget;
      final remaining = (target - controller.elapsedTime.value).clamp(0, 9999);
      final isUrgent = remaining <= 10;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: (isUrgent ? const Color(0xFFFF1744) : const Color(0xFFFF9100))
              .withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                (isUrgent ? const Color(0xFFFF1744) : const Color(0xFFFF9100))
                    .withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              color: isUrgent
                  ? const Color(0xFFFF1744)
                  : const Color(0xFFFF9100),
              size: 13,
            ),
            const SizedBox(width: 3),
            Text(
              '${remaining}s',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: isUrgent ? const Color(0xFFFF1744) : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timer_outlined,
          color: isMeltdown
              ? const Color(0xFFC6FF00)
              : isLaser
              ? const Color(0xFFFF9100)
              : isBlindMemory
              ? const Color(0xFFD500F9)
              : isCasual
              ? const Color(0xFFA855F7)
              : (isInfection && controller.snakeGame.infectionRatio.value > 0.6
                    ? const Color(0xFFFF1744)
                    : (isClassic || isCrabChase
                          ? Colors.white70
                          : (controller.timeRemaining.value <= 15
                                ? kGameOverRed
                                : Colors.white70))),
          size: 16,
        ),
        const SizedBox(width: 3),
        Text(
          (isClassic ||
                  isCasual ||
                  isInfection ||
                  isBlindMemory ||
                  isLaser ||
                  isMeltdown ||
                  isCrabChase)
              ? _formatTime(controller.elapsedTime.value)
              : '${controller.timeRemaining.value}s',
          textDirection: TextDirection.ltr,
          style: TextStyle(
            color: isBlindMemory
                ? const Color(0xFFD500F9)
                : (isInfection &&
                          controller.snakeGame.infectionRatio.value > 0.6
                      ? const Color(0xFFFF1744)
                      : ((!isClassic &&
                                !isInfection &&
                                !isBlindMemory &&
                                !isLaser &&
                                !isMeltdown &&
                                !isCrabChase &&
                                !isCasual &&
                                controller.timeRemaining.value <= 15)
                            ? kGameOverRed
                            : Colors.white)),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildCasualLives(GameController controller) {
    return Obx(() {
      final lives = controller.casualLives.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFA855F7).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFA855F7).withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final isAlive = index < lives;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Icon(
                isAlive
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isAlive ? const Color(0xFFFF1744) : Colors.white30,
                size: 14,
              ),
            );
          }),
        ),
      );
    });
  }

  TextStyle _modeBadgeTextStyle({
    required Color color,
    required bool isRtl,
    double fontSize = 12,
  }) {
    if (isRtl) {
      return GoogleFonts.vazirmatn(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
        height: 1.2,
      );
    }
    return TextStyle(
      color: color,
      fontWeight: FontWeight.bold,
      fontSize: fontSize,
      letterSpacing: 1,
    );
  }

  Widget _buildModeBadge({
    required GameController controller,
    required bool isRtl,
    required bool isClassic,
    required bool isInfection,
    required bool isBlindMemory,
    required bool isLaser,
    required bool isMeltdown,
    required bool isCrabChase,
    required bool isCasual,
  }) {
    if (controller.snakeGame.isDailyMission) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9100).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFF9100).withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_rounded, color: Color(0xFFFF9100), size: 14),
            const SizedBox(width: 4),
            Text(
              'daily_challenge_title'.tr,
              style: _modeBadgeTextStyle(
                color: const Color(0xFFFF9100),
                isRtl: isRtl,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    if (controller.snakeGame.isLeagueAttempt) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFD700),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'league_attempt_btn'.tr,
              style: _modeBadgeTextStyle(
                color: const Color(0xFFFFD700),
                isRtl: isRtl,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (isLaser) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9100).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFF9100).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.flash_on_rounded,
              color: Color(0xFFFF9100),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'laser_mode'.tr,
              style: _modeBadgeTextStyle(
                color: const Color(0xFFFF9100),
                isRtl: isRtl,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else if (isMeltdown) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFC6FF00).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFC6FF00).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFC6FF00),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'meltdown_mode'.tr,
              style: _modeBadgeTextStyle(
                color: const Color(0xFFC6FF00),
                isRtl: isRtl,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else if (isBlindMemory) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFD500F9).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFD500F9).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧠', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              'blind_memory_mode'.tr,
              style: _modeBadgeTextStyle(
                color: const Color(0xFFD500F9),
                isRtl: isRtl,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else if (isInfection) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFF1744).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFF1744).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧬', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              'infection_mode'.tr,
              style: _modeBadgeTextStyle(
                color: const Color(0xFFFF1744),
                isRtl: isRtl,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else if (isClassic) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: kPrimaryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kPrimaryColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, color: kPrimaryColor, size: 16),
            const SizedBox(width: 4),
            Text(
              'classic_mode'.tr,
              style: _modeBadgeTextStyle(
                color: kPrimaryColor,
                isRtl: isRtl,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else if (isCrabChase) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5252).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFF5252).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🦀', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              'crab_chase_mode'.tr,
              style: _modeBadgeTextStyle(
                color: const Color(0xFFFF5252),
                isRtl: isRtl,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else if (isCasual) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFA855F7).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFA855F7).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧭', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              'casual_short'.tr,
              style: _modeBadgeTextStyle(
                color: const Color(0xFFA855F7),
                isRtl: isRtl,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_outlined, color: kGoldColor, size: 18),
          const SizedBox(width: 4),
          Text(
            isRtl
                ? 'مرحله ${controller.currentLevel.value}'
                : 'Lv.${controller.currentLevel.value}',
            style: isRtl
                ? GoogleFonts.vazirmatn(
                    color: kGoldColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    height: 1.2,
                  )
                : const TextStyle(
                    color: kGoldColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
          ),
        ],
      );
    }
  }

  static String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildAudioButton(GameController controller) {
    if (!Get.isRegistered<SettingsController>()) {
      return const SizedBox.shrink();
    }
    final settingsController = Get.find<SettingsController>();
    final bgOn = settingsController.bgMusicEnabled.value;
    final sfxOn = settingsController.soundEffectsEnabled.value;

    IconData audioIcon;
    Color audioColor;

    if (bgOn && sfxOn) {
      audioIcon = Icons.volume_up_rounded;
      audioColor = const Color(0xFF00E676);
    } else if (!bgOn && sfxOn) {
      audioIcon = Icons.music_off_rounded;
      audioColor = const Color(0xFFFFD600);
    } else {
      audioIcon = Icons.volume_off_rounded;
      audioColor = const Color(0xFFFF5252);
    }

    return RoundIconButton(
      icon: audioIcon,
      iconColor: audioColor,
      onPressed: () => controller.cycleAudioMode(),
    );
  }
}
