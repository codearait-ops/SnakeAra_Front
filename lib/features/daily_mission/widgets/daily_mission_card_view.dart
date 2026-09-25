import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/widgets/app_loading_widget.dart';
import '../../game/models/game_mode_config.dart';
import '../controllers/daily_mission_controller.dart';

/// A full-width, sleek Daily Mission card designed exactly as the modern dark HUD layout.
class DailyMissionCardView extends StatelessWidget {
  const DailyMissionCardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DailyMissionController());

    return Obx(() {
      final mission = controller.currentMission.value;

      // Loading state
      if (mission == null) {
        if (controller.isLoading.value) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF0B141C),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Center(child: AppLoadingWidget(size: 28)),
          );
        }

        // Error / Retry state
        if (controller.errorMessage.value.isNotEmpty) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1620),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.errorMessage.value,
                    style: GoogleFonts.vazirmatn(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => controller.fetchTodayMission(),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(
                    'retry'.tr,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      }

      // Mission data & mode resolution
      final isCompleted = mission.isCompleted;
      final isFailed = mission.isFailed;
      final canUnlockAd = mission.canUnlockSecondAttempt;
      final isAttempt2Ready =
          !isCompleted &&
          !canUnlockAd &&
          mission.attemptNumber == 2 &&
          mission.status != 'failed' &&
          mission.canPlay;
      final isReadyAttempt1 =
          !isCompleted &&
          !canUnlockAd &&
          mission.attemptNumber == 1 &&
          mission.status != 'failed' &&
          mission.canPlay;
      final lang = Get.locale?.languageCode ?? 'fa';

      // Mode configuration & styling
      final modeConfig = GameModeConfig.findByModeString(mission.gameMode) ??
          _resolveModeConfig(mission.gameMode);
      final modeColor = modeConfig?.accentColor ??
          _getModeAccentColor(mission.gameMode);
      final modeIconAsset = modeConfig?.iconAsset ??
          GameModeConfig.getIconAssetForMode(mission.gameMode);

      // Title & Subtitle resolution
      final titleText = mission.localizedTitle(lang).isNotEmpty
          ? mission.localizedTitle(lang)
          : (modeConfig?.titleTr ?? mission.gameMode.toUpperCase());

      final descriptionText = mission.localizedDescription(lang);

      return RepaintBoundary(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D2534), Color(0xFF091621), Color(0xFF050D14)],
            ),
            border: Border.all(
              color: modeColor.withValues(alpha: 0.55),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: modeColor.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ==========================================
                // 1. TOP HEADER ROW: Daily Objective Pill ("هدف امروز")
                // ==========================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🎯', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                          Text(
                            'daily_mission_today_target'.tr,
                            style: GoogleFonts.vazirmatn(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ==========================================
                // 2. MIDDLE ROW: Title, Description & Circular Icon Avatar
                // ==========================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Texts (Title & Subtitle)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleText,
                            style: GoogleFonts.vazirmatn(
                              color: modeColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: modeColor.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            descriptionText,
                            style: GoogleFonts.vazirmatn(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 13,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Circular Avatar with Mode Icon from Assets
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: modeColor.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: modeColor.withValues(alpha: 0.65),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: modeColor.withValues(alpha: 0.35),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          modeIconAsset,
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            modeConfig?.icon ??
                                _getMissionTypeIcon(mission.type),
                            color: modeColor,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ==========================================
                // 3. MIDDLE STATUS BOX (Dark Rounded Glass Panel)
                // ==========================================
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070F16).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.09),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Left Section: Participation Status (وضعیت شرکت)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'daily_mission_participation_status'.tr,
                              style: GoogleFonts.vazirmatn(
                                color: Colors.white54,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _buildParticipationStatusValue(
                              isCompleted: isCompleted,
                              canUnlockAd: canUnlockAd,
                              isAttempt2Ready: isAttempt2Ready,
                              isReadyAttempt1: isReadyAttempt1,
                              isFailed: isFailed,
                              modeColor: modeColor,
                            ),
                          ],
                        ),
                      ),

                      // Center Vertical Divider
                      Container(
                        width: 1,
                        height: 38,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),

                      // Right Section: Remaining Time (زمان باقی‌مانده)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'daily_mission_time_left'.tr,
                              style: GoogleFonts.vazirmatn(
                                color: Colors.white54,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Obx(() {
                                    final remaining =
                                        controller.remainingTime.value;
                                    final hours = remaining.inHours
                                        .toString()
                                        .padLeft(2, '0');
                                    final minutes = (remaining.inMinutes % 60)
                                        .toString()
                                        .padLeft(2, '0');
                                    final seconds = (remaining.inSeconds % 60)
                                        .toString()
                                        .padLeft(2, '0');
                                    final countdownStr =
                                        '$hours:$minutes:$seconds';

                                    return Text(
                                      countdownStr,
                                      style: GoogleFonts.vazirmatn(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    );
                                  }),
                                  const SizedBox(width: 5),
                                  const Icon(
                                    Icons.alarm_on_rounded,
                                    color: Colors.white70,
                                    size: 17,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ==========================================
                // 4. BOTTOM FULL-WIDTH ACTION BUTTON
                // ==========================================
                _buildBottomActionButton(
                  context: context,
                  controller: controller,
                  isCompleted: isCompleted,
                  canUnlockAd: canUnlockAd,
                  isAttempt2Ready: isAttempt2Ready,
                  isReadyAttempt1: isReadyAttempt1,
                  isFailed: isFailed,
                  modeColor: modeColor,
                  rewardCoins: mission.rewardCoins,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Builds the participation status value indicator (Icon + Text)
  Widget _buildParticipationStatusValue({
    required bool isCompleted,
    required bool canUnlockAd,
    required bool isAttempt2Ready,
    required bool isReadyAttempt1,
    required bool isFailed,
    required Color modeColor,
  }) {
    if (isCompleted) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'daily_mission_status_completed_short'.tr,
              style: GoogleFonts.vazirmatn(
                color: const Color(0xFF00E676),
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF00E676),
              size: 16,
            ),
          ],
        ),
      );
    }

    if (canUnlockAd) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'daily_mission_status_attempt_ad_short'.tr,
              style: GoogleFonts.vazirmatn(
                color: const Color(0xFFFF9100),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.play_circle_fill_rounded,
              color: Color(0xFFFF9100),
              size: 16,
            ),
          ],
        ),
      );
    }

    if (isAttempt2Ready) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'daily_mission_status_attempt_2_short'.tr,
              style: GoogleFonts.vazirmatn(
                color: const Color(0xFFFF9100),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.sports_esports_rounded,
              color: Color(0xFFFF9100),
              size: 16,
            ),
          ],
        ),
      );
    }

    if (isReadyAttempt1) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'daily_mission_status_not_participated_short'.tr,
              style: GoogleFonts.vazirmatn(
                color: modeColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.radio_button_unchecked_rounded,
              color: modeColor,
              size: 15,
            ),
          ],
        ),
      );
    }

    // Exhausted / Failed
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'daily_mission_status_exhausted_short'.tr,
            style: GoogleFonts.vazirmatn(
              color: Colors.redAccent.shade100,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.cancel_rounded,
            color: Colors.redAccent.shade100,
            size: 16,
          ),
        ],
      ),
    );
  }

  /// Builds the full-width action button matching the screenshot and all 3 states
  Widget _buildBottomActionButton({
    required BuildContext context,
    required DailyMissionController controller,
    required bool isCompleted,
    required bool canUnlockAd,
    required bool isAttempt2Ready,
    required bool isReadyAttempt1,
    required bool isFailed,
    required Color modeColor,
    required int rewardCoins,
  }) {
    // ----------------------------------------------------
    // STATE 1: Completed Successfully
    // ----------------------------------------------------
    if (isCompleted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFF00C853), Color(0xFF00E676)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E676).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.black,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'daily_mission_reward_claimed'.trParams({
                'count': '$rewardCoins',
              }),
              style: GoogleFonts.vazirmatn(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    // ----------------------------------------------------
    // STATE 2: 1st Attempt used -> Watch Ad for 2nd Attempt
    // ----------------------------------------------------
    if (canUnlockAd) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => controller.unlockSecondAttemptViaAd(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9100), Color(0xFFFF3D00)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9100).withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'daily_mission_watch_ad_retry'.tr,
                    style: GoogleFonts.vazirmatn(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ----------------------------------------------------
    // STATE 3: Ready to play (Attempt 1 OR Attempt 2 unlocked)
    // ----------------------------------------------------
    if (isReadyAttempt1 || isAttempt2Ready) {
      final btnLabel = isAttempt2Ready
          ? 'daily_mission_start_attempt_2'.tr
          : 'daily_mission_start'.tr;

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => controller.startMissionGame(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [modeColor, modeColor.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: modeColor.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.sports_esports_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    btnLabel,
                    style: GoogleFonts.vazirmatn(
                      color: Colors.black,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ----------------------------------------------------
    // STATE 4: Locked / All attempts exhausted (دقیقاً مثل تصویر)
    // ----------------------------------------------------
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141F28).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_rounded, color: Colors.white60, size: 20),
          const SizedBox(width: 8),
          Text(
            'غیرمجاز (اتمام تلاش‌های امروز)',
            style: GoogleFonts.vazirmatn(
              color: Colors.white70,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Resolves the specific accent color for the game mode
  Color _getModeAccentColor(String modeId) {
    final cfg = GameModeConfig.findByModeString(modeId);
    if (cfg != null) return cfg.accentColor;
    return GameModeConfig.getColorForMode(modeId);
  }

  /// Resolves the GameModeConfig from availableGameModes using robust alias matching
  GameModeConfig? _resolveModeConfig(String modeId) {
    return GameModeConfig.findByModeString(modeId);
  }

  /// Returns icon for specific mission type
  IconData _getMissionTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'eat_count':
        return Icons.restaurant_rounded;
      case 'survive_time':
        return Icons.timer_rounded;
      case 'score_threshold':
        return Icons.emoji_events_rounded;
      case 'combo_apples':
        return Icons.bolt_rounded;
      default:
        return Icons.psychology_rounded;
    }
  }
}
