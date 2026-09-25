import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/widgets/app_loading_widget.dart';
import '../../../app/core/widgets/floating_app_bar.dart';
import '../controllers/leaderboard_controller.dart';
import 'widgets/leaderboard_header_bar.dart';
import 'widgets/online_league_card.dart';
import '../../profile/views/player_profile_bottom_sheet.dart';

/// Global Leaderboard Screen with Mode-Specific Tabs.
class LeaderboardView extends StatelessWidget {
  const LeaderboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LeaderboardController());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FloatingAppBar(
        titleText: 'global_league'.tr,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kPrimaryColor),
            onPressed: () => controller.refreshAll(),
            tooltip: 'Refresh Rankings',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF142032), Color(0xFF0D1117), Color(0xFF06090E)],
            stops: [0.0, 0.28, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              SizedBox(
                height: FloatingAppBar.preferredTotalHeight(context) + 6,
              ),

              // Mode Selector Tabs (Classic, Infection, Blind Memory, etc.)
              _buildModeTabs(controller),

              const SizedBox(height: 12),

              // Main Content Area for selected mode
              Expanded(child: _buildLeaderboardContent(controller)),
            ],
          ),
        ),
      ),
    );
  }

  /// Horizontal tab selector for game modes
  Widget _buildModeTabs(LeaderboardController controller) {
    return Obx(() {
      final modes = controller.leaderboardGameModes;
      final selectedId = controller.selectedModeId.value;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: modes.map((modeConfig) {
            final isSelected = modeConfig.id == selectedId;
            final color = modeConfig.accentColor;

            return GestureDetector(
              onTap: () => controller.selectMode(modeConfig.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFF30363D),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.25),
                            blurRadius: 10,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Icon(
                      modeConfig.icon,
                      color: isSelected ? color : Colors.white54,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      modeConfig.titleTr,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  /// Active leaderboard list content
  Widget _buildLeaderboardContent(LeaderboardController controller) {
    return Obx(() {
      final onlineEntries = controller.modesEntries;
      final isLoading = controller.isLoadingModes.value;
      final statusMsg = controller.modesErrorMessage.value;
      final activeModeConfig = controller.leaderboardGameModes.firstWhere(
        (m) => m.id == controller.selectedModeId.value,
        orElse: () => controller.leaderboardGameModes.first,
      );

      return CustomScrollView(
        cacheExtent: 180, // Lazy loading: only pre-render items close to viewport
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Header for Online Leaderboard
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.public_rounded, color: kGoldColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${activeModeConfig.titleTr} ${'top_players'.tr}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: kGoldColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    if (isLoading)
                      const AppLoadingWidget.small(size: 16, color: kGoldColor),
                  ],
                ),

                if (statusMsg.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusMsg,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                if (onlineEntries.isNotEmpty) ...[
                  LeaderboardHeaderBar(
                    accentColor: activeModeConfig.accentColor,
                    isTime: activeModeConfig.id == 'infection',
                  ),
                  const SizedBox(height: 8),
                ],
              ]),
            ),
          ),

          // Leaderboard Entries or Empty State
          if (onlineEntries.isEmpty && !isLoading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'no_records_yet'.tr,
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
              sliver: SliverList.separated(
                itemCount: onlineEntries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = onlineEntries[index];
                  return OnlineLeagueCard(
                    entry: entry,
                    accentColor: activeModeConfig.accentColor,
                    modeId: activeModeConfig.id,
                    onTap: entry.userId > 0
                        ? () =>
                              openPlayerProfileBottomSheet(context, entry.userId)
                        : null,
                  );
                },
              ),
            ),
        ],
      );
    });
  }
}
