import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/constants/app_constants.dart';
import '../controllers/game_controller.dart';

/// Overlay shown when a level is completed (target apples eaten).
///
/// Features a golden celebration with score display, confetti-like animation,
/// and options to go to next level or return to menu.
class LevelCompleteOverlay extends StatefulWidget {
  const LevelCompleteOverlay({super.key});

  @override
  State<LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<LevelCompleteOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GameController>();
    final isLastLevel = controller.levelNumber >= 50;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        color: Colors.black87,
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnim,
            child: _buildCard(controller, isLastLevel),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(GameController controller, bool isLastLevel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
        maxWidth: 400,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2E1A), Color(0xFF0D1117)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kGoldColor.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: kGoldColor.withValues(alpha: 0.3),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kGoldColor.withValues(alpha: 0.5),
                      blurRadius: 26,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.black87,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),

              // Level Complete / Boss Defeated / Daily Challenge Cleared text
              Text(
                controller.snakeGame.isDailyMission
                    ? '🎉 ${'daily_mission_completed'.tr}'
                    : (isLastLevel
                        ? 'FINAL BOSS DEFEATED! 👑'
                        : (controller.levelNumber % 10 == 0
                            ? 'boss_defeated'.tr
                            : 'level_complete'.tr)),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: kGoldColor,
                  letterSpacing: 1.5,
                  shadows: [Shadow(color: kGoldColor, blurRadius: 20)],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              Text(
                controller.snakeGame.isDailyMission
                    ? 'daily_challenge_title'.tr
                    : (controller.levelNumber % 10 == 0
                        ? '👑 ${'boss_${controller.levelNumber ~/ 10}_name'.tr} DEFEATED!'
                        : 'Level ${controller.levelNumber} cleared!'),
                style: TextStyle(
                  color: controller.snakeGame.isDailyMission
                      ? Colors.white70
                      : (controller.levelNumber % 10 == 0 ? kGoldColor : Colors.white54),
                  fontSize: 13.5,
                  fontWeight: controller.levelNumber % 10 == 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 18),

              // Reward Badge (Coins for Daily Mission or XP for Level mode)
              if (controller.snakeGame.isDailyMission)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFD700).withValues(alpha: 0.25),
                        const Color(0xFFFF8F00).withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      color: Color(0xFFFFD700),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'daily_mission_coins_reward'.trParams({
                        'count': '${controller.snakeGame.dailyMissionReward}',
                      }),
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
            else
              Obx(() {
                final hasCoins = controller.snakeGame.levelCoinAwarded.value &&
                    controller.snakeGame.levelCoinsAwarded.value > 0;
                final coinsAmount = controller.snakeGame.levelCoinsAwarded.value;

                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    // XP Reward Badge
                    if (controller.earnedXp.value > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
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
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                color: kGoldColor,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '+${controller.earnedXp.value} ${'xp_earned'.tr}',
                                style: const TextStyle(
                                  color: kGoldColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Coin Reward Badge (ONLY shown when server confirmed coin_awarded == true)
                    if (hasCoins)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFD700).withValues(alpha: 0.25),
                              const Color(0xFFFF8F00).withValues(alpha: 0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.monetization_on_rounded,
                                color: Color(0xFFFFD700),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '+$coinsAmount ${'coins_count_label'.trParams({'count': ''}).trim()}',
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              }),
            const SizedBox(height: 24),

            // Action buttons
            if (controller.snakeGame.isDailyMission)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9100).withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => controller.goToMenu(),
                  icon: const Icon(Icons.home_rounded, size: 18),
                  label: Text('back_to_menu'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9100),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                ),
              )
            else ...[
              if (!isLastLevel)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: kGoldColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => controller.nextLevel(),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text('next_level'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGoldColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              if (!isLastLevel) const SizedBox(height: 12),

              // Menu / Back to levels
              TextButton.icon(
                onPressed: () => controller.goToMenu(),
                icon: const Icon(Icons.home_outlined, size: 18),
                label: Text(
                  isLastLevel ? 'YOU BEAT ALL LEVELS! 🎉' : 'back_to_menu'.tr,
                  style: TextStyle(
                    color: isLastLevel ? kGoldColor : Colors.white54,
                    fontSize: isLastLevel ? 16 : 13,
                    fontWeight: isLastLevel ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white54,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
}
