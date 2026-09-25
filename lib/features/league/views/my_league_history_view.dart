import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/widgets/app_loading_widget.dart';
import '../../../app/core/widgets/floating_app_bar.dart';
import '../controllers/my_league_history_controller.dart';
import '../models/league_models.dart';

class MyLeagueHistoryView extends StatelessWidget {
  const MyLeagueHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyLeagueHistoryController());

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: FloatingAppBar(
        titleText: 'my_league_history'.tr,
        accentColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingWidget.gold(fullScreen: true);
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(controller.errorMessage.value, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.fetchHistory,
                  child: const Text('Retry'),
                )
              ],
            ),
          );
        }

        if (controller.history.isEmpty) {
          return const Center(child: Text('No league history available.', style: TextStyle(color: Colors.white70)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.history.length,
          itemBuilder: (context, index) {
            final entry = controller.history[index];
            return _buildHistoryCard(entry);
          },
        );
      }),
    );
  }

  Widget _buildHistoryCard(LeagueHistoryEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'season'.tr} ${entry.season}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (entry.medals.isNotEmpty)
                Row(
                  children: entry.medals.map((m) => _buildMedalIcon(m)).toList(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('my_rank'.tr, style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
              Text(
                entry.rank > 0
                    ? '#${entry.rank}'
                    : (entry.status == 'active' ? 'active'.tr : '-'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Score', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
              Text('${entry.finalScore.toStringAsFixed(1)} pts', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedalIcon(PlayerMedal medal) {
    String? asset;
    if (medal.medalType == 'gold') asset = 'assets/image/medal/gold.png';
    if (medal.medalType == 'silver') asset = 'assets/image/medal/silver.png';
    if (medal.medalType == 'bronze') asset = 'assets/image/medal/bronze.png';

    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Tooltip(
        message: medal.mode ?? 'Overall',
        child: asset != null
            ? Image.asset(
                asset,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.amber,
                  size: 20,
                ),
              )
            : const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.amber,
                size: 20,
              ),
      ),
    );
  }
}
