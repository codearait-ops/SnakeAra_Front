import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/core/widgets/app_loading_widget.dart';
import '../../../app/core/widgets/floating_app_bar.dart';
import '../../league/models/league_tier_models.dart';
import '../controllers/hall_of_fame_controller.dart';
import '../models/hall_of_fame_models.dart';

class HallOfFameView extends StatefulWidget {
  const HallOfFameView({super.key});

  @override
  State<HallOfFameView> createState() => _HallOfFameViewState();
}

class _HallOfFameViewState extends State<HallOfFameView> {
  final Rx<LeagueTier?> selectedTierFilter = Rx<LeagueTier?>(null);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HallOfFameController());

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: FloatingAppBar(
        titleText: 'hall_of_fame_title'.tr,
        accentColor: Colors.amber,
      ),
      body: Column(
        children: [
          // --- Tier Filter Tabs ---
          Container(
            height: 42,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // All Tiers chip
                Obx(() {
                  final isAll = selectedTierFilter.value == null;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(
                        'all_tiers'.tr,
                        style: GoogleFonts.vazirmatn(
                          color: isAll ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      selected: isAll,
                      selectedColor: const Color(0xFFFFD700),
                      backgroundColor: const Color(0xFF161B22),
                      onSelected: (_) {
                        selectedTierFilter.value = null;
                        controller.fetchHallOfFameBundle(
                          tier: null,
                          forceRefresh: false,
                        );
                      },
                    ),
                  );
                }),
                // Individual Tiers
                ...LeagueTier.values.map((tier) {
                  return Obx(() {
                    final isSelected = selectedTierFilter.value == tier;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        avatar: Icon(
                          tier.icon,
                          color: isSelected ? Colors.black : tier.color,
                          size: 16,
                        ),
                        label: Text(
                          tier.displayNameTr,
                          style: GoogleFonts.vazirmatn(
                            color: isSelected ? Colors.black : tier.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: tier.color,
                        backgroundColor: const Color(0xFF161B22),
                        onSelected: (_) {
                          selectedTierFilter.value = tier;
                          controller.fetchHallOfFameBundle(
                            tier: tier.apiName,
                            forceRefresh: false,
                          );
                        },
                      ),
                    );
                  });
                }),
              ],
            ),
          ),

          // --- Seasons List ---
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const AppLoadingWidget.gold(fullScreen: true);
              }
              if (controller.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        controller.errorMessage.value,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            controller.fetchHallOfFame(forceRefresh: true),
                        child: Text('retry'.tr),
                      ),
                    ],
                  ),
                );
              }

              if (controller.seasons.isEmpty) {
                return Center(
                  child: Text(
                    'no_champions_yet'.tr,
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.fetchHallOfFame(forceRefresh: true),
                color: Colors.amber,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.seasons.length,
                  itemBuilder: (context, index) {
                    final entry = controller.seasons[index];
                    return _buildSeasonCard(entry);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonCard(HallOfFameEntry entry) {
    return GestureDetector(
      onTap: () => Get.toNamed('/season-detail', arguments: entry.season),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
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
                  style: GoogleFonts.vazirmatn(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
            const SizedBox(height: 16),
            _buildWinnerRow(
              entry.goldPlayer,
              entry.goldScore,
              'assets/image/medal/gold.png',
              Colors.amber,
            ),
            const SizedBox(height: 12),
            _buildWinnerRow(
              entry.silverPlayer,
              entry.silverScore,
              'assets/image/medal/silver.png',
              Colors.grey[400]!,
            ),
            const SizedBox(height: 12),
            _buildWinnerRow(
              entry.bronzePlayer,
              entry.bronzeScore,
              'assets/image/medal/bronze.png',
              Colors.brown[300]!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerRow(
    HallOfFamePlayer? player,
    int score,
    String medalAsset,
    Color color,
  ) {
    if (player == null) return const SizedBox.shrink();

    return Row(
      children: [
        Image.asset(
          medalAsset,
          width: 24,
          height: 24,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.workspace_premium_rounded,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            player.username,
            style: GoogleFonts.vazirmatn(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          '$score pts',
          style: GoogleFonts.vazirmatn(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
