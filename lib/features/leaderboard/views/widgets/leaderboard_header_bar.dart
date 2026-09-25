import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A slim header bar displaying column titles (Rank, Player, Score/Time)
/// aligned precisely with the columns in [OnlineLeagueCard].
class LeaderboardHeaderBar extends StatelessWidget {
  final Color accentColor;
  final bool isTime;

  const LeaderboardHeaderBar({
    super.key,
    required this.accentColor,
    this.isTime = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF141922).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // Rank column header (aligned with rank badge width 26)
          SizedBox(
            width: 26,
            child: Center(
              child: Text(
                'rank_col'.tr,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Avatar spacing (avatar width 34 + spacing 10 = 44)
          const SizedBox(width: 44),

          // Player name column header (aligned with username Expanded column)
          Expanded(
            child: Text(
              'player_col'.tr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Score / Time column header (aligned with score pill width 86)
          SizedBox(
            width: 86,
            child: Center(
              child: Text(
                isTime ? 'time_col'.tr : 'score_col'.tr,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
