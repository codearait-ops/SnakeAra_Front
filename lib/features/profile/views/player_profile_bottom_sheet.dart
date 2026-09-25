import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../app/core/constants/app_constants.dart';
import '../../../app/core/widgets/app_loading_widget.dart';
import '../../game/models/game_mode_config.dart';
import '../../league/models/league_player_summary_model.dart';
import '../../league/widgets/league_tier_badge_widget.dart';
import '../controllers/player_profile_controller.dart';
import '../models/universal_player_profile.dart';
import '../widgets/game_mode_donut_chart.dart';

void openPlayerProfileBottomSheet(
  BuildContext context,
  int userId, {
  int? seasonId,
  bool isLeagueContext = false,
}) {
  openPlayerProfileDialog(
    context,
    userId,
    seasonId: seasonId,
    isLeagueContext: isLeagueContext,
  );
}

void openPlayerProfileDialog(
  BuildContext context,
  int userId, {
  int? seasonId,
  bool isLeagueContext = false,
}) {
  debugPrint(
    '>>> [MODAL POPUP] openPlayerProfileDialog triggered for userId: $userId, seasonId: $seasonId, isLeague: $isLeagueContext',
  );
  if (userId <= 0) {
    debugPrint('>>> [POPUP ERROR] Invalid userId: $userId <= 0');
    Get.snackbar(
      'player_profile'.tr,
      '${'err_profile_id_invalid'.tr} ($userId)',
    );
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (context) => PlayerProfileDialog(
      userId: userId,
      seasonId: seasonId,
      isLeagueContext: isLeagueContext,
    ),
  );
}

class PlayerProfileBottomSheet extends StatelessWidget {
  final int userId;
  final int? seasonId;
  final bool isLeagueContext;

  const PlayerProfileBottomSheet({
    super.key,
    required this.userId,
    this.seasonId,
    this.isLeagueContext = false,
  });

  @override
  Widget build(BuildContext context) {
    return PlayerProfileDialog(
      userId: userId,
      seasonId: seasonId,
      isLeagueContext: isLeagueContext,
    );
  }
}

class PlayerProfileDialog extends StatefulWidget {
  final int userId;
  final int? seasonId;
  final bool isLeagueContext;

  const PlayerProfileDialog({
    super.key,
    required this.userId,
    this.seasonId,
    this.isLeagueContext = false,
  });

  @override
  State<PlayerProfileDialog> createState() => _PlayerProfileDialogState();
}

class _PlayerProfileDialogState extends State<PlayerProfileDialog> {
  late final PlayerProfileController _controller;
  String? _selectedMode;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      PlayerProfileController(),
      tag: '${widget.userId}_${widget.seasonId ?? 0}',
    );
    _controller.fetchProfile(
      widget.userId,
      seasonId: widget.seasonId,
      isLeagueContext: widget.isLeagueContext || (widget.seasonId != null),
    );
  }

  @override
  void dispose() {
    Get.delete<PlayerProfileController>(
      tag: '${widget.userId}_${widget.seasonId ?? 0}',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dismiss when tapping outside the centered dialog card
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: 440,
              maxHeight: screenSize.height * 0.90,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF30363D), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: kGoldColor.withValues(alpha: 0.08),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Obx(() {
                if (_controller.isLoading.value) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildInlineTopBar(),
                        const SizedBox(height: 28),
                        Center(
                          child: AppLoadingWidget.gold(
                            size: 34,
                            message: _safeTr(
                              'loading_data',
                              Get.locale?.languageCode == 'fa'
                                  ? 'در حال دریافت اطلاعات...'
                                  : 'Loading data...',
                            ),
                            messageStyle: GoogleFonts.vazirmatn(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                }

              if (_controller.errorMessage.value.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInlineTopBar(),
                      const SizedBox(height: 18),
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 38,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _controller.errorMessage.value,
                        style: GoogleFonts.vazirmatn(
                          color: Colors.white70,
                          fontSize: 13.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () => _controller.fetchProfile(
                          widget.userId,
                          seasonId: widget.seasonId,
                          isLeagueContext:
                              widget.isLeagueContext ||
                              (widget.seasonId != null),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                        ),
                        child: Text('retry'.tr),
                      ),
                    ],
                  ),
                );
              }

              // If League Summary is available, render compact league view
              final leagueSummary = _controller.leagueSummary.value;
              if (leagueSummary != null) {
                return ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    _buildInlineTopBar(),
                    const SizedBox(height: 6),
                    _buildCompactLeagueHeader(leagueSummary),
                    const SizedBox(height: 14),
                    _buildCompactSectionTitle(
                      '🎮 ${_safeTr('league_stats_title', 'عملکرد در لیگ')}',
                    ),
                    const SizedBox(height: 8),
                    _buildCompactLeagueModeGrid(leagueSummary.modeStats),
                    const SizedBox(height: 14),
                    _buildCompactSectionTitle(
                      '🏆 ${_safeTr('hall_of_fame_title', 'افتخارات تالار مشاهیر')}',
                    ),
                    const SizedBox(height: 8),
                    _buildHallOfFameShowcase(leagueSummary.hallOfFame),
                    const SizedBox(height: 10),
                    _buildDailyChallengeShowcase(
                      leagueSummary.dailyChallengeStats,
                    ),
                  ],
                );
              }

              // Fallback / Standard Profile view
              final profile = _controller.profile.value;
              if (profile == null) {
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'profile_not_found'.tr,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
                );
              }

              return ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                children: [
                  _buildInlineTopBar(),
                  const SizedBox(height: 10),
                  _buildHeader(profile),
                  const SizedBox(height: 18),
                  _buildSectionTitle(
                    '🏆 ${_safeTr('hall_of_fame_title', 'تالار مشاهیر و چالش‌ها')}',
                  ),
                  _buildUniversalShowcases(profile),
                  const SizedBox(height: 18),
                  _buildSectionTitle(
                    '🎮 ${_safeTr('game_modes_stats', 'آمار مودهای بازی')}',
                  ),
                  _buildGameModesSection(profile),
                ],
              );
            }),
          ),
        ),
      ],
    ),
  );
}

  String _safeTr(String key, String fallback) {
    final res = key.tr;
    if (res.isEmpty || res == key) return fallback;
    return res;
  }

  Widget _buildCompactSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.vazirmatn(
        color: kGoldColor,
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.vazirmatn(
          color: kGoldColor,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildInlineTopBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.person_pin_rounded, color: kGoldColor, size: 16),
              const SizedBox(width: 6),
              Text(
                _safeTr('player_profile', 'پروفایل بازیکن'),
                style: GoogleFonts.vazirmatn(
                  color: Colors.white70,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // COMPACT LEAGUE DESIGN
  // ===========================================================================

  Widget _buildCompactLeagueHeader(LeaguePlayerSummary summary) {
    final user = summary.user;
    final presetAvatar = getAvatarById(user.avatarId ?? 'avatar_1');
    final hasValidUrl =
        user.avatarUrl != null &&
        user.avatarUrl!.isNotEmpty &&
        (user.avatarUrl!.startsWith('http://') ||
            user.avatarUrl!.startsWith('https://'));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.tier.color.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Compact Avatar with Tier Ring
          Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [user.tier.color, presetAvatar.secondaryColor],
              ),
              boxShadow: [
                BoxShadow(
                  color: user.tier.color.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0D1117),
              ),
              padding: const EdgeInsets.all(1.5),
              child: ClipOval(
                child: hasValidUrl
                    ? CachedNetworkImage(
                        imageUrl: user.avatarUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 150,
                        memCacheHeight: 150,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: Colors.grey[800]!,
                          highlightColor: Colors.grey[600]!,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          presetAvatar.icon,
                          color: Colors.white70,
                          size: 28,
                        ),
                      )
                    : (presetAvatar.imageUrl != null &&
                          presetAvatar.imageUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: presetAvatar.imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 150,
                        memCacheHeight: 150,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: Colors.grey[800]!,
                          highlightColor: Colors.grey[600]!,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          presetAvatar.icon,
                          color: Colors.white70,
                          size: 28,
                        ),
                      )
                    : Icon(presetAvatar.icon, color: Colors.white70, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // User Info & Badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.username,
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Rank (رنک)
                      if (user.currentRank != null && user.currentRank! > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: user.currentRank == 1
                                ? kGoldColor.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: user.currentRank == 1
                                  ? kGoldColor.withValues(alpha: 0.5)
                                  : Colors.white24,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (user.currentRank == 1)
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(end: 4),
                                  child: Image.asset(
                                    'assets/image/medal/gold.png',
                                    width: 12,
                                    height: 12,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              else if (user.currentRank == 2)
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(end: 4),
                                  child: Image.asset(
                                    'assets/image/medal/silver.png',
                                    width: 12,
                                    height: 12,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              else if (user.currentRank == 3)
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(end: 4),
                                  child: Image.asset(
                                    'assets/image/medal/bronze.png',
                                    width: 12,
                                    height: 12,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(end: 4),
                                  child: Image.asset(
                                    user.tier.assetPath,
                                    width: 11,
                                    height: 11,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              Text(
                                '#${user.currentRank} ${_safeTr('rank_col', 'رتبه')}',
                                style: GoogleFonts.vazirmatn(
                                  color: user.currentRank == 1
                                      ? kGoldColor
                                      : (user.currentRank == 2
                                          ? const Color(0xFFE0E0E0)
                                          : (user.currentRank == 3
                                              ? const Color(0xFFFFB74D)
                                              : Colors.white70)),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],

                      // 2. Score (امتیاز)
                      if (user.finalScore != null && user.finalScore! > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12, width: 0.8),
                          ),
                          child: Text(
                            '${user.finalScore!.toStringAsFixed(1)} ${_safeTr('pts_unit', 'امتیاز')}',
                            style: GoogleFonts.vazirmatn(
                              color: Colors.amberAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],

                      // 3. League Tier (سطح لیگ)
                      LeagueTierBadgeWidget(
                        tier: user.tier,
                        showLabel: true,
                        iconSize: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLeagueModeGrid(List<LeaguePlayerModeStat> modeStats) {
    if (modeStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            _safeTr('no_league_games_played', 'هنوز در این لیگ بازی نکرده است'),
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.15,
      ),
      itemCount: modeStats.length,
      itemBuilder: (context, index) {
        final stat = modeStats[index];
        final modeColor = GameModeConfig.getColorForMode(stat.mode);
        final modeTitle = _getModeTitle(stat.mode);
        final isRecord = stat.isLeagueRecord;

        final isInfection = stat.mode.toLowerCase().contains('infection');
        final String displayRecord;
        if (isInfection && stat.bestScore > 0) {
          final mins = (stat.bestScore ~/ 60).toString().padLeft(2, '0');
          final secs = (stat.bestScore % 60).toString().padLeft(2, '0');
          displayRecord = '$mins:$secs';
        } else {
          displayRecord = '${stat.bestScore}';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isRecord ? const Color(0xFF1F1C12) : const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRecord
                  ? kGoldColor.withValues(alpha: 0.85)
                  : modeColor.withValues(alpha: 0.3),
              width: isRecord ? 1.4 : 1.0,
            ),
            boxShadow: isRecord
                ? [
                    BoxShadow(
                      color: kGoldColor.withValues(alpha: 0.22),
                      blurRadius: 8,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Mode title + Played count badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: modeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            modeTitle,
                            style: GoogleFonts.vazirmatn(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Played count pill (e.g. 8x)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${stat.playedCount}x',
                      style: GoogleFonts.vazirmatn(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom row: Score & Crown indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            displayRecord,
                            style: TextStyle(
                              color: isRecord ? kGoldColor : modeColor,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isRecord && stat.leagueHighestScore > 0) ...[
                          const SizedBox(width: 3),
                          Text(
                            '(${stat.leagueHighestScore})',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isRecord) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('👑', style: TextStyle(fontSize: 8.5)),
                          const SizedBox(width: 2),
                          Text(
                            _safeTr('league_record_holder', 'رکورددار'),
                            style: GoogleFonts.vazirmatn(
                              color: const Color(0xFF0D1117),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // REDESIGNED HALL OF FAME SHOWCASE (METALLIC PODIUMS)
  // ===========================================================================

  Widget _buildHallOfFameShowcase(LeaguePlayerHallOfFame? hof) {
    final gold = hof?.gold ?? 0;
    final silver = hof?.silver ?? 0;
    final bronze = hof?.bronze ?? 0;
    final podiums = hof?.pastPodiums ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kGoldColor.withValues(alpha: 0.22),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTrophyPedestal(
                  assetPath: 'assets/image/medal/gold.png',
                  count: gold,
                  label: 'gold_medal'.tr,
                  accentColor: const Color(0xFFFFD700),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTrophyPedestal(
                  assetPath: 'assets/image/medal/silver.png',
                  count: silver,
                  label: 'silver_medal'.tr,
                  accentColor: const Color(0xFFE0E0E0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTrophyPedestal(
                  assetPath: 'assets/image/medal/bronze.png',
                  count: bronze,
                  label: 'bronze_medal'.tr,
                  accentColor: const Color(0xFFCD7F32),
                ),
              ),
            ],
          ),
          if (podiums.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 13,
                    color: Colors.white54,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: podiums.map((p) {
                          final medalAsset = p.rank == 1
                              ? 'assets/image/medal/gold.png'
                              : (p.rank == 2
                                    ? 'assets/image/medal/silver.png'
                                    : 'assets/image/medal/bronze.png');
                          final seasonText = Get.locale?.languageCode == 'fa'
                              ? 'سیزن ${p.seasonNumber} (رتبه ${p.rank})'
                              : 'Season ${p.seasonNumber} (#${p.rank})';
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    medalAsset,
                                    width: 12,
                                    height: 12,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    seasonText,
                                    style: GoogleFonts.vazirmatn(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrophyPedestal({
    required String assetPath,
    required int count,
    required String label,
    required Color accentColor,
  }) {
    final bool hasMedals = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: hasMedals
            ? accentColor.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasMedals
              ? accentColor.withValues(alpha: 0.45)
              : Colors.white10,
          width: hasMedals ? 1.2 : 0.8,
        ),
        boxShadow: hasMedals
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.18),
                  blurRadius: 8,
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Opacity(
              opacity: hasMedals ? 1.0 : 0.35,
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.emoji_events_rounded,
                  color: accentColor,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$count',
            style: TextStyle(
              color: hasMedals ? accentColor : Colors.white38,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.vazirmatn(
              color: hasMedals ? Colors.white70 : Colors.white30,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // REDESIGNED DAILY CHALLENGE SHOWCASE (NEON QUEST BAR)
  // ===========================================================================

  Widget _buildDailyChallengeShowcase(LeaguePlayerDailyStats? daily) {
    final completed = daily?.completedCount ?? 0;
    final streak = daily?.streakDays ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C160F), Color(0xFF161B22)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.orangeAccent.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9100), Color(0xFFFF3D00)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _safeTr(
                      'daily_challenges_completed',
                      'چالش‌های روزانه انجام‌شده',
                    ),
                    style: GoogleFonts.vazirmatn(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    Get.locale?.languageCode == 'fa'
                        ? '$completed چالش تکمیل شده'
                        : '$completed Challenges Completed',
                    style: GoogleFonts.vazirmatn(
                      color: Colors.orangeAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF3D00), Color(0xFFFF9100)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrangeAccent.withValues(alpha: 0.35),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    Get.locale?.languageCode == 'fa'
                        ? '$streak روز زنجیره'
                        : '$streak Day Streak',
                    style: GoogleFonts.vazirmatn(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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
  // UNIVERSAL / DEFAULT PROFILE WIDGETS (FALLBACK)
  // ===========================================================================

  Widget _buildUniversalShowcases(UniversalPlayerProfile profile) {
    final totalCompleted =
        profile.dailyChallengeMedals['completed_count'] ??
        profile.dailyChallengeMedals['missions_completed_total'] ??
        profile.dailyChallengeMedals['completed_missions'] ??
        (profile.dailyChallengeMedals['gold'] ?? 0) +
            (profile.dailyChallengeMedals['silver'] ?? 0) +
            (profile.dailyChallengeMedals['bronze'] ?? 0);
    final count = totalCompleted is num
        ? totalCompleted.toInt()
        : (int.tryParse(totalCompleted.toString()) ?? 0);

    final medals = profile.hallOfFameMedals;
    final int gold = (medals['gold'] is num)
        ? (medals['gold'] as num).toInt()
        : int.tryParse(medals['gold']?.toString() ?? '0') ?? 0;
    final int silver = (medals['silver'] is num)
        ? (medals['silver'] as num).toInt()
        : int.tryParse(medals['silver']?.toString() ?? '0') ?? 0;
    final int bronze = (medals['bronze'] is num)
        ? (medals['bronze'] as num).toInt()
        : int.tryParse(medals['bronze']?.toString() ?? '0') ?? 0;

    return Column(
      children: [
        _buildHallOfFameShowcase(
          LeaguePlayerHallOfFame(gold: gold, silver: silver, bronze: bronze),
        ),
        const SizedBox(height: 10),
        _buildDailyChallengeShowcase(
          LeaguePlayerDailyStats(completedCount: count, streakDays: 0),
        ),
      ],
    );
  }

  Widget _buildHeader(UniversalPlayerProfile profile) {
    final presetAvatar = getAvatarById(profile.avatarId ?? 'avatar_1');
    final hasValidUrl =
        profile.avatarUrl != null &&
        profile.avatarUrl!.isNotEmpty &&
        (profile.avatarUrl!.startsWith('http://') ||
            profile.avatarUrl!.startsWith('https://'));

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 74,
              height: 74,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    presetAvatar.primaryColor,
                    presetAvatar.secondaryColor,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: presetAvatar.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0D1117),
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: hasValidUrl
                      ? CachedNetworkImage(
                          imageUrl: profile.avatarUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 200,
                          memCacheHeight: 200,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor: Colors.grey[800]!,
                            highlightColor: Colors.grey[600]!,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (_, __, ___) => Icon(
                            presetAvatar.icon,
                            color: Colors.white70,
                            size: 38,
                          ),
                        )
                      : (presetAvatar.imageUrl != null &&
                            presetAvatar.imageUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: presetAvatar.imageUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 200,
                          memCacheHeight: 200,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor: Colors.grey[800]!,
                            highlightColor: Colors.grey[600]!,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (_, __, ___) => Icon(
                            presetAvatar.icon,
                            color: Colors.white70,
                            size: 38,
                          ),
                        )
                      : Icon(
                          presetAvatar.icon,
                          color: Colors.white70,
                          size: 38,
                        ),
                ),
              ),
            ),
            // Level badge
            Positioned(
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF0D1117), width: 2),
                ),
                child: Text(
                  '${'level_tag'.tr} ${profile.level}',
                  style: GoogleFonts.vazirmatn(
                    color: const Color(0xFF0D1117),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          profile.username,
          style: GoogleFonts.vazirmatn(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              profile.bio!,
              textAlign: TextAlign.center,
              style: GoogleFonts.vazirmatn(
                color: Colors.white60,
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getModeTitle(String mode) {
    switch (mode.toLowerCase()) {
      case 'classic':
        return 'classic_mode'.tr;
      case 'level':
        return 'level_mode'.tr;
      case 'infection':
        return 'infection_mode'.tr;
      case 'blind_memory':
      case 'blindmemory':
        return 'blind_memory_mode'.tr;
      case 'laser':
      case 'laser_core':
        return 'laser_mode'.tr;
      case 'meltdown':
        return 'meltdown_mode'.tr;
      case 'crab':
      case 'crab_chase':
      case 'crabchase':
        return 'crab_chase_mode'.tr;
      case 'casual':
        return 'casual_mode'.tr;
      default:
        return mode.replaceAll('_', ' ').toUpperCase();
    }
  }

  Widget _buildGameModesSection(UniversalPlayerProfile profile) {
    final modes = {
      ...profile.bestScores.keys,
      ...profile.playCounts.keys,
    }.toList();

    if (modes.isEmpty) {
      return Text(
        'no_game_modes_data'.tr,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      );
    }

    final hasPlayCounts = profile.playCounts.values.any((c) => c > 0);

    return Column(
      children: [
        if (hasPlayCounts) ...[
          GameModeDonutChart(
            playCounts: profile.playCounts,
            size: 140,
            selectedModeId: _selectedMode,
            onModeSelected: (modeId) {
              setState(() {
                _selectedMode = modeId;
              });
            },
          ),
          const SizedBox(height: 12),
        ],
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.3,
          ),
          itemCount: modes.length,
          itemBuilder: (context, index) {
            final mode = modes[index];
            final bestScore = profile.bestScores[mode] ?? 0;
            final modeTitle = _getModeTitle(mode);
            final modeColor = GameModeConfig.getColorForMode(mode);
            final isSelected =
                _selectedMode != null &&
                _selectedMode!.toLowerCase().replaceAll('_', '') ==
                    mode.toLowerCase().replaceAll('_', '');

            final isInfection = mode.toLowerCase().contains('infection');
            final String displayRecord;
            if (isInfection) {
              final mins = (bestScore ~/ 60).toString().padLeft(2, '0');
              final secs = (bestScore % 60).toString().padLeft(2, '0');
              displayRecord = '$mins:$secs';
            } else {
              displayRecord = '$bestScore';
            }

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedMode = null;
                    } else {
                      _selectedMode = mode;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? modeColor.withValues(alpha: 0.12)
                        : const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? modeColor
                          : modeColor.withValues(alpha: 0.35),
                      width: isSelected ? 1.6 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modeTitle,
                        style: GoogleFonts.vazirmatn(
                          color: modeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'best_score_label'.tr,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10.5,
                            ),
                          ),
                          Text(
                            displayRecord,
                            style: TextStyle(
                              color: modeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
