import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/league_tier_models.dart';

/// Renders a sleek glowing badge representing the player's competitive League Tier.
class LeagueTierBadgeWidget extends StatelessWidget {
  final LeagueTier tier;
  final bool showLabel;
  final double iconSize;

  const LeagueTierBadgeWidget({
    super.key,
    required this.tier,
    this.showLabel = true,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final color = tier.color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? 10 : 6,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            tier.assetPath,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Icon(tier.icon, color: color, size: iconSize),
          ),
          if (showLabel) ...[
            const SizedBox(width: 5),
            Text(
              tier.displayNameTr,
              style: GoogleFonts.vazirmatn(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
