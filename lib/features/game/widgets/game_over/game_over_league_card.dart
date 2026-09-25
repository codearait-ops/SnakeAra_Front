import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/game_controller.dart';

/// Weekly League status card and league attempt badges.
class GameOverLeagueCard extends StatelessWidget {
  final GameController controller;

  const GameOverLeagueCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isLoggedIn = auth.isLoggedIn.value && auth.currentUser.value != null;
    final isLeague = controller.snakeGame.isLeagueAttempt;
    final leagueAttempts = controller.snakeGame.leagueAttemptsRemaining.value;
    final bool canPlayLeague = !isLeague ||
        (controller.snakeGame.canPlayLeagueAttempt.value && leagueAttempts != 0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 6. Weekly League Status Card
        if (isLoggedIn &&
            controller.leagueResult.value != null &&
            controller.leagueResult.value!.isEligible) ...[
          Builder(
            builder: (context) {
              final league = controller.leagueResult.value!;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade900.withValues(alpha: 0.35),
                      const Color(0xFF161B22),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.55),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Row: Season & Rank | Final Score in table
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${'season'.tr} ${league.seasonNumber}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  league.rank != null && league.rank! > 0
                                      ? '${'game_over_league_rank'.tr}: #${league.rank}'
                                      : 'game_over_league_title'.tr,
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'game_over_league_score'.tr,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              '${league.finalScore.toStringAsFixed(1)} pts',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Divider if additional mode info or diversity exists
                    if (league.modeLeaguePoints != null ||
                        league.isNewModeRecord ||
                        (league.modeBestValue != null &&
                            league.modeBestValue! > 0) ||
                        league.diversityMultiplier > 1.0) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.12),
                          height: 1,
                        ),
                      ),

                      // Middle Row: Mode League Points Gained & Mode Record / Diversity
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (league.modeLeaguePoints != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: Color(0xFF00E5FF),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '+ ${league.modeLeaguePoints!.toStringAsFixed(1)} ${'out_of_100'.tr}',
                                  style: const TextStyle(
                                    color: Color(0xFF00E5FF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          else if (league.modeBestValue != null &&
                              league.modeBestValue! > 0)
                            Text(
                              '${'mode_league_best'.tr}: ${league.modeBestValue}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            )
                          else
                            const SizedBox.shrink(),

                          if (league.isNewModeRecord)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'new_mode_league_record'.tr,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else if (league.diversityMultiplier > 1.0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.orangeAccent.withValues(
                                    alpha: 0.6,
                                  ),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '${'diversity_bonus_indicator'.tr}: ${league.diversityMultiplier.toStringAsFixed(2)}x 🔥',
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
        ],

        // 8. League attempts badge (if League mode)
        if (isLeague && leagueAttempts >= 0) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: (canPlayLeague ? Colors.amber : Colors.redAccent)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (canPlayLeague ? Colors.amber : Colors.redAccent)
                    .withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  canPlayLeague
                      ? Icons.bolt_rounded
                      : Icons.lock_outline_rounded,
                  size: 16,
                  color: canPlayLeague ? Colors.amber : Colors.redAccent,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    canPlayLeague
                        ? 'league_attempts_left'
                            .trParams({'count': '$leagueAttempts'})
                        : 'no_league_attempts_left'.tr,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: canPlayLeague ? Colors.amber : Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
