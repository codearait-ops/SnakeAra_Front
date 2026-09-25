import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/sound_service.dart';
import '../../menu/controllers/menu_controller.dart' as menu;
import '../models/league_tier_models.dart';

/// Interactive glowing badge in the Home AppBar showing the player's active League Tier and Rank.
///
/// Tapping it plays a tap sound and navigates directly to the League screen.
class PlayerRankBadgeWidget extends StatelessWidget {
  final LeagueTier? customTier;
  final int? customRank;
  final VoidCallback? onTap;

  const PlayerRankBadgeWidget({
    super.key,
    this.customTier,
    this.customRank,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final menuCtrl = Get.isRegistered<menu.MenuController>()
        ? Get.find<menu.MenuController>()
        : null;

    return Obx(() {
      final summary = menuCtrl?.leagueSummary.value ??
          menuCtrl?.dashboard.value?.leagueSummary;

      final tier = customTier ??
          (summary != null ? summary.leagueTier : LeagueTier.bronze);
      final rank = customRank ?? summary?.rank;
      final season = summary?.seasonNumber ?? 1;

      final color = tier.color;

      final displayText = (rank != null && rank > 0)
          ? '#$rank ${tier.displayNameTr}'
          : tier.displayNameTr;

      return Tooltip(
        message: '${'season'.tr} $season • ${tier.displayNameTr}'
            '${rank != null && rank > 0 ? ' • ${'my_rank'.tr}: #$rank' : ''}',
        child: GestureDetector(
          onTap: () {
            if (Get.isRegistered<SoundService>()) {
              Get.find<SoundService>().playButtonTap();
            }
            if (onTap != null) {
              onTap!();
            } else if (menuCtrl != null) {
              menuCtrl.openLeague();
            } else {
              Get.toNamed('/league');
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.22),
                  const Color(0xFF1E232A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.55),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  tier.assetPath,
                  width: 15,
                  height: 15,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    tier.icon,
                    color: color,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  displayText,
                  style: GoogleFonts.vazirmatn(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
