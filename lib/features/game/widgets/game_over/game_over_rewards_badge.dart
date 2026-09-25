import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/core/constants/app_constants.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/game_controller.dart';

/// XP reward pill for logged in users, or guest registration CTA card.
class GameOverRewardsBadge extends StatelessWidget {
  final GameController controller;

  const GameOverRewardsBadge({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isLoggedIn = auth.isLoggedIn.value && auth.currentUser.value != null;

    if (isLoggedIn && controller.earnedXp.value > 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: kGoldColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: kGoldColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: kGoldColor.withValues(alpha: 0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars_rounded,
                  color: kGoldColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '+${controller.earnedXp.value} ${'xp_earned'.tr}',
                  style: const TextStyle(
                    color: kGoldColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
      );
    } else if (!isLoggedIn && !controller.snakeGame.isDailyChallenge) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kPrimaryColor.withValues(alpha: 0.14),
                  kGoldColor.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: kPrimaryColor.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: kPrimaryColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'guest_score_not_submitted'.tr,
                            style: GoogleFonts.vazirmatn(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'guest_score_not_submitted_desc'.tr,
                            style: GoogleFonts.vazirmatn(
                              color: Colors.white70,
                              fontSize: 10.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: () => auth.requireAuth(
                      () {},
                      contextMessage: 'login_prompt_default'.tr,
                    ),
                    icon: const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 15,
                    ),
                    label: Text(
                      'guest_score_not_submitted_btn'.tr,
                      style: GoogleFonts.vazirmatn(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
      );
    }

    return const SizedBox(height: 6);
  }
}
