import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/core/widgets/app_cached_avatar.dart';
import '../../../app/core/widgets/app_loading_widget.dart';
import '../../../app/core/widgets/floating_app_bar.dart';
import '../../profile/views/player_profile_bottom_sheet.dart';
import '../controllers/league_controller.dart';
import '../models/league_tier_models.dart' hide LeagueGroupMember;
import '../models/weekend_league_models.dart';
import 'widgets/league_rules_sheet.dart';

/// Live leaderboard view for the user's Weekend League group (§1.2).
/// Displays group standings from GET /league/group with:
/// - Highlighted user row
/// - Visual promotion cut-line (after top X players)
/// - Visual relegation cut-line (before bottom Y players)
/// - Pull-to-refresh & 45s periodic polling while active
class LeagueGroupView extends StatelessWidget {
  final bool isEmbedded;

  const LeagueGroupView({super.key, this.isEmbedded = true});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LeagueController>();

    final content = Obx(() {
      debugPrint('👥 [LeagueGroupView] Building group view (isLoadingGroup: ${controller.isLoadingGroup.value}, members: ${controller.groupData.value?.members.length ?? 0})');
      if (controller.seasonStatus.value != null && !controller.isRegistered.value) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Center(
            child: Text(
              'league_not_registered_desc'.tr,
              style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      if (controller.isLoadingGroup.value && controller.groupData.value == null) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: AppLoadingWidget.gold(size: 36),
          ),
        );
      }

      if (controller.groupErrorMessage.value.isNotEmpty &&
          controller.groupData.value == null) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 36),
              const SizedBox(height: 8),
              Text(
                controller.groupErrorMessage.value,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => controller.fetchLeagueGroup(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text('retry'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                ),
              ),
            ],
          ),
        );
      }

      final group = controller.groupData.value;
      if (group == null || group.members.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Center(
            child: Text(
              'league_group_unavailable'.tr,
              style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13),
            ),
          ),
        );
      }

      return _buildGroupLeaderboard(context, controller, group);
    });

    if (isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: FloatingAppBar(
        titleText: 'league_group_leaderboard_title'.tr,
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => controller.fetchLeagueGroup(isPull: true),
          color: Colors.white,
          backgroundColor: const Color(0xFF161B22),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupLeaderboard(
    BuildContext context,
    LeagueController controller,
    LeagueGroupResponse group,
  ) {
    final members = group.members;
    final totalCount = members.length;
    final isBronze = group.tier == LeagueTier.bronze;

    // Use cutoffs from server; if server didn't send them (== 0), fall back to
    // sensible defaults so promotion/relegation badges always render.
    final promoCount = group.promotionCutoff > 0
        ? group.promotionCutoff
        : (totalCount >= 6 ? 3 : (totalCount ~/ 4).clamp(1, 3));
    final relegCount = isBronze
        ? 0
        : (group.relegationCutoff > 0
              ? group.relegationCutoff
              : (totalCount >= 6 ? 3 : (totalCount ~/ 4).clamp(1, 3)));
    final relegStartIndex = totalCount - relegCount;

    // Use index-based fallback when rank field may be 0 or missing from server
    bool isPromoByIndex(int idx) => idx < promoCount;
    bool isRelegByIndex(int idx) =>
        !isBronze && relegCount > 0 && idx >= relegStartIndex;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF30363D), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Bar: League Tier Badge + Countdown
          _buildTopBar(context, controller, group.tier),

          const SizedBox(height: 10),

          // 2. Explanation / Column Header (هدر توضیحات: رتبه | نام کاربری | امتیاز | جایزه)
          _buildExplanationHeader(),

          const SizedBox(height: 6),

          // 3. Player Cards List with 3D Gifts, Dark Metallic Gradients, and Avatars
          if (members.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              itemBuilder: (context, idx) {
                final member = members[idx];

                final isPromoDivider = idx == promoCount - 1;
                final isRelegDivider = !isBronze &&
                    relegCount > 0 &&
                    relegStartIndex > 0 &&
                    idx == relegStartIndex - 1;

                // Index-based detection is primary; rank-based is a secondary
                // fallback (rank can be 0 when the server omits the field).
                final isPromo = isPromoByIndex(idx) ||
                    (member.rank > 0 && member.rank <= promoCount);
                final isReleg = isRelegByIndex(idx) ||
                    (!isBronze &&
                        relegCount > 0 &&
                        member.rank > 0 &&
                        member.rank > relegStartIndex);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildGameMemberCard(
                      context: context,
                      member: member,
                      index: idx,
                      isPromo: isPromo,
                      isReleg: isReleg,
                    ),

                    // Visual Promotion Cut-line divider
                    if (isPromoDivider)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 6),
                        child: _buildCutLineDivider(
                          label: 'league_promotion_cutoff_label'.trParams({
                            'count': promoCount.toString(),
                          }),
                          color: const Color(0xFF00E676),
                          icon: Icons.keyboard_double_arrow_up_rounded,
                        ),
                      ),

                    // Visual Relegation Cut-line divider (omitted if Bronze)
                    if (isRelegDivider)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 6),
                        child: _buildCutLineDivider(
                          label: 'league_relegation_cutoff_label'.trParams({
                            'count': relegCount.toString(),
                          }),
                          color: const Color(0xFFFF1744),
                          icon: Icons.keyboard_double_arrow_down_rounded,
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  /// Top Bar: Current League Tier Pill + Remaining Time pill
  Widget _buildTopBar(
    BuildContext context,
    LeagueController controller,
    LeagueTier tier,
  ) {
    return Row(
      children: [
        // Current League Tier Badge (سطح لیگ: لیگ برنز، لیگ طلایی ...)
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => openLeagueRulesBottomSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tier.color.withValues(alpha: 0.22),
                    tier.color.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: tier.color.withValues(alpha: 0.55),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: tier.color.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    tier.assetPath,
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      tier.icon,
                      color: tier.color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tier.leagueTitleTr,
                    style: GoogleFonts.vazirmatn(
                      color: tier.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Countdown Card with English digits and clean styling
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF30363D),
                width: 1.2,
              ),
            ),
            child: Obx(() {
              final duration = controller.remainingCountdown.value;
              return Center(
                child: _buildCountdownWidget(duration),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// Explanation / Column Header (هدر توضیحات: رتبه | نام کاربری | امتیاز | جایزه)
  Widget _buildExplanationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // رتبه (Rank)
          SizedBox(
            width: 32,
            child: Text(
              'rank_col'.tr,
              style: const TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: 8),

          // Spacing for avatar + نام کاربری (Username)
          const SizedBox(width: 42),
          Expanded(
            child: Text(
              'player_col'.tr, // نام کاربری
              style: const TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.start,
            ),
          ),

          // امتیاز (Score)
          SizedBox(
            width: 58,
            child: Text(
              'score_col'.tr,
              style: const TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: 10),

          // جایزه (Prize / Gift)
          SizedBox(
            width: 30,
            child: Text(
              'prize_col'.tr,
              style: const TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Individual Player Card with custom Gold, Silver, Bronze dark gradients and 3D gifts
  Widget _buildGameMemberCard({
    required BuildContext context,
    required LeagueGroupMember member,
    required int index,
    required bool isPromo,
    required bool isReleg,
  }) {
    final isMe = member.isMe;

    // Gradients matching the reference image adapted for DARK theme:
    Gradient? cardGradient;
    Color cardBgColor = const Color(0xFF161B22);
    Color borderColor = const Color(0xFF262C36);
    double borderWidth = 1.0;
    List<BoxShadow>? shadows;

    if (member.rank == 1) {
      // 🥇 Rank 1: Deep Luxury Gold Gradient
      cardGradient = const LinearGradient(
        colors: [
          Color(0xFF3B2A06),
          Color(0xFF241B07),
          Color(0xFF161B22),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderColor = const Color(0xFFFFD700).withValues(alpha: 0.8);
      borderWidth = 1.5;
      shadows = [
        BoxShadow(
          color: const Color(0xFFFFD700).withValues(alpha: 0.18),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (member.rank == 2) {
      // 🥈 Rank 2: Sleek Metallic Silver Gradient
      cardGradient = const LinearGradient(
        colors: [
          Color(0xFF262C38),
          Color(0xFF1A202A),
          Color(0xFF161B22),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderColor = const Color(0xFFC0C0C0).withValues(alpha: 0.7);
      borderWidth = 1.3;
      shadows = [
        BoxShadow(
          color: const Color(0xFFC0C0C0).withValues(alpha: 0.12),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (member.rank == 3) {
      // 🥉 Rank 3: Rich Bronze / Copper Gradient
      cardGradient = const LinearGradient(
        colors: [
          Color(0xFF351F13),
          Color(0xFF24160E),
          Color(0xFF161B22),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderColor = const Color(0xFFCD7F32).withValues(alpha: 0.7);
      borderWidth = 1.3;
      shadows = [
        BoxShadow(
          color: const Color(0xFFCD7F32).withValues(alpha: 0.12),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (isMe) {
      // Current user outside top 3
      cardGradient = LinearGradient(
        colors: [
          Colors.amber.withValues(alpha: 0.18),
          const Color(0xFF1E1A12),
          const Color(0xFF161B22),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderColor = Colors.amber;
      borderWidth = 1.8;
      shadows = [
        BoxShadow(
          color: Colors.amber.withValues(alpha: 0.25),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    } else {
      // Regular dark card
      borderColor = const Color(0xFF282F3A);
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: cardGradient == null ? cardBgColor : null,
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: member.userId > 0
              ? () {
                  final leagueCtrl = Get.isRegistered<LeagueController>()
                      ? Get.find<LeagueController>()
                      : null;
                  final sId = leagueCtrl?.seasonStatus.value?.seasonId ??
                      leagueCtrl?.seasonStatus.value?.seasonNumber;
                  openPlayerProfileBottomSheet(
                    context,
                    member.userId,
                    seasonId: sId,
                    isLeagueContext: true,
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                // 1. Rank Badge / Number (رتبه)
                _buildRankBadge(member.rank),

                const SizedBox(width: 8),

                // 2. Avatar with Golden Ring Frame and Animated Status Chevron Badge
                _buildAvatarWithFrame(member, isPromo: isPromo, isReleg: isReleg),

                const SizedBox(width: 10),

                // 3. Username + Promotion / Relegation Pill (نام کاربری)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              member.username,
                              style: TextStyle(
                                color: member.rank == 1
                                    ? const Color(0xFFFFE082)
                                    : (member.rank == 2
                                        ? const Color(0xFFE2E8F0)
                                        : (member.rank == 3
                                            ? const Color(0xFFFFCCBC)
                                            : Colors.white)),
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 5),
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
                                'you_label'.tr,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (isPromo || isReleg) ...[
                        const SizedBox(height: 3),
                        _buildStatusIndicator(
                          isPromo: isPromo,
                          isReleg: isReleg,
                        ),
                      ],
                    ],
                  ),
                ),

                // 4. Score Display (امتیاز با ارقام انگلیسی عادی و غیربولد)
                SizedBox(
                  width: 58,
                  child: Text(
                    member.score % 1 == 0
                        ? member.score.toInt().toString()
                        : member.score.toStringAsFixed(1),
                    style: GoogleFonts.rubik(
                      color: member.rank == 1
                          ? const Color(0xFFFFD700)
                          : (member.rank == 2
                              ? const Color(0xFFECEFF1)
                              : (member.rank == 3
                                  ? const Color(0xFFFFAB91)
                                  : const Color(0xFFC9D1D9))),
                      fontWeight: FontWeight.normal,
                      fontSize: 13.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(width: 10),

                // 5. 3D Game Gift Box (کادو جمع‌وجور ۲۱)
                SizedBox(
                  width: 30,
                  child: Center(
                    child: GiftBoxWidget(
                      rank: member.rank,
                      size: 21,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Circular Rank Badge (1, 2, 3 in metallic medal, 4+ plain digits)
  Widget _buildRankBadge(int rank) {
    if (rank == 1) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFECB3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8F00).withValues(alpha: 0.35),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '1',
            style: GoogleFonts.rubik(
              color: const Color(0xFF2E1C03),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    if (rank == 2) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFECEFF1), Color(0xFF90A4AE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF546E7A).withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '2',
            style: GoogleFonts.rubik(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    if (rank == 3) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB74D), Color(0xFFD84315)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFCCBC), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFBF360C).withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '3',
            style: GoogleFonts.rubik(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    // Rank 4 and below: Plain English digits in normal weight
    return SizedBox(
      width: 30,
      child: Text(
        '$rank',
        style: GoogleFonts.rubik(
          color: const Color(0xFF8B949E),
          fontWeight: FontWeight.normal,
          fontSize: 13.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Avatar with metallic golden ring and animated status chevron badge
  Widget _buildAvatarWithFrame(
    LeagueGroupMember member, {
    required bool isPromo,
    required bool isReleg,
  }) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Golden Ring Frame
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFD54F),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFA000).withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipOval(
              child: AppCachedAvatar(
                avatarUrl: member.avatar,
                size: 38,
              ),
            ),
          ),

          // Animated Promotion (green up) / Relegation (red down) Chevron Badge
          if (isPromo || isReleg)
            Positioned(
              bottom: -3,
              left: -3,
              child: _AnimatedStatusChevronBadge(
                isPromo: isPromo,
                isReleg: isReleg,
              ),
            ),
        ],
      ),
    );
  }

  /// Compact status indicator badge (صعود / سقوط) in dark theme
  Widget _buildStatusIndicator({
    required bool isPromo,
    required bool isReleg,
  }) {
    if (isPromo) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: const Color(0xFF00E676).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: const Color(0xFF00E676).withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_drop_up_rounded,
              color: Color(0xFF00E676),
              size: 14,
            ),
            Text(
              'league_status_promoted_tag'.tr,
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (isReleg) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFF1744).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: const Color(0xFFFF1744).withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: Color(0xFFFF1744),
              size: 14,
            ),
            Text(
              'league_status_relegated_tag'.tr,
              style: const TextStyle(
                color: Color(0xFFFF1744),
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Visual cut-line divider in dark theme
  Widget _buildCutLineDivider({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Countdown widget with clean English digits and clear labels
  static Widget _buildCountdownWidget(Duration d) {
    if (d.isNegative || d.inSeconds <= 0) {
      return Text(
        'ended'.tr,
        style: GoogleFonts.vazirmatn(
          color: const Color(0xFF8B949E),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    final numStyle = GoogleFonts.rubik(
      color: const Color(0xFF00E676),
      fontWeight: FontWeight.normal,
      fontSize: 12.5,
    );
    final unitStyle = GoogleFonts.vazirmatn(
      color: const Color(0xFF8B949E),
      fontWeight: FontWeight.normal,
      fontSize: 11,
    );
    final colonStyle = GoogleFonts.rubik(
      color: const Color(0xFF30363D),
      fontWeight: FontWeight.normal,
      fontSize: 12,
    );

    final dUnit = days == 1 ? 'day_unit'.tr : 'days_unit'.tr;
    final hUnit = hours == 1 ? 'hour_unit'.tr : 'hours_unit'.tr;
    final mUnit = minutes == 1 ? 'minute_unit'.tr : 'minutes_unit'.tr;
    final sUnit = seconds == 1 ? 'second_unit'.tr : 'seconds_unit'.tr;

    if (days > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$days', style: numStyle),
          const SizedBox(width: 3),
          Text(dUnit, style: unitStyle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(':', style: colonStyle),
          ),
          Text('$hours', style: numStyle),
          const SizedBox(width: 3),
          Text(hUnit, style: unitStyle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(':', style: colonStyle),
          ),
          Text('$minutes', style: numStyle),
          const SizedBox(width: 3),
          Text(mUnit, style: unitStyle),
        ],
      );
    } else if (hours > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$hours', style: numStyle),
          const SizedBox(width: 3),
          Text(hUnit, style: unitStyle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(':', style: colonStyle),
          ),
          Text('$minutes', style: numStyle),
          const SizedBox(width: 3),
          Text(mUnit, style: unitStyle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(':', style: colonStyle),
          ),
          Text('$seconds', style: numStyle),
          const SizedBox(width: 2),
          Text(sUnit, style: unitStyle),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$minutes', style: numStyle),
        const SizedBox(width: 3),
        Text(mUnit, style: unitStyle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(':', style: colonStyle),
        ),
        Text('$seconds', style: numStyle),
        const SizedBox(width: 2),
        Text(sUnit, style: unitStyle),
      ],
    );
  }
}

/// 3D Game Gift Box Widget (§کادو) with compact size (21px)
/// Rank 1: Royal Magenta/Purple with Gold Ribbon
/// Rank 2: Sky Blue with White Ribbon
/// Rank 3: Amber/Gold with Cream Ribbon
/// Rank 4+: Emerald Green with Lime Ribbon
class GiftBoxWidget extends StatelessWidget {
  final int rank;
  final double size;

  const GiftBoxWidget({super.key, required this.rank, this.size = 21});

  @override
  Widget build(BuildContext context) {
    Color boxTopColor;
    Color boxBottomColor;
    Color ribbonColor;
    Color shadowColor;

    if (rank == 1) {
      // 🎁 Magenta / Purple with Yellow Ribbon (رتبه ۱)
      boxTopColor = const Color(0xFFD81B60);
      boxBottomColor = const Color(0xFF880E4F);
      ribbonColor = const Color(0xFFFFEE58);
      shadowColor = const Color(0xFFAD1457).withValues(alpha: 0.4);
    } else if (rank == 2) {
      // 🎁 Cyan / Sky Blue with White Ribbon (رتبه ۲)
      boxTopColor = const Color(0xFF29B6F6);
      boxBottomColor = const Color(0xFF0277BD);
      ribbonColor = const Color(0xFFFFFFFF);
      shadowColor = const Color(0xFF0288D1).withValues(alpha: 0.4);
    } else if (rank == 3) {
      // 🎁 Amber / Gold with Cream Ribbon (رتبه ۳)
      boxTopColor = const Color(0xFFFFB300);
      boxBottomColor = const Color(0xFFE65100);
      ribbonColor = const Color(0xFFFFF9C4);
      shadowColor = const Color(0xFFFF8F00).withValues(alpha: 0.4);
    } else {
      // 🎁 Emerald Green with Light Green Ribbon (رتبه‌های بعدی)
      boxTopColor = const Color(0xFF66BB6A);
      boxBottomColor = const Color(0xFF2E7D32);
      ribbonColor = const Color(0xFFDCEDC8);
      shadowColor = const Color(0xFF388E3C).withValues(alpha: 0.35);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Box Body
          Positioned(
            bottom: 1.0,
            child: Container(
              width: size * 0.74,
              height: size * 0.54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [boxTopColor, boxBottomColor],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(size * 0.12),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 2.5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: size * 0.18,
                  height: size * 0.54,
                  color: ribbonColor,
                ),
              ),
            ),
          ),

          // Box Lid
          Positioned(
            top: size * 0.22,
            child: Container(
              width: size * 0.84,
              height: size * 0.2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    boxTopColor.withValues(alpha: 0.95),
                    boxBottomColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(size * 0.08),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 1.5,
                    offset: const Offset(0, 0.8),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: size * 0.18,
                  height: size * 0.2,
                  color: ribbonColor,
                ),
              ),
            ),
          ),

          // Ribbon Bow Loops on Top
          Positioned(
            top: 0.5,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: -0.35,
                  child: Container(
                    width: size * 0.22,
                    height: size * 0.18,
                    decoration: BoxDecoration(
                      color: ribbonColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(size * 0.1),
                        bottomLeft: Radius.circular(size * 0.1),
                        topRight: Radius.circular(size * 0.04),
                      ),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.12),
                        width: 0.4,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: size * 0.12,
                  height: size * 0.12,
                  decoration: BoxDecoration(
                    color: ribbonColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Transform.rotate(
                  angle: 0.35,
                  child: Container(
                    width: size * 0.22,
                    height: size * 0.18,
                    decoration: BoxDecoration(
                      color: ribbonColor,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(size * 0.1),
                        bottomRight: Radius.circular(size * 0.1),
                        topLeft: Radius.circular(size * 0.04),
                      ),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.12),
                        width: 0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated bouncing & glowing promotion/relegation chevron badge for leaderboard avatars
class _AnimatedStatusChevronBadge extends StatefulWidget {
  final bool isPromo;
  final bool isReleg;

  const _AnimatedStatusChevronBadge({
    required this.isPromo,
    required this.isReleg,
  });

  @override
  State<_AnimatedStatusChevronBadge> createState() =>
      _AnimatedStatusChevronBadgeState();
}

class _AnimatedStatusChevronBadgeState extends State<_AnimatedStatusChevronBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late Animation<double> _translateAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _initAnimations();
  }

  void _initAnimations() {
    // Upward float for promotion, downward float for relegation
    _translateAnim = Tween<double>(
      begin: widget.isPromo ? 1.5 : -1.5,
      end: widget.isPromo ? -3.5 : 3.5,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutSine,
    ));
  }

  @override
  void didUpdateWidget(covariant _AnimatedStatusChevronBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPromo != widget.isPromo ||
        oldWidget.isReleg != widget.isReleg) {
      _initAnimations();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPromo && !widget.isReleg) {
      return const SizedBox.shrink();
    }

    final isPromo = widget.isPromo;
    final color = isPromo ? const Color(0xFF00E676) : const Color(0xFFFF5252);
    final icon = isPromo
        ? Icons.keyboard_double_arrow_up_rounded
        : Icons.keyboard_double_arrow_down_rounded;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _translateAnim.value),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        );
      },
    );
  }
}
