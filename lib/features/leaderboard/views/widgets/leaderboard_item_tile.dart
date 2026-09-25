import 'package:flutter/material.dart';
import '../../../../app/core/widgets/app_cached_avatar.dart';

class LeaderboardItemTile extends StatelessWidget {
  final int rank;
  final String username;
  final String? avatarUrl;
  final String scoreText;
  final String? subtitleText;
  final VoidCallback onPlayerTap;
  final String? medal; // 'gold', 'silver', 'bronze'

  const LeaderboardItemTile({
    Key? key,
    required this.rank,
    required this.username,
    this.avatarUrl,
    required this.scoreText,
    this.subtitleText,
    required this.onPlayerTap,
    this.medal,
  }) : super(key: key);

  Widget _buildAvatar() {
    return AppCachedAvatar(
      avatarUrl: avatarUrl,
      size: 48,
      border: Border.all(color: Colors.white24, width: 2),
    );
  }

  Widget _buildRank() {
    if (medal != null) {
      Color medalColor;
      switch (medal) {
        case 'gold':
          medalColor = Colors.amber;
          break;
        case 'silver':
          medalColor = Colors.grey[300]!;
          break;
        case 'bronze':
          medalColor = Colors.brown[400]!;
          break;
        default:
          medalColor = Colors.transparent;
      }
      if (medalColor != Colors.transparent) {
        return Icon(Icons.emoji_events, color: medalColor, size: 28);
      }
    }

    if (rank <= 3) {
      Color rankColor = rank == 1
          ? Colors.amber
          : rank == 2
              ? Colors.grey[300]!
              : Colors.brown[400]!;
      return CircleAvatar(
        radius: 14,
        backgroundColor: rankColor,
        child: Text(
          rank.toString(),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      );
    }

    return SizedBox(
      width: 28,
      child: Center(
        child: Text(
          rank.toString(),
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.black45,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          debugPrint('>>> [TAP] LeaderboardItemTile tapped for $username (rank: $rank)');
          onPlayerTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildRank(),
              const SizedBox(width: 16),
              _buildAvatar(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitleText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitleText!,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                scoreText,
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
