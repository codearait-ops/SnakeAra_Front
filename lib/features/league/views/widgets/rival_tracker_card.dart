import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/constants/app_constants.dart';
import '../../../../app/core/widgets/app_cached_avatar.dart';
import '../../../profile/views/player_profile_bottom_sheet.dart';
import '../../models/league_models.dart';

class RivalTrackerCard extends StatelessWidget {
  final LeaderboardEntry rival;
  final double myScore;
  final int? seasonId;

  const RivalTrackerCard({
    super.key,
    required this.rival,
    required this.myScore,
    this.seasonId,
  });

  @override
  Widget build(BuildContext context) {
    final diff = (rival.finalScore - myScore).clamp(0.0, double.infinity);
    final avatar = getAvatarById(rival.avatarId ?? 'avatar_1');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.cyanAccent.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: rival.userId > 0
              ? () => openPlayerProfileBottomSheet(
                    context,
                    rival.userId,
                    seasonId: seasonId,
                    isLeagueContext: true,
                  )
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar with target badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AppCachedAvatar(
                      avatarUrl: rival.avatarUrl,
                      avatarId: rival.avatarId,
                      size: 44,
                      iconSize: 24,
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF0D1117),
                        ),
                        child: const Icon(
                          Icons.track_changes_rounded,
                          color: Colors.cyanAccent,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Rival Name and gap info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${'rival_tracker_title'.tr}: ${rival.name}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '#${rival.rank}',
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${'rival_gap_to_pass'.tr}: ${diff.toStringAsFixed(1)} pts',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white38,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
