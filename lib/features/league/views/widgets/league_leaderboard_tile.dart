import 'package:flutter/material.dart';
import '../../../../app/core/constants/app_constants.dart';
import '../../../../app/core/widgets/app_cached_avatar.dart';
import '../../../profile/views/player_profile_bottom_sheet.dart';
import '../../models/league_models.dart';
import 'trend_indicator.dart';

class LeagueLeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isHighlighted;
  final int? seasonId;

  const LeagueLeaderboardTile({
    super.key,
    required this.entry,
    this.isHighlighted = false,
    this.seasonId,
  });

  @override
  Widget build(BuildContext context) {
    final rank = entry.rank;
    final isTop3 = rank >= 1 && rank <= 3;

    final rankColor = rank == 1
        ? kGoldColor
        : rank == 2
            ? const Color(0xFFE0E0E0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : Colors.white70;

    final avatar = getAvatarById(entry.avatarId ?? 'avatar_1');
    final bool highlightMe = isHighlighted || entry.isMe;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: highlightMe
            ? const Color(0xFF162B3D)
            : const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlightMe
              ? Colors.cyanAccent.withValues(alpha: 0.7)
              : isTop3
                  ? rankColor.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.08),
          width: highlightMe ? 1.5 : (isTop3 ? 1.2 : 1.0),
        ),
        boxShadow: highlightMe
            ? [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : (isTop3
                ? [
                    BoxShadow(
                      color: rankColor.withValues(alpha: 0.12),
                      blurRadius: 8,
                    ),
                  ]
                : []),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: entry.userId > 0
              ? () => openPlayerProfileBottomSheet(
                    context,
                    entry.userId,
                    seasonId: seasonId,
                    isLeagueContext: true,
                  )
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Rank Number & Badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isTop3
                        ? rankColor.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        color: rankColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Trend Indicator
                TrendIndicator(trend: entry.trend),
                const SizedBox(width: 8),

                // Avatar Icon / Image
                AppCachedAvatar(
                  avatarUrl: entry.avatarUrl,
                  avatarId: entry.avatarId,
                  size: 36,
                  iconSize: 20,
                ),
                const SizedBox(width: 12),

                // Name and Diversity Multiplier
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.name,
                              style: TextStyle(
                                color: highlightMe ? Colors.cyanAccent : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (entry.isMe) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.cyanAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'YOU',
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (entry.diversityMul > 1.0) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'x${entry.diversityMul.toStringAsFixed(2)} bonus',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Final Score
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isTop3
                        ? rankColor.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${entry.finalScore.toStringAsFixed(1)} pts',
                    style: TextStyle(
                      color: isTop3 ? rankColor : Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
}
