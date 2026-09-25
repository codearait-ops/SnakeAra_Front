import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/widgets/app_cached_avatar.dart';
import '../../../profile/views/player_profile_bottom_sheet.dart';
import '../../models/weekend_league_models.dart';

/// Top 3 Podium leaderboard widget inspired by Olympic pedestals.
/// Places Rank 2 on the left (Silver), Rank 1 in the center (elevated, Gold, Crown),
/// and Rank 3 on the right (Bronze).
class LeagueTop3PodiumWidget extends StatelessWidget {
  final List<LeagueGroupMember> topMembers;
  final int? seasonId;

  const LeagueTop3PodiumWidget({
    super.key,
    required this.topMembers,
    this.seasonId,
  });

  @override
  Widget build(BuildContext context) {
    if (topMembers.isEmpty) return const SizedBox.shrink();

    // Map members by rank (or by position fallback)
    final rank1 = topMembers.firstWhereOrNull((m) => m.rank == 1) ??
        (topMembers.isNotEmpty ? topMembers[0] : null);
    final rank2 = topMembers.firstWhereOrNull((m) => m.rank == 2) ??
        (topMembers.length > 1 ? topMembers[1] : null);
    final rank3 = topMembers.firstWhereOrNull((m) => m.rank == 3) ??
        (topMembers.length > 2 ? topMembers[2] : null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place (Left - Silver)
          Expanded(
            flex: 10,
            child: rank2 != null
                ? _buildPodiumSlot(
                    context: context,
                    member: rank2,
                    rank: 2,
                    pillarHeight: 100,
                    avatarSize: 62,
                    primaryColor: const Color(0xFFD1D5DB),
                    floatingBadgeColor: const Color(0xFF788494),
                    gradientColors: const [
                      Color(0xFFE2E8F0),
                      Color(0xFF94A3B8),
                    ],
                    hasCrown: false,
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(width: 8),

          // 1st Place (Center - Elevated Gold)
          Expanded(
            flex: 11,
            child: rank1 != null
                ? _buildPodiumSlot(
                    context: context,
                    member: rank1,
                    rank: 1,
                    pillarHeight: 138,
                    avatarSize: 74,
                    primaryColor: const Color(0xFFFFB300),
                    floatingBadgeColor: const Color(0xFFFFB300),
                    gradientColors: const [
                      Color(0xFFFFC107),
                      Color(0xFFFFA000),
                    ],
                    hasCrown: true,
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(width: 8),

          // 3rd Place (Right - Bronze)
          Expanded(
            flex: 10,
            child: rank3 != null
                ? _buildPodiumSlot(
                    context: context,
                    member: rank3,
                    rank: 3,
                    pillarHeight: 80,
                    avatarSize: 62,
                    primaryColor: const Color(0xFFCD7F32),
                    floatingBadgeColor: const Color(0xFF8C4A19),
                    gradientColors: const [
                      Color(0xFFD98240),
                      Color(0xFF8C4A19),
                    ],
                    hasCrown: false,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumSlot({
    required BuildContext context,
    required LeagueGroupMember member,
    required int rank,
    required double pillarHeight,
    required double avatarSize,
    required Color primaryColor,
    required Color floatingBadgeColor,
    required List<Color> gradientColors,
    required bool hasCrown,
  }) {
    final isMe = member.isMe;

    return GestureDetector(
      onTap: member.userId > 0
          ? () => openPlayerProfileBottomSheet(
                context,
                member.userId,
                seasonId: seasonId,
                isLeagueContext: true,
              )
          : null,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top Avatar Section with Crown or Rank Badge
          Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // Avatar with Border
              Padding(
                padding: EdgeInsets.only(top: hasCrown ? 16 : 8),
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isMe ? Colors.amberAccent : primaryColor,
                      width: isMe ? 3.5 : 3.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isMe ? Colors.amberAccent : primaryColor)
                            .withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: AppCachedAvatar(
                      avatarUrl: member.avatar,
                      size: avatarSize,
                    ),
                  ),
                ),
              ),

              // Crown for #1
              if (hasCrown)
                Positioned(
                  top: 0,
                  child: CustomPaint(
                    size: const Size(36, 22),
                    painter: _CrownPainter(),
                  ),
                ),

              // Small Floating Rank Badge for #2 (Silver) and #3 (Bronze)
              if (!hasCrown)
                Positioned(
                  top: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: floatingBadgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          // Player Username
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    member.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isMe ? Colors.amberAccent : Colors.white,
                      fontSize: rank == 1 ? 13 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 3),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'you_label'.tr,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Podium Pedestal Block with Score INSIDE the pillar
          Container(
            height: pillarHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rank Circle
                Container(
                  width: rank == 1 ? 38 : 34,
                  height: rank == 1 ? 38 : 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: rank == 1
                            ? const Color(0xFF1E293B)
                            : (rank == 2
                                ? const Color(0xFF334155)
                                : const Color(0xFF5D2808)),
                        fontSize: rank == 1 ? 18 : 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Score INSIDE the pedestal box
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    member.score
                        .toStringAsFixed(member.score % 1 == 0 ? 0 : 1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
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

/// Custom painter for the golden crown sitting above Rank 1
class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Crown Body Path
    final path = Path();
    path.moveTo(w * 0.12, h * 0.9);
    path.quadraticBezierTo(w * 0.5, h * 1.0, w * 0.88, h * 0.9);
    path.lineTo(w * 0.92, h * 0.35); // Right outer tip
    path.lineTo(w * 0.68, h * 0.62); // Right inner valley
    path.lineTo(w * 0.5, h * 0.15); // Center peak (tallest)
    path.lineTo(w * 0.32, h * 0.62); // Left inner valley
    path.lineTo(w * 0.08, h * 0.35); // Left outer tip
    path.close();

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFF9C4),
          Color(0xFFFFD54F),
          Color(0xFFFFB300),
          Color(0xFFFFA000),
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Shadow
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.4), 3.0, false);
    canvas.drawPath(path, paint);

    // Tip Pearls / Spheres
    final pearlPaint = Paint()..color = const Color(0xFFFFF9C4);
    final pearlBorder = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Center Pearl
    canvas.drawCircle(Offset(w * 0.5, h * 0.15), 3.0, pearlPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.15), 3.0, pearlBorder);

    // Left Pearl
    canvas.drawCircle(Offset(w * 0.08, h * 0.35), 2.5, pearlPaint);
    canvas.drawCircle(Offset(w * 0.08, h * 0.35), 2.5, pearlBorder);

    // Right Pearl
    canvas.drawCircle(Offset(w * 0.92, h * 0.35), 2.5, pearlPaint);
    canvas.drawCircle(Offset(w * 0.92, h * 0.35), 2.5, pearlBorder);

    // Crown Bottom Arc Trim
    final arcPaint = Paint()
      ..color = const Color(0xFFFF8F00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final arcPath = Path();
    arcPath.moveTo(w * 0.12, h * 0.9);
    arcPath.quadraticBezierTo(w * 0.5, h * 1.0, w * 0.88, h * 0.9);
    canvas.drawPath(arcPath, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
