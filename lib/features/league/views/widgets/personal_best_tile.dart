import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/league_models.dart';

class PersonalBestTile extends StatelessWidget {
  final PersonalBestModel pb;

  const PersonalBestTile({super.key, required this.pb});

  @override
  Widget build(BuildContext context) {
    final modeTitle = 'mode_${pb.gameMode}'.tr;
    final displayTitle = modeTitle.startsWith('mode_') ? pb.gameMode.toUpperCase() : modeTitle;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: pb.isNewRecord
            ? Colors.amber.withValues(alpha: 0.12)
            : const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pb.isNewRecord
              ? Colors.amber.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.08),
          width: pb.isNewRecord ? 1.4 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Left side: Mode Icon + Mode Name
          Icon(
            _getModeIcon(pb.gameMode),
            color: _getModeColor(pb.gameMode),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // Right side: Record details
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pb.isNewRecord) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'new_record_badge'.tr,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${'this_week'.tr}: ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${pb.currentWeekBest.toInt()}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getModeIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'classic':
        return Icons.sports_esports_rounded;
      case 'meltdown':
        return Icons.warning_amber_rounded;
      case 'laser':
      case 'laser_core':
        return Icons.bolt_rounded;
      case 'infection':
        return Icons.coronavirus_rounded;
      case 'blind_memory':
      case 'blindmemory':
        return Icons.visibility_off_rounded;
      case 'crab':
      case 'crab_chase':
        return Icons.pest_control_rounded;
      default:
        return Icons.videogame_asset_rounded;
    }
  }

  Color _getModeColor(String mode) {
    switch (mode.toLowerCase()) {
      case 'classic':
        return Colors.greenAccent;
      case 'meltdown':
        return Colors.orangeAccent;
      case 'laser':
      case 'laser_core':
        return Colors.redAccent;
      case 'infection':
        return Colors.purpleAccent;
      case 'blind_memory':
      case 'blindmemory':
        return const Color(0xFF00E5FF);
      case 'crab':
      case 'crab_chase':
        return const Color(0xFFFF5722);
      default:
        return Colors.amber;
    }
  }
}
