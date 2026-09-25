import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Opens the bottom sheet explaining League scoring and rules.
void openLeagueRulesBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const LeagueRulesSheet(),
  );
}

/// Comprehensive League Rules and Scoring guide modal.
class LeagueRulesSheet extends StatelessWidget {
  const LeagueRulesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF30363D), width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF30363D),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Title & Close Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'league_rules_title'.tr,
                      style: GoogleFonts.vazirmatn(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'close'.tr,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF21262D)),

          // Scrollable Rules Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Scoring & Attempts
                  _buildRuleCard(
                    icon: Icons.sports_score_rounded,
                    iconColor: const Color(0xFFFFB300),
                    title: 'league_rules_scoring_title'.tr,
                    items: [
                      'league_rules_scoring_1'.tr,
                      'league_rules_scoring_2'.tr,
                      'league_rules_scoring_3'.tr,
                      'league_rules_scoring_4'.tr,
                      'league_rules_scoring_5'.tr,
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. Promotion & Relegation
                  _buildRuleCard(
                    icon: Icons.swap_vert_rounded,
                    iconColor: const Color(0xFF00E676),
                    title: 'league_rules_promotion_title'.tr,
                    items: [
                      'league_rules_promotion_1'.tr,
                      'league_rules_promotion_2'.tr,
                      'league_rules_promotion_3'.tr,
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 3. League Tiers
                  _buildRuleCard(
                    icon: Icons.military_tech_rounded,
                    iconColor: const Color(0xFF00E5FF),
                    title: 'league_rules_tiers_title'.tr,
                    items: [
                      'league_rules_tiers_1'.tr,
                      'league_rules_tiers_2'.tr,
                      'league_rules_tiers_3'.tr,
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 4. Rewards with Horizontal Scroll of Tier Prize Cards
                  _buildRewardsSection(context),

                  const SizedBox(height: 24),

                  // Got it button
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'got_it'.tr,
                      style: GoogleFonts.vazirmatn(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF21262D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.vazirmatn(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.vazirmatn(
                        color: const Color(0xFFC9D1D9),
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF21262D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.amberAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'league_rules_rewards_title'.tr,
                    style: GoogleFonts.vazirmatn(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Horizontal Scrollable Row with Rank Images & Prizes
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: _tierPrizes
                  .map((tier) => _buildTierPrizeCard(tier))
                  .toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Footer note
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'league_rules_rewards_footer'.tr,
              style: GoogleFonts.vazirmatn(
                color: const Color(0xFF8B949E).withValues(alpha: 0.9),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierPrizeCard(_TierPrizeData tier) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tier.color.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: tier.color.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Rank Image Badge from assets/image/ranks/
          Image.asset(
            tier.imagePath,
            height: 54,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.shield_rounded, color: tier.color, size: 50);
            },
          ),

          const SizedBox(height: 6),

          // Tier Name
          Text(
            tier.nameKey.tr,
            style: GoogleFonts.vazirmatn(
              color: tier.color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Color(0xFF21262D)),
          ),

          // 5 Ranks Prizes
          ...List.generate(5, (index) {
            final rankNum = index + 1;
            final coins = tier.prizes[index];
            final medalEmoji = rankNum == 1
                ? '🥇'
                : rankNum == 2
                ? '🥈'
                : rankNum == 3
                ? '🥉'
                : '▫️';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(medalEmoji, style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        'league_rank_num'.trParams({'rank': '$rankNum'}),
                        style: GoogleFonts.vazirmatn(
                          color: rankNum <= 3
                              ? Colors.white
                              : const Color(0xFF8B949E),
                          fontSize: 11.5,
                          fontWeight: rankNum <= 3
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '$coins',
                        style: const TextStyle(
                          color: Color(0xFFFFD54F),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'coins_unit'.tr,
                        style: GoogleFonts.vazirmatn(
                          color: const Color(0xFF8B949E),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TierPrizeData {
  final String nameKey;
  final String imagePath;
  final Color color;
  final List<int> prizes;

  const _TierPrizeData({
    required this.nameKey,
    required this.imagePath,
    required this.color,
    required this.prizes,
  });
}

const List<_TierPrizeData> _tierPrizes = [
  _TierPrizeData(
    nameKey: 'tier_bronze',
    imagePath: 'assets/image/ranks/Bronze.png',
    color: Color(0xFFCD7F32),
    prizes: [300, 240, 180, 120, 60],
  ),
  _TierPrizeData(
    nameKey: 'tier_silver',
    imagePath: 'assets/image/ranks/Silver.png',
    color: Color(0xFFC0C0C0),
    prizes: [400, 320, 240, 160, 80],
  ),
  _TierPrizeData(
    nameKey: 'tier_gold',
    imagePath: 'assets/image/ranks/Gold.png',
    color: Color(0xFFFFB300),
    prizes: [500, 400, 300, 200, 100],
  ),
  _TierPrizeData(
    nameKey: 'tier_platinum',
    imagePath: 'assets/image/ranks/Platinum.png',
    color: Color(0xFF26C6DA),
    prizes: [650, 520, 390, 260, 130],
  ),
  _TierPrizeData(
    nameKey: 'tier_diamond',
    imagePath: 'assets/image/ranks/Diamond.png',
    color: Color(0xFF29B6F6),
    prizes: [850, 680, 510, 340, 170],
  ),
  _TierPrizeData(
    nameKey: 'tier_master',
    imagePath: 'assets/image/ranks/Master.png',
    color: Color(0xFFAB47BC),
    prizes: [1100, 880, 660, 440, 220],
  ),
];
