import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/widgets/app_loading_widget.dart';
import '../../../app/core/widgets/floating_app_bar.dart';
import '../../../app/routes/app_routes.dart';

import '../controllers/league_controller.dart';
import '../models/league_tier_models.dart' hide LeagueGroupMember;
import '../models/weekend_league_models.dart';
import '../widgets/league_confetti_overlay.dart';
import 'league_group_view.dart';
import 'widgets/league_rules_sheet.dart';
import 'widgets/league_top3_podium_widget.dart';

/// Main entry point for the Weekend League feature (GET /league/status).
/// Screen state dynamically transforms based on the 5 season phases:
/// - registration_open
/// - grouping
/// - active
/// - completed
/// - cancelled_low_turnout
class LeagueHubView extends StatefulWidget {
  const LeagueHubView({super.key});

  @override
  State<LeagueHubView> createState() => _LeagueHubViewState();
}

class _LeagueHubViewState extends State<LeagueHubView> {
  late final LeagueController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<LeagueController>();

    // Synchronously reset state so that the initial frame ALWAYS shows clean loading
    controller.seasonStatus.value = null;
    controller.groupData.value = null;
    controller.isLoading.value = true;
    controller.fetchLeagueStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: FloatingAppBar(
        titleText: 'weekend_league_title'.tr,
        accentColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.help_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => openLeagueRulesBottomSheet(context),
            tooltip: 'rules'.tr,
          ),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: Obx(() {
        final status = controller.seasonStatus.value;
        final phase = controller.phase;
        final isRegistered =
            controller.isRegistered.value || (status?.isRegistered ?? false);

        if (status != null &&
            phase == LeagueSeasonPhase.active &&
            isRegistered) {
          return Container(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              MediaQuery.of(context).padding.bottom + 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117).withValues(alpha: 0.96),
              border: const Border(
                top: BorderSide(color: Color(0xFF21262D), width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.leagueAttemptSelector),
              icon: const Icon(Icons.play_arrow_rounded, size: 24),
              label: Text(
                'play_league_match'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      }),
      body: Obx(() {
        final status = controller.seasonStatus.value;
        final phase = controller.phase;
        final isLoading = controller.isLoading.value;
        final errorMessage = controller.errorMessage.value;

        debugPrint(
          '🎨 [LeagueHubView] Building body for phase: ${phase.name} (isLoading: $isLoading, hasStatus: ${status != null})',
        );

        if (status == null) {
          if (errorMessage.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      errorMessage,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => controller.fetchLeagueStatus(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text('retry'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const AppLoadingWidget.gold(fullScreen: true);
        }

        final content = RefreshIndicator(
          onRefresh: () => controller.fetchLeagueStatus(isPullToRefresh: true),
          color: Colors.white,
          backgroundColor: const Color(0xFF161B22),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Top padding
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Season header chip (only in non-active phases)
              if (phase != LeagueSeasonPhase.active) ...[
                SliverToBoxAdapter(
                  child: _buildSeasonHeaderChip(controller, status),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],

              // Phase-specific content
              if (phase == LeagueSeasonPhase.registrationOpen)
                SliverToBoxAdapter(
                  child: _buildRegistrationOpenPhase(
                    context,
                    controller,
                    status,
                  ),
                )
              else if (phase == LeagueSeasonPhase.grouping)
                SliverToBoxAdapter(
                  child: _buildGroupingPhase(context, controller, status),
                )
              else if (phase == LeagueSeasonPhase.active)
                ..._buildActivePhaseSliver(context, controller, status)
              else if (phase == LeagueSeasonPhase.completed)
                SliverToBoxAdapter(
                  child: _buildCompletedPhase(context, controller, status),
                )
              else if (phase == LeagueSeasonPhase.cancelledLowTurnout)
                SliverToBoxAdapter(
                  child: _buildCancelledPhase(context, controller, status),
                )
              else
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: AppLoadingWidget.gold(size: 36),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        );

        if (phase == LeagueSeasonPhase.completed) {
          return Stack(
            children: [
              content,
              Positioned.fill(
                child: LeagueConfettiOverlay(
                  key: ValueKey(
                    'league_confetti_${status.seasonId ?? status.seasonNumber}',
                  ),
                ),
              ),
            ],
          );
        }

        return content;
      }),
    );
  }

  // ===========================================================================
  // SEASON HEADER CHIP
  // ===========================================================================

  Widget _buildSeasonHeaderChip(
    LeagueController controller,
    LeagueSeasonStatus? status,
  ) {
    final seasonNum = status?.seasonNumber ?? 1;
    final phaseTitle = _getPhaseTitle(controller.phase);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${'season'.tr} $seasonNum',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getPhaseColor(controller.phase).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getPhaseColor(
                    controller.phase,
                  ).withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                phaseTitle,
                style: TextStyle(
                  color: _getPhaseColor(controller.phase),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. REGISTRATION OPEN PHASE (§1.1)
  // ===========================================================================

  Widget _buildRegistrationOpenPhase(
    BuildContext context,
    LeagueController controller,
    LeagueSeasonStatus status,
  ) {
    final isRegistered = controller.isRegistered.value || status.isRegistered;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Registration Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isRegistered
                    ? const Color(0xFF00E676).withValues(alpha: 0.6)
                    : const Color(0xFF30363D),
                width: isRegistered ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card Header: Cost / Free Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'weekend_league_title'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (status.isFreeEntry)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF00E676,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00E676)),
                        ),
                        child: Text(
                          'league_free_entry_badge'.tr,
                          style: const TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          const Icon(
                            Icons.monetization_on_rounded,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'league_cost_label'.trParams({
                              'cost': status.entryCost.toString(),
                            }),
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 18),

                // Countdown Timer Box
                _buildCountdownBox(
                  context,
                  controller,
                  label: isRegistered
                      ? 'league_starts_in'.trParams({
                          'time': _formatDuration(
                            controller.remainingCountdown.value,
                          ),
                        })
                      : 'league_registration_closes_in'.trParams({
                          'time': _formatDuration(
                            controller.remainingCountdown.value,
                          ),
                        }),
                  accentColor: isRegistered
                      ? const Color(0xFF00E676)
                      : Colors.white,
                ),

                const SizedBox(height: 20),

                // Registered Confirmed State OR Register Button
                if (isRegistered) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF00E676).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF00E676),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'league_registered_confirmed'.trParams({
                              'time': _formatDurationShort(
                                controller.remainingCountdown.value,
                              ),
                            }),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Obx(() {
                    final isRegistering = controller.isRegistering.value;
                    return ElevatedButton.icon(
                      onPressed: isRegistering
                          ? null
                          : () => controller.registerForLeague(),
                      icon: isRegistering
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                          : const Icon(Icons.how_to_reg_rounded, size: 20),
                      label: Text(
                        'league_register_btn'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Auto-enroll Toggle Card (§1.3)
          _buildAutoEnrollCard(controller),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. GROUPING PHASE (§1.1)
  // ===========================================================================

  Widget _buildGroupingPhase(
    BuildContext context,
    LeagueController controller,
    LeagueSeasonStatus status,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.hourglass_top_rounded,
              color: Color(0xFF00E5FF),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'league_grouping'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'league_grouping_msg'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            _buildCountdownBox(
              context,
              controller,
              label: 'league_starts_in'.trParams({
                'time': _formatDuration(controller.remainingCountdown.value),
              }),
              accentColor: const Color(0xFF00E5FF),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. ACTIVE PHASE (§1.1 & §1.2)
  // ===========================================================================

  List<Widget> _buildActivePhaseSliver(
    BuildContext context,
    LeagueController controller,
    LeagueSeasonStatus status,
  ) {
    if (!status.isRegistered) {
      return [
        SliverToBoxAdapter(
          child: _buildActiveNotRegisteredView(context, controller, status),
        ),
      ];
    }

    return [
      // Live Group Leaderboard embedded directly (includes the unified header)
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: LeagueGroupView(),
        ),
      ),

      // Bottom padding so content is not obscured by bottom play button
      const SliverToBoxAdapter(child: SizedBox(height: 90)),
    ];
  }

  /// View shown when season is currently active, but player did not register before deadline
  Widget _buildActiveNotRegisteredView(
    BuildContext context,
    LeagueController controller,
    LeagueSeasonStatus status,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Countdown until season ends
          _buildCountdownBox(
            context,
            controller,
            label: 'league_ends_in'.trParams({
              'time': _formatDuration(controller.remainingCountdown.value),
            }),
            accentColor: const Color(0xFFFFB300),
          ),
          const SizedBox(height: 16),

          // Not-registered informational card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_busy_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'league_not_registered_title'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'league_not_registered_desc'.tr,
                  style: const TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFF30363D), height: 1),
                const SizedBox(height: 16),
                _buildAutoEnrollCard(controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. COMPLETED PHASE (§1.1)
  // ===========================================================================

  Widget _buildCompletedPhase(
    BuildContext context,
    LeagueController controller,
    LeagueSeasonStatus status,
  ) {
    final group = controller.groupData.value;
    final topMembers = (group != null && group.members.isNotEmpty)
        ? group.members.take(3).toList()
        : <LeagueGroupMember>[];

    final myMember = group?.members.cast<LeagueGroupMember?>().firstWhere(
      (m) => m?.isMe == true,
      orElse: () => null,
    );

    final result = status.completedResult;

    // Resolve user's rank: fallback to group ranking if result.rank is not provided
    final rank = (result?.rank != null && result!.rank! > 0)
        ? result.rank!
        : (group?.myRank ?? myMember?.rank ?? 0);

    // The tier the user competed in during this completed season.
    // group?.tier is the exact group tier the user was enrolled in.
    final playedTier = group?.tier ??
        result?.previousTier ??
        (status.tier != null && (result?.isPromoted == true || rank == 1)
            ? status.tier!.previousTier
            : status.tier) ??
        LeagueTier.bronze;

    // Promotion cutoff (e.g. top 10 or 20%)
    final totalMembers = group?.members.length ?? 0;
    final promoCutoff = (group != null && group.promotionCutoff > 0)
        ? group.promotionCutoff
        : (totalMembers > 0 ? (totalMembers * 0.20).ceil().clamp(1, 50) : 10);

    // Relegation cutoff (e.g. bottom 15%, but not for bronze)
    final relegCutoff = (group != null && group.relegationCutoff > 0)
        ? group.relegationCutoff
        : (totalMembers > 0 ? (totalMembers * 0.15).floor() : 0);

    // Determine promotion/relegation/stayed status
    final hasScoreOrAttempts =
        (myMember != null && myMember.score > 0) ||
        (group?.myScore != null && group!.myScore! > 0) ||
        (result?.rank != null && result!.rank! > 0);

    final bool isPromoted = result?.isPromoted == true ||
        (rank > 0 && rank <= promoCutoff && hasScoreOrAttempts);

    final bool isRelegated = !isPromoted &&
        playedTier != LeagueTier.bronze &&
        (result?.isRelegated == true ||
            (relegCutoff > 0 &&
                totalMembers > 0 &&
                rank > (totalMembers - relegCutoff)));

    String statusText;
    Color badgeColor;
    LeagueTier displayTier;

    if (isPromoted) {
      displayTier = playedTier.nextTier;
      statusText = 'league_status_promoted'.trParams({
        'tier': displayTier.displayNameTr,
      });
      badgeColor = const Color(0xFF00E676);
    } else if (isRelegated) {
      displayTier = playedTier.previousTier;
      statusText = 'league_status_relegated'.trParams({
        'tier': displayTier.displayNameTr,
      });
      badgeColor = const Color(0xFFFF1744);
    } else {
      displayTier = playedTier;
      statusText = 'league_status_stayed'.trParams({
        'tier': displayTier.displayNameTr,
      });
      badgeColor = displayTier.color;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Champions / Top 3 Podium (نتایج و برترین‌های فصل)
          if (topMembers.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withValues(alpha: 0.2),
                    const Color(0xFF161B22),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'league_season_champions'.trParams({
                      'season': status.seasonNumber.toString(),
                    }),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            LeagueTop3PodiumWidget(
              topMembers: topMembers,
              seasonId: status.seasonId ?? status.seasonNumber,
            ),
            const SizedBox(height: 20),
          ],

          // 2. Personal Season Result Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Column(
              children: [
                Icon(
                  isPromoted
                      ? Icons.military_tech_rounded
                      : Icons.workspace_premium_rounded,
                  color: isPromoted ? const Color(0xFF00E676) : displayTier.color,
                  size: 56,
                ),
                const SizedBox(height: 12),
                Text(
                  'league_completed'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Rank & Badge Display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (rank > 0)
                        Text(
                          'league_rank_display'.trParams({
                            'rank': rank.toString(),
                          }),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  'league_next_registration_opens'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. CANCELLED LOW TURNOUT PHASE (§1.1)
  // ===========================================================================

  Widget _buildCancelledPhase(
    BuildContext context,
    LeagueController controller,
    LeagueSeasonStatus status,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cancel_outlined,
              color: Colors.orangeAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'league_cancelled_low_turnout'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'league_cancelled_msg'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // REUSABLE COMPONENTS
  // ===========================================================================

  Widget _buildCountdownBox(
    BuildContext context,
    LeagueController controller, {
    required String label,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, color: accentColor, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoEnrollCard(LeagueController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.autorenew_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'auto_enroll_label'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'auto_enroll_sub'.tr,
                  style: const TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            return Switch(
              value: controller.autoEnrollEnabled.value,
              onChanged: controller.isTogglingAutoEnroll.value
                  ? null
                  : (val) => controller.toggleAutoEnroll(val),
              activeColor: Colors.white,
              activeTrackColor: Colors.white.withValues(alpha: 0.4),
              inactiveThumbColor: const Color(0xFF8B949E),
              inactiveTrackColor: const Color(0xFF21262D),
            );
          }),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.isNegative || d.inSeconds <= 0) return '00:00:00';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    final dUnit = days == 1 ? 'day_unit'.tr : 'days_unit'.tr;
    final hUnit = hours == 1 ? 'hour_unit'.tr : 'hours_unit'.tr;
    final mUnit = minutes == 1 ? 'minute_unit'.tr : 'minutes_unit'.tr;
    final sUnit = seconds == 1 ? 'second_unit'.tr : 'seconds_unit'.tr;

    if (days > 0) {
      return '$days $dUnit $hours $hUnit $minutes $mUnit';
    }
    return '$hours $hUnit $minutes $mUnit $seconds $sUnit';
  }

  String _formatDurationShort(Duration d) {
    if (d.isNegative || d.inSeconds <= 0) {
      return '0 ${'hours_unit'.tr} 0 ${'minutes_unit'.tr}';
    }
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;

    final dUnit = days == 1 ? 'day_unit'.tr : 'days_unit'.tr;
    final hUnit = hours == 1 ? 'hour_unit'.tr : 'hours_unit'.tr;
    final mUnit = minutes == 1 ? 'minute_unit'.tr : 'minutes_unit'.tr;

    if (days > 0) {
      return '$days $dUnit $hours $hUnit';
    }
    return '$hours $hUnit $minutes $mUnit';
  }

  String _getPhaseTitle(LeagueSeasonPhase phase) {
    switch (phase) {
      case LeagueSeasonPhase.registrationOpen:
        return 'league_registration_open'.tr;
      case LeagueSeasonPhase.grouping:
        return 'league_grouping'.tr;
      case LeagueSeasonPhase.active:
        return 'league_active'.tr;
      case LeagueSeasonPhase.completed:
        return 'league_completed'.tr;
      case LeagueSeasonPhase.cancelledLowTurnout:
        return 'league_cancelled_low_turnout'.tr;
      case LeagueSeasonPhase.unknown:
        return 'weekend_league_title'.tr;
    }
  }

  Color _getPhaseColor(LeagueSeasonPhase phase) {
    switch (phase) {
      case LeagueSeasonPhase.registrationOpen:
        return Colors.white;
      case LeagueSeasonPhase.grouping:
        return const Color(0xFF00E5FF);
      case LeagueSeasonPhase.active:
        return const Color(0xFF00E676);
      case LeagueSeasonPhase.completed:
        return const Color(0xFFB388FF);
      case LeagueSeasonPhase.cancelledLowTurnout:
        return Colors.orangeAccent;
      case LeagueSeasonPhase.unknown:
        return Colors.white70;
    }
  }
}
