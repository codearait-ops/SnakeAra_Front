import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/utils/enums.dart';
import '../controllers/game_controller.dart';
import 'game_over/game_over_action_buttons.dart';
import 'game_over/game_over_header.dart';
import 'game_over/game_over_item_badges.dart';
import 'game_over/game_over_league_card.dart';
import 'game_over/game_over_retry_banner.dart';
import 'game_over/game_over_rewards_badge.dart';
import 'game_over/game_over_stats_card.dart';

/// Modal overlay shown when a game is lost.
///
/// Orchestrates the modular sub-cards for game-over presentation,
/// score display, league stats, reward badges, offline retry, and actions.
class GameOverOverlay extends StatefulWidget {
  const GameOverOverlay({super.key});

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
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

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        color: Colors.black87,
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Obx(() {
              return _buildCard(context, controller);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, GameController controller) {
    final mode = controller.gameMode.value;
    final isInfection = mode == GameMode.infection;
    final isBlindMemory = mode == GameMode.blindMemory;
    final isLaser = mode == GameMode.laser;
    final isMeltdown = mode == GameMode.meltdown;
    final isNewRecord = controller.isNewHighscore.value;

    final themeColor = isMeltdown
        ? const Color(0xFFC6FF00)
        : (isLaser
              ? const Color(0xFFFF9100)
              : (isBlindMemory
                    ? const Color(0xFF00E5FF)
                    : (isInfection
                          ? const Color(0xFFFF1744)
                          : (isNewRecord ? kGoldColor : kGameOverRed))));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
        maxWidth: 420,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isBlindMemory
              ? const [Color(0xFF041926), Color(0xFF020914)]
              : (isInfection
                    ? const [Color(0xFF260A14), Color(0xFF0F060A)]
                    : const [Color(0xFF1A1F2E), Color(0xFF0D1117)]),
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: themeColor.withValues(
            alpha: isNewRecord || isInfection || isBlindMemory ? 0.8 : 0.4,
          ),
          width: isNewRecord || isInfection || isBlindMemory ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(
              alpha: isNewRecord || isInfection || isBlindMemory ? 0.4 : 0.2,
            ),
            blurRadius: isNewRecord || isInfection || isBlindMemory ? 40 : 30,
            spreadRadius: isNewRecord || isInfection || isBlindMemory ? 6 : 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GameOverHeader(controller: controller),
              GameOverStatsCard(
                controller: controller,
                themeColor: themeColor,
              ),
              GameOverItemBadges(controller: controller),
              GameOverLeagueCard(controller: controller),
              GameOverRewardsBadge(controller: controller),
              GameOverRetryBanner(controller: controller),
              GameOverActionButtons(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}
