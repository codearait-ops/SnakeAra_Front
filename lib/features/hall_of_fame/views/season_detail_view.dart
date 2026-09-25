import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snake_game/features/league/models/league_models.dart';
import '../../../app/core/widgets/app_loading_widget.dart';
import '../../../app/core/widgets/floating_app_bar.dart';
import '../controllers/hall_of_fame_controller.dart';
import '../models/hall_of_fame_models.dart';

class SeasonDetailView extends StatelessWidget {
  const SeasonDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final int seasonNumber = Get.arguments as int? ?? 1;
    final controller = Get.isRegistered<HallOfFameController>()
        ? Get.find<HallOfFameController>()
        : Get.put(HallOfFameController());

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: FloatingAppBar(
        titleText: '${'season'.tr} $seasonNumber',
        accentColor: Colors.amber,
      ),
      body: FutureBuilder<SeasonDetail?>(
        future: controller.fetchSeasonDetail(seasonNumber),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingWidget.gold(fullScreen: true);
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                'Failed to load season details.',
                style: TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final detail = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildOverallWinners(detail.overallWinners),
                const SizedBox(height: 32),
                if (detail.badges.isNotEmpty) ...[
                  Text(
                    'weekly_champions'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBadgesGrid(detail.badges),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverallWinners(List<HallOfFameEntry> winners) {
    if (winners.isEmpty) return const SizedBox.shrink();

    // Assuming the first entry is the overall leaderboard for the season
    final entry = winners.first;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          if (entry.goldPlayer != null)
            _buildMedalRow(
              entry.goldPlayer!,
              entry.goldScore,
              'assets/image/medal/gold.png',
              Colors.amber,
              24,
            ),
          if (entry.silverPlayer != null)
            _buildMedalRow(
              entry.silverPlayer!,
              entry.silverScore,
              'assets/image/medal/silver.png',
              Colors.grey[400]!,
              20,
            ),
          if (entry.bronzePlayer != null)
            _buildMedalRow(
              entry.bronzePlayer!,
              entry.bronzeScore,
              'assets/image/medal/bronze.png',
              Colors.brown[300]!,
              18,
            ),
        ],
      ),
    );
  }

  Widget _buildMedalRow(
    HallOfFamePlayer player,
    int score,
    String medalAsset,
    Color color,
    double fontSize,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Image.asset(
            medalAsset,
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.workspace_premium_rounded,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              player.username,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesGrid(List<ModeBadge> badges) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shield,
                color: _getColorForMode(badge.mode),
                size: 48,
              ), // Replace with specific mode icons
              const SizedBox(height: 12),
              Text(
                badge.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'badge_title_${badge.mode}'.tr,
                style: TextStyle(
                  color: Colors.amber.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${badge.valueAchieved} pts',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getColorForMode(String mode) {
    switch (mode) {
      case 'classic':
        return Colors.greenAccent;
      case 'meltdown':
        return Colors.orangeAccent;
      case 'laser_core':
        return Colors.redAccent;
      case 'infection':
        return Colors.purpleAccent;
      case 'blind_memory':
        return Colors.blueGrey;
      case 'crab':
      case 'crab_chase':
        return const Color(0xFFFF5722);
      default:
        return Colors.amber;
    }
  }
}
