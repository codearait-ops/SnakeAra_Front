import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/core/constants/app_constants.dart';
import '../../../daily_mission/controllers/daily_mission_controller.dart';
import '../../controllers/game_controller.dart';

/// Action buttons for GameOverOverlay: Replay, Watch Ad for 2nd chance, Back to Menu/League.
class GameOverActionButtons extends StatelessWidget {
  final GameController controller;

  const GameOverActionButtons({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isLeague = controller.snakeGame.isLeagueAttempt;
    final leagueAttempts = controller.snakeGame.leagueAttemptsRemaining.value;
    final bool canPlayLeague = !isLeague ||
        (controller.snakeGame.canPlayLeagueAttempt.value && leagueAttempts != 0);

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        if (!controller.snakeGame.isDailyChallenge &&
            (!isLeague || canPlayLeague))
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => controller.restartGame(),
              icon: const Icon(Icons.refresh, size: 17),
              label: Text(
                isLeague && leagueAttempts > 0
                    ? '${'retry'.tr} ($leagueAttempts)'
                    : 'retry'.tr,
                style: GoogleFonts.vazirmatn(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
            ),
          ),
        if (controller.snakeGame.isDailyMission &&
            Get.isRegistered<DailyMissionController>())
          Builder(
            builder: (context) {
              final mission =
                  Get.find<DailyMissionController>().currentMission.value;
              if (mission != null && mission.canUnlockSecondAttempt) {
                return ElevatedButton.icon(
                  onPressed: () {
                    Get.find<DailyMissionController>()
                        .unlockSecondAttemptViaAd(context)
                        .then((success) {
                          if (success) {
                            controller.restartGame();
                          }
                        });
                  },
                  icon: const Icon(
                    Icons.video_library_rounded,
                    size: 17,
                  ),
                  label: Text(
                    'daily_mission_second_chance_ad'.tr,
                    style: GoogleFonts.vazirmatn(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        if (controller.snakeGame.isDailyChallenge)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => controller.goToMenu(),
              icon: const Icon(Icons.home_outlined, size: 17),
              label: Text(
                'back_to_menu'.tr,
                style: GoogleFonts.vazirmatn(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
            ),
          )
        else if (isLeague && !canPlayLeague)
          // When league attempts are exhausted, Back to League is the primary button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => controller.goToMenu(),
              icon: const Icon(Icons.emoji_events_outlined, size: 17),
              label: Text(
                'back_to_league'.tr,
                style: GoogleFonts.vazirmatn(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: () => controller.goToMenu(),
            icon: Icon(
              isLeague ? Icons.emoji_events_outlined : Icons.home_outlined,
              size: 17,
              color: Colors.white70,
            ),
            label: Text(
              isLeague ? 'back_to_league'.tr : 'back_to_menu'.tr,
              style: GoogleFonts.vazirmatn(
                color: Colors.white70,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
      ],
    );
  }
}
